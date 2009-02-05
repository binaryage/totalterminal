//
//  Visor.m
//  Visor
//
//  Created by Nicholas Jitkoff on 6/1/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#define DEBUG_LOG_PATH "/Users/darwin/code/visor/Debug.log"

#import "Visor.h"
#import "VisorWindow.h"
#import "NDHotKeyEvent_QSMods.h"

#define VisorTerminalDefaults @"VisorTerminal"

NSString* stringForCharacter(const unsigned short aKeyCode, unichar aCharacter);

void displayReconfigurationCallback(CGDirectDisplayID display, CGDisplayChangeSummaryFlags flags, void *userInfo) {
    if (flags & kCGDisplayBeginConfigurationFlag) {
        NSLog(@"Will change display config: %d, flags=%x", display, flags);
        // need to hide visor window to prevent displaying it randomly after resolution change takes place
        // correct visor placement is restored again in didChangeScreenScreenParameters
        Visor* visor = [Visor sharedInstance];
        [visor makeVisorInvisible]; 
    } else {
        NSLog(@"Display config changed: %d, flags=%x", display, flags);
        // I was unable to use this place to restore correct visor placement here
        // NSScreen:frame has still old value at this point
    }
}

@implementation Visor

+ (Visor*) sharedInstance {
    static Visor* plugin = nil;
    if (plugin == nil)
        plugin = [[Visor alloc] init];
    return plugin;
}

+ (void) install {
    NSDictionary *defaults=[NSDictionary dictionaryWithContentsOfFile:[[NSBundle bundleForClass:[self class]]pathForResource:@"Defaults" ofType:@"plist"]];
    [[NSUserDefaults standardUserDefaults]registerDefaults:defaults];
    [Visor sharedInstance];
}

// for SIMBL debugging
// http://www.atomicbird.com/blog/2007/07/code-quickie-redirect-nslog
- (void) redirectLog {
    // set permissions for our NSLog file
    umask(022);
    // send stderr to our file
    FILE *newStderr = freopen(DEBUG_LOG_PATH, "w", stderr);
}

- (id) init {
    self = [super init];
    if (!self) return self;

#ifdef _DEBUG_MODE
    [self redirectLog];
#endif
    NSLog(@"init");
    
    NSString* imagePath1=[[NSBundle bundleForClass:[self classForCoder]]pathForImageResource:@"VisorActive"];
    activeIcon=[[NSImage alloc]initWithContentsOfFile:imagePath1];
    NSString* imagePath2=[[NSBundle bundleForClass:[self classForCoder]]pathForImageResource:@"VisorInactive"];
    inactiveIcon=[[NSImage alloc]initWithContentsOfFile:imagePath2];
    
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    NSUserDefaultsController* udc = [NSUserDefaultsController sharedUserDefaultsController];

    previouslyActiveApp = nil;
    hidden = true;

    NSDictionary *defaults=[NSDictionary dictionaryWithContentsOfFile:[[NSBundle bundleForClass:[self class]]pathForResource:@"Defaults" ofType:@"plist"]];
    [ud registerDefaults:defaults];
    
    hotkey=nil;
    [NSBundle loadNibNamed:@"Visor" owner:self];

    // if the default VisorShowStatusItem doesn't exist, set it to true by default
    if (![ud objectForKey:@"VisorShowStatusItem"]) {
        [ud setBool:YES forKey:@"VisorShowStatusItem"];
    }
    if (![ud objectForKey:@"VisorScreen"]) {
        [ud setInteger:0 forKey:@"VisorScreen"]; // use main screen by default
    }
    
    // add the "Visor Preferences..." item to the Terminal menu
    id <NSMenuItem> prefsMenuItem = [[statusMenu itemAtIndex:2] copy];
    [[[[NSApp mainMenu] itemAtIndex:0] submenu] insertItem:prefsMenuItem atIndex:3];
    [prefsMenuItem release];
    
    if ([ud boolForKey:@"VisorShowStatusItem"]) {
        [self activateStatusMenu];
    }
    
    [self enableHotKey];
    [self initEscapeKey];
    
    // watch for hotkey changes
    [udc addObserver:self forKeyPath:@"values.VisorHotKey" options:nil context:nil];
    [udc addObserver:self forKeyPath:@"values.VisorUseFade" options:nil context:nil];                                                           
    [udc addObserver:self forKeyPath:@"values.VisorUseSlide" options:nil context:nil];               
    [udc addObserver:self forKeyPath:@"values.VisorAnimationSpeed" options:nil context:nil];
    [udc addObserver:self forKeyPath:@"values.VisorShowStatusItem" options:nil context:nil];
    [udc addObserver:self forKeyPath:@"values.VisorScreen" options:nil context:nil];

    // get notified of resolution change
    CGDisplayRegisterReconfigurationCallback(displayReconfigurationCallback, self);
    
    return self;
}

- (BOOL)status {
    return !!window;
}

- (void)adoptTerminal:(id)win {
    NSLog(@"createController window=%@", win);

    if (window) {
        NSLog(@"createController called when old window existed");
    }
    window = win;
    
    [window setLevel:NSMainMenuWindowLevel-1];
    [window setOpaque:NO];
    [window setHasShadow:NO];
    
    NSNotificationCenter* dnc = [NSNotificationCenter defaultCenter];
    [dnc addObserver:self selector:@selector(resignMain:) name:NSWindowDidResignMainNotification object:window];
    [dnc addObserver:self selector:@selector(becomeMain:) name:NSWindowDidBecomeMainNotification object:window];
    [dnc addObserver:self selector:@selector(didResize:) name:NSWindowDidResizeNotification object:window];
    [dnc addObserver:self selector:@selector(willClose:) name:NSWindowWillCloseNotification object:window];
    [dnc addObserver:self selector:@selector(didChangeScreenScreenParameters:) name:NSApplicationDidChangeScreenParametersNotification object:nil];
    
    needPlacement = true;
    [self updateStatusMenu];
}

- (IBAction)showPrefs:(id)sender {
    [NSApp activateIgnoringOtherApps:YES];
    [prefsWindow center];
    [prefsWindow makeKeyAndOrderFront:nil];
}
 
- (IBAction)showAboutBox:(id)sender {
    NSLog(@"showAboutBox");
    [NSApp activateIgnoringOtherApps:YES];
    [aboutWindow center];
    [aboutWindow makeKeyAndOrderFront:nil];
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem {
    if ([menuItem action]==@selector(toggleVisor:)){
        [menuItem setKeyEquivalent:stringForCharacter([hotkey keyCode],[hotkey character])];
        [menuItem setKeyEquivalentModifierMask:[hotkey modifierFlags]];
        return [self status];
    }
    return YES;
}

- (void)activateStatusMenu {
    NSLog(@"activateStatusMenu");
    NSStatusBar *bar = [NSStatusBar systemStatusBar];
    statusItem = [bar statusItemWithLength:NSVariableStatusItemLength];
    [statusItem retain];
    
    [statusItem setHighlightMode:YES];
    [statusItem setTarget:self];
    [statusItem setAction:@selector(toggleVisor:)];
    [statusItem setDoubleAction:@selector(toggleVisor:)];
    
    [statusItem setMenu:statusMenu];
    [self updateStatusMenu];
}

- (void)updateStatusMenu {
    NSLog(@"updateStatusMenu");
    if (!statusItem) return;
    
    // update icon
    BOOL status = [self status];
    if (status)
        [statusItem setImage:activeIcon];
    else
        [statusItem setImage:inactiveIcon];
}

- (IBAction)toggleVisor:(id)sender {
    NSLog(@"toggleVisor %@", sender);
    if (!window) {
        NSLog(@"visor is detached");
        NSBeep();
        return;
    }
    if (hidden){
        [self showVisor:false];
    }else{
        [self hideVisor:false];
    }
}

- (void)resetWindowPlacement {
    if (!window) return;
    float offset = 1.0f;
    if (hidden) offset = 0.0f;
    NSLog(@"resetWindowPlacement %@ %f", window, offset);
    [self cacheScreen];
    [self placeWindow:window offset:offset];
    [self adoptScreenWidth:window];
}

- (void)cacheScreen {
    int screenIndex = [[NSUserDefaults standardUserDefaults]integerForKey:@"VisorScreen"];
    if (screenIndex==0) {
        cachedScreen = [NSScreen mainScreen];
        NSLog(@"Cached main screen %@", cachedScreen);
        return;
    }
    screenIndex--;
    NSArray* screens = [NSScreen screens];
    if (screenIndex>0 && screenIndex<[screens count]) {
        cachedScreen=[screens objectAtIndex:screenIndex];
    } else {
        cachedScreen=[screens objectAtIndex:0];
    }
    NSLog(@"Cached screen %d %@", screenIndex, cachedScreen);
}

// offset==0.0 means window is "hidden" above top screen edge
// offset==1.0 means window is visible right under top screen edge
- (void)placeWindow:(id)window offset:(float)offset {
    NSScreen* screen=cachedScreen;
    NSRect screenRect=[screen frame];
    if (screen == [[NSScreen screens] objectAtIndex: 0]) // see http://code.google.com/p/blacktree-visor/issues/detail?id=19
        screenRect.size.height-=22; // ignore menu area
    NSRect frame=[window frame]; // respect the existing height
    frame.origin.y=NSMaxY(screenRect)-round(offset*NSHeight(frame)); // move above top of screen
    [window setFrame:frame display:NO];
}

- (void)adoptScreenWidth:(id)window {
    NSScreen* screen=cachedScreen;
    NSRect screenRect=[screen frame];
    NSRect frame=[window frame]; // respect the existing height
    frame.size.width=screenRect.size.width; // make it the full screen width
    frame.origin.x+=NSMidX(screenRect)-NSMidX(frame); // center horizontally
    [window setFrame:frame display:NO];
}

- (void)storePreviouslyActiveApp {
    NSDictionary *activeAppDict = [[NSWorkspace sharedWorkspace] activeApplication];
    if (previouslyActiveApp) {
        [previouslyActiveApp release];
        previouslyActiveApp = nil;
    }
    if ([[activeAppDict objectForKey:@"NSApplicationBundleIdentifier"] compare:@"com.apple.Terminal"]) {
        previouslyActiveApp = [[NSString alloc] initWithString:[activeAppDict objectForKey:@"NSApplicationPath"]];
    }
}

- (void)restorePreviouslyActiveApp {
    if (!previouslyActiveApp) return;
    NSDictionary *scriptError = [[NSDictionary alloc] init]; 
    NSString *scriptSource = [NSString stringWithFormat: @"tell application \"%@\" to activate ", previouslyActiveApp]; 
    NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:scriptSource]; 
    [appleScript executeAndReturnError: &scriptError];
    [appleScript release];
    [scriptError release];
    [previouslyActiveApp release];
    previouslyActiveApp = nil;
}

- (void)showVisor:(BOOL)fast {
    if (!hidden) return;
    hidden = false;
    [self cacheScreen]; // performs screen pointer caching at this point
    [self storePreviouslyActiveApp];
    [NSApp activateIgnoringOtherApps:YES];
    [self maybeEnableEscapeKey:YES];
    [window makeKeyAndOrderFront:self];
    [window setHasShadow:YES];
    [self adoptScreenWidth:window];
    [self slideWindows:1 fast:fast];
    [window invalidateShadow];
    [window update];
}

-(void)makeVisorInvisible {
    [window orderOut:nil];
}

-(void)hideVisor:(BOOL)fast {
    if (hidden) return;
    hidden = true;
    [self restorePreviouslyActiveApp];
    [self maybeEnableEscapeKey:NO];
    [self saveDefaults];
    [self slideWindows:0 fast:fast];
    [window setHasShadow:NO];
    [window invalidateShadow];
    [window update];
}

#define SLIDE_EASING(x) sin(M_PI_2*(x))
#define ALPHA_EASING(x) (1.0f-(x))
#define SLIDE_DIRECTION(d,x) (d?(x):1.0f-(x))
#define ALPHA_DIRECTION(d,x) (d?1.0f-(x):(x))

- (void)slideWindows:(BOOL)direction fast:(bool)fast { // true == down
    NSAutoreleasePool* pool=[[NSAutoreleasePool alloc]init];

    if (!fast) {
        BOOL doSlide = [[NSUserDefaults standardUserDefaults]boolForKey:@"VisorUseSlide"];
        BOOL doFade = [[NSUserDefaults standardUserDefaults]boolForKey:@"VisorUseFade"];
        float animSpeed = [[NSUserDefaults standardUserDefaults]floatForKey:@"VisorAnimationSpeed"];

        // animation loop
        if (doFade || doSlide) {
            if (!doSlide && direction) {
                float offset = SLIDE_DIRECTION(direction, SLIDE_EASING(1));
                [self placeWindow:window offset:offset];
            }
            NSTimeInterval t;
            NSDate* date=[NSDate date];
            while (animSpeed>(t=-[date timeIntervalSinceNow])) {
                float k=t/animSpeed;
                if (doSlide) {
                    float offset = SLIDE_DIRECTION(direction, SLIDE_EASING(k));
                    [self placeWindow:window offset:offset];
                }
                if (doFade) {
                    float alpha = ALPHA_DIRECTION(direction, ALPHA_EASING(k));
                    [window setAlphaValue:alpha];
                }
                usleep(5000); // 5ms
            }
        }
    }
    
    // apply final state
    float offset = SLIDE_DIRECTION(direction, SLIDE_EASING(1));
    [self placeWindow:window offset:offset];
    // always set final alpha to 1, for case off-screen window gets onto the screen somehow (imagine display resize?)
    [window setAlphaValue:1.0]; // NSWindow caches these values, so let it know
}

- (void)saveDefaults {   
//  NSDictionary *defaults=[[controller defaults]dictionaryRepresentation];
//  [[NSUserDefaults standardUserDefaults]setObject:defaults forKey:VisorTerminalDefaults];
}

- (void)resignMain:(id)sender {
    NSLog(@"resignMain %@", sender);
    if (!hidden){
        [self hideVisor:false];  
    }
}
- (void)becomeMain:(id)sender {
    NSLog(@"becomeMain %@", sender);
    if (needPlacement) {
        NSLog(@"... needPlacement");
        [self resetWindowPlacement];
        needPlacement = false;
    }
}

- (void)didChangeScreenScreenParameters:(id)sender {
    NSLog(@"didChangeScreenScreenParameters %@", sender);
    [self resetWindowPlacement];
}

- (void)didResize:(id)sender {
    NSLog(@"didResize %@", sender);
    [self cacheScreen];
    [self adoptScreenWidth:window];
    [self saveDefaults];
}

- (void)willClose:(id)sender {
    NSLog(@"willClose %@", sender);
    [self makeVisorInvisible]; // prevent gray background
    window = nil;
    [self updateStatusMenu];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"values.VisorShowStatusItem"]) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"VisorShowStatusItem"]) {
            [self activateStatusMenu];
        } else {
            [statusItem release];
            statusItem=nil;
        }
    } else {
        [self enableHotKey];
    }
}

- (void)enableHotKey {
    if (hotkey){
        [hotkey setEnabled:NO];
        [hotkey release];
        hotkey=nil;
    }
    NSDictionary *dict=[[NSUserDefaults standardUserDefaults]dictionaryForKey:@"VisorHotKey"];
    if (dict){
        hotkey=(QSHotKeyEvent *)[QSHotKeyEvent hotKeyWithDictionary:dict];
        [hotkey setTarget:self selectorReleased:(SEL)0 selectorPressed:@selector(toggleVisor:)];
        [hotkey setEnabled:YES];    
        [hotkey retain];
    }
}

- (void)initEscapeKey {
    escapeKey=(QSHotKeyEvent *)[QSHotKeyEvent hotKeyWithKeyCode:53 character:0 modifierFlags:0];
    [escapeKey setTarget:self selectorReleased:(SEL)0 selectorPressed:@selector(toggleVisor:)];
    [escapeKey setEnabled:NO];  
    [escapeKey retain];
}

- (void)maybeEnableEscapeKey:(BOOL)pEnable {
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"VisorHideOnEscape"])
        [escapeKey setEnabled:pEnable];
}

- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox {
    NSLog(@"numberOfItemsInComboBox %@", aComboBox);
    return [[NSScreen screens] count]+1;
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index{
    NSLog(@"comboBox %@, objectValueForItemAtIndex %d", aComboBox, index);
    VisorScreenTransformer* transformer = [[VisorScreenTransformer alloc] init];
    id res = [transformer transformedValue:[NSNumber numberWithInteger:index]];
    [transformer release];
    return res;
}

@end

@implementation VisorScreenTransformer

+ (Class)transformedValueClass {
    NSLog(@"transformedValueClass");
    return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation {
    NSLog(@"allowsReverseTransformation");
    return YES;
}

- (id)transformedValue:(id)value {
    NSLog(@"transformedValue %@", value);
    if ([value integerValue]==0) {
        return @"Main Screen";
    }
    return [NSString stringWithFormat: @"Screen %d", [value integerValue]-1];
}

- (id)reverseTransformedValue:(id)value {
    NSLog(@"reverseTransformedValue %@", value);
    if ([value hasPrefix:@"Screen"]) {
        return [NSNumber numberWithInteger:[[value substringFromIndex:6] integerValue]+1];
    }
    return [NSNumber numberWithInteger:0];
}

@end