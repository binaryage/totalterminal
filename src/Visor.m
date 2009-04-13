#import "Macros.h"
#import "CGSPrivate.h"
#import <Cocoa/Cocoa.h>
#import "Visor.h"
#import "VisorWindow.h"
#import "VisorScreenTransformer.h"
#import "NDHotKeyEvent_QSMods.h"

int main(int argc, char *argv[]) {
    return NSApplicationMain(argc,  (const char **) argv);
}

NSString* stringForCharacter(const unsigned short aKeyCode, unichar aCharacter);

void displayReconfigurationCallback(CGDirectDisplayID display, CGDisplayChangeSummaryFlags flags, void *userInfo) {
    if (flags & kCGDisplayBeginConfigurationFlag) {
        LOG(@"Will change display config: %d, flags=%x", display, flags);
        // need to hide visor window to prevent displaying it randomly after resolution change takes place
        // correct visor placement is restored again in didChangeScreenScreenParameters
        Visor* visor = [Visor sharedInstance];
        [visor makeVisorInvisible]; 
    } else {
        LOG(@"Display config changed: %d, flags=%x", display, flags);
        // I was unable to use this place to restore correct visor placement here
        // NSScreen:frame has still old value at this point
    }
}

@implementation Visor

+ (Visor*)sharedInstance {
    static Visor* plugin = nil;
    if (plugin == nil)
        plugin = [[Visor alloc] init];
    return plugin;
}

+ (void)install {
    NSDictionary *defaults=[NSDictionary dictionaryWithContentsOfFile:[[NSBundle bundleForClass:[self class]]pathForResource:@"Defaults" ofType:@"plist"]];
    [[NSUserDefaults standardUserDefaults]registerDefaults:defaults];
    [Visor sharedInstance];
}

- (BOOL)status {
    return !!window;
}

// for SIMBL debugging
// http://www.atomicbird.com/blog/2007/07/code-quickie-redirect-nslog
- (void) redirectLog {
    // set permissions for our LOG file
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
    LOG(@"init");
    
    activeIcon=[[NSImage alloc]initWithContentsOfFile:[[NSBundle bundleForClass:[self classForCoder]]pathForImageResource:@"VisorActive"]];
    inactiveIcon=[[NSImage alloc]initWithContentsOfFile:[[NSBundle bundleForClass:[self classForCoder]]pathForImageResource:@"VisorInactive"]];
    pinUpIcon=[[NSImage alloc]initWithContentsOfFile:[[NSBundle bundleForClass:[self classForCoder]]pathForImageResource:@"VisorPinUp"]];
    pinDownIcon=[[NSImage alloc]initWithContentsOfFile:[[NSBundle bundleForClass:[self classForCoder]]pathForImageResource:@"VisorPinDown"]];
    
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    NSUserDefaultsController* udc = [NSUserDefaultsController sharedUserDefaultsController];

    previouslyActiveApp = nil;
    isHidden = true;
    isMain = false;
    isKey = false;

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
    if (![ud objectForKey:@"VisorOnEverySpace"]) {
        [ud setBool:YES forKey:@"VisorOnEverySpace"];
    }
    if (![ud objectForKey:@"VisorPosition"]) {
        [ud setObject:@"Top-Stretch" forKey:@"VisorPosition"];
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
    [udc addObserver:self forKeyPath:@"values.VisorPosition" options:nil context:nil];

    // get notified of resolution change
    CGDisplayRegisterReconfigurationCallback(displayReconfigurationCallback, self);
    
    return self;
}

// credit: http://tonyarnold.com/entries/fixing-an-annoying-expose-bug-with-nswindows/
- (OSStatus)setupExposeTags:(NSWindow*)win {
    CGSConnection cid;
    CGSWindow wid;
    CGSWindowTag tags[2];
    bool showOnEverySpace = [[NSUserDefaults standardUserDefaults] boolForKey:@"VisorOnEverySpace"];
    
    wid = [win windowNumber];
    cid = _CGSDefaultConnection();
    tags[0] = CGSTagSticky;
    tags[1] = 0;
    
    if (showOnEverySpace)
        return CGSSetWindowTags(cid, wid, tags, 32);
    else 
        return CGSClearWindowTags(cid, wid, tags, 32);
}

- (void)adoptTerminal:(id)win {
    LOG(@"adoptTerminal window=%@", win);
    if (window) {
        LOG(@"adoptTerminal called when old window existed");
    }
    window = win;
    
    [window setLevel:NSMainMenuWindowLevel-1];
    [window setOpaque:NO];
    
    NSNotificationCenter* dnc = [NSNotificationCenter defaultCenter];
    [dnc addObserver:self selector:@selector(becomeKey:) name:NSWindowDidBecomeKeyNotification object:window];
    [dnc addObserver:self selector:@selector(resignKey:) name:NSWindowDidResignKeyNotification object:window];
    [dnc addObserver:self selector:@selector(becomeMain:) name:NSWindowDidBecomeMainNotification object:window];
    [dnc addObserver:self selector:@selector(resignMain:) name:NSWindowDidResignMainNotification object:window];
    [dnc addObserver:self selector:@selector(didResize:) name:NSWindowDidResizeNotification object:window];
    [dnc addObserver:self selector:@selector(willClose:) name:NSWindowWillCloseNotification object:window];
    [dnc addObserver:self selector:@selector(didChangeScreenScreenParameters:) name:NSApplicationDidChangeScreenParametersNotification object:nil];
    
    needPlacement = true;
    [self updateStatusMenu];
}

- (void)createPinButton {
    LOG(@"createPinButton");
    NSRect windowFrame = [window frame];
    pinButton = [[NSButton alloc] initWithFrame:NSMakeRect(windowFrame.size.width-20.-16.,windowFrame.size.height-20.,16.,16.)];
    [pinButton setState:NSOffState];
    [pinButton setButtonType: NSToggleButton];
    [pinButton setImagePosition: NSImageOnly];
    [pinButton setBordered: NO];
    [pinButton setImage:pinUpIcon];
    [pinButton setAlternateImage:pinDownIcon];
    [pinButton setTarget:self];
    [pinButton setAction:@selector(pinAction:)];
    [[window contentView] addSubview:pinButton positioned:NSWindowAbove relativeTo:nil];  
}

- (void)updatePinButton {
    LOG(@"updatePinButton");
    NSRect windowFrame = [window frame];
    [pinButton setFrame:NSMakeRect(windowFrame.size.width-20.-16.,windowFrame.size.height-20.,16.,16.)];
}

- (IBAction)pinAction:(id)sender {
    LOG(@"pinAction %@", sender);
    isPinned = !isPinned;
}

- (IBAction)toggleVisor:(id)sender {
    LOG(@"toggleVisor %@", sender);
    if (!window) {
        LOG(@"visor is detached");
        NSBeep();
        return;
    }
    if (isHidden){
        [self showVisor:false];
    }else{
        [self hideVisor:false];
    }
}

- (void)resetWindowPlacement {
    if (!window) return;
    float offset = 1.0f;
    if (isHidden) offset = 0.0f;
    LOG(@"resetWindowPlacement %@ %f", window, offset);
    [self cacheScreen];
    [self cachePosition];
    [self applyWindowPositioning:window];
    [self placeWindow:window offset:offset];
}

- (void)cachePosition {
    cachedPosition = [[NSUserDefaults standardUserDefaults] stringForKey:@"VisorPosition"];
}

- (void)cacheScreen {
    int screenIndex = [[NSUserDefaults standardUserDefaults]integerForKey:@"VisorScreen"];
    if (screenIndex==0) {
        cachedScreen = [NSScreen mainScreen];
        LOG(@"Cached main screen %@", cachedScreen);
        return;
    }
    screenIndex--;
    NSArray* screens = [NSScreen screens];
    if (screenIndex>0 && screenIndex<[screens count]) {
        cachedScreen=[screens objectAtIndex:screenIndex];
    } else {
        cachedScreen=[screens objectAtIndex:0];
    }
    LOG(@"Cached screen %d %@", screenIndex, cachedScreen);
}

// offset==0.0 means window is "hidden" above top screen edge
// offset==1.0 means window is visible right under top screen edge
- (void)placeWindow:(id)window offset:(float)offset {
    NSScreen* screen=cachedScreen;
    NSRect screenRect=[screen frame];
    NSRect frame=[window frame];
    int shift = 0; // see http://code.google.com/p/blacktree-visor/issues/detail?id=19
    if (screen == [[NSScreen screens] objectAtIndex: 0]) shift = 21; // menu area
    if ([cachedPosition hasPrefix:@"Top"]) {
        frame.origin.y = screenRect.origin.y + NSHeight(screenRect) - round(offset*(NSHeight(frame)+shift));
    }
    if ([cachedPosition hasPrefix:@"Left"]) {
        frame.origin.x = screenRect.origin.x - NSWidth(frame) + round(offset*NSWidth(frame));
    }
    if ([cachedPosition hasPrefix:@"Right"]) {
        frame.origin.x = screenRect.origin.x + NSWidth(screenRect) - round(offset*NSWidth(frame));
    }
    if ([cachedPosition hasPrefix:@"Bottom"]) {
        frame.origin.y = screenRect.origin.y - NSHeight(frame) + round(offset*NSHeight(frame));
    }
    [window setFrame:frame display:NO];
}

- (void)resetVisorWindowSize {
    // this is kind of a hack
    // I'm using scripting API to update main window geometry according to profile settings
    TTProfile* profile = [[TTProfileManager sharedProfileManager] startupProfile];
    LOG(@"resetWindowSize %@", profile);
    NSNumber* cols = [profile scriptNumberOfColumns];
    NSNumber* rows = [profile scriptNumberOfRows];
    [profile setScriptNumberOfColumns:cols];
    [profile setScriptNumberOfRows:rows];
}

- (void)applyWindowPositioning:(id)window {
    [self setupExposeTags:window];
    NSScreen* screen = cachedScreen;
    NSRect screenRect = [screen frame];
    NSString* position = [[NSUserDefaults standardUserDefaults] stringForKey:@"VisorPosition"];
    LOG(@"applyWindowPositioning %@", position);
    int shift = 0; // see http://code.google.com/p/blacktree-visor/issues/detail?id=19
    if (screen == [[NSScreen screens] objectAtIndex: 0]) shift = 21; // menu area
    if ([position isEqualToString:@"Top-Stretch"]) {
        NSRect frame = [window frame];
        frame.size.width = screenRect.size.width;
        frame.origin.x = screenRect.origin.x;
        frame.origin.y = screenRect.origin.y + NSHeight(screenRect) - NSHeight(frame) - shift;
        [window setFrame:frame display:NO];
    }
    if ([position isEqualToString:@"Top-Left"]) {
        [self resetVisorWindowSize];
        NSRect frame = [window frame];
        frame.origin.x = screenRect.origin.x;
        frame.origin.y = screenRect.origin.y + NSHeight(screenRect) - NSHeight(frame) - shift;
        [window setFrame:frame display:NO];
    }
    if ([position isEqualToString:@"Top-Right"]) {
        [self resetVisorWindowSize];
        NSRect frame = [window frame];
        frame.origin.x = screenRect.origin.x + NSWidth(screenRect) - NSWidth(frame);
        frame.origin.y = screenRect.origin.y + NSHeight(screenRect) - NSHeight(frame) - shift;
        [window setFrame:frame display:NO];
    }
    if ([position isEqualToString:@"Top-Center"]) {
        [self resetVisorWindowSize];
        NSRect frame = [window frame];
        frame.origin.x = screenRect.origin.x + (NSWidth(screenRect)-NSWidth(frame))/2;
        frame.origin.y = screenRect.origin.y + NSHeight(screenRect) - NSHeight(frame) - shift;
        [window setFrame:frame display:NO];
    }
    if ([position isEqualToString:@"Left-Stretch"]) {
        NSRect frame = [window frame];
        frame.size.height = screenRect.size.height;
        frame.origin.x = screenRect.origin.x;
        frame.origin.y = screenRect.origin.y + NSHeight(screenRect) - NSHeight(frame) - shift;
        [window setFrame:frame display:NO];
    }
    if ([position isEqualToString:@"Left-Top"]) {
        [self resetVisorWindowSize];
        NSRect frame = [window frame];
        frame.origin.x = screenRect.origin.x;
        frame.origin.y = screenRect.origin.y + NSHeight(screenRect) - NSHeight(frame) - shift;
        [window setFrame:frame display:NO];
    }
    if ([position isEqualToString:@"Left-Bottom"]) {
        [self resetVisorWindowSize];
        NSRect frame = [window frame];
        frame.origin.x = screenRect.origin.x;
        frame.origin.y = screenRect.origin.y;
        [window setFrame:frame display:NO];
    }
    if ([position isEqualToString:@"Left-Center"]) {
        [self resetVisorWindowSize];
        NSRect frame = [window frame];
        frame.origin.x = screenRect.origin.x;
        frame.origin.y = screenRect.origin.y + (NSHeight(screenRect)-NSHeight(frame))/2;
        [window setFrame:frame display:NO];
    }
    if ([position isEqualToString:@"Right-Stretch"]) {
        NSRect frame = [window frame];
        frame.size.height = screenRect.size.height;
        frame.origin.x = screenRect.origin.x + NSWidth(screenRect) - NSWidth(frame);
        frame.origin.y = screenRect.origin.y + NSHeight(screenRect) - NSHeight(frame) - shift;
        [window setFrame:frame display:NO];
    }
    if ([position isEqualToString:@"Right-Top"]) {
        [self resetVisorWindowSize];
        NSRect frame = [window frame];
        frame.origin.x = screenRect.origin.x + NSWidth(screenRect) - NSWidth(frame);
        frame.origin.y = screenRect.origin.y + NSHeight(screenRect) - NSHeight(frame) - shift;
        [window setFrame:frame display:NO];
    }
    if ([position isEqualToString:@"Right-Bottom"]) {
        [self resetVisorWindowSize];
        NSRect frame = [window frame];
        frame.origin.x = screenRect.origin.x + NSWidth(screenRect) - NSWidth(frame);
        frame.origin.y = screenRect.origin.y;
        [window setFrame:frame display:NO];
    }
    if ([position isEqualToString:@"Right-Center"]) {
        [self resetVisorWindowSize];
        NSRect frame = [window frame];
        frame.origin.x = screenRect.origin.x + NSWidth(screenRect) - NSWidth(frame);
        frame.origin.y = screenRect.origin.y + (NSHeight(screenRect)-NSHeight(frame))/2;
        [window setFrame:frame display:NO];
    }
    if ([position isEqualToString:@"Bottom-Stretch"]) {
        NSRect frame = [window frame];
        frame.size.width = screenRect.size.width;
        frame.origin.x = screenRect.origin.x;
        frame.origin.y = screenRect.origin.y;
        [window setFrame:frame display:NO];
    }
    if ([position isEqualToString:@"Bottom-Left"]) {
        [self resetVisorWindowSize];
        NSRect frame = [window frame];
        frame.origin.x = screenRect.origin.x;
        frame.origin.y = screenRect.origin.y;
        [window setFrame:frame display:NO];
    }
    if ([position isEqualToString:@"Bottom-Right"]) {
        [self resetVisorWindowSize];
        NSRect frame = [window frame];
        frame.origin.x = screenRect.origin.x + NSWidth(screenRect) - NSWidth(frame);
        frame.origin.y = screenRect.origin.y;
        [window setFrame:frame display:NO];
    }
    if ([position isEqualToString:@"Bottom-Center"]) {
        [self resetVisorWindowSize];
        NSRect frame = [window frame];
        frame.origin.x = screenRect.origin.x + (NSWidth(screenRect)-NSWidth(frame))/2;
        frame.origin.y = screenRect.origin.y;
        [window setFrame:frame display:NO];
    }
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
    if (!isHidden) return;
    isHidden = false;
    [self cacheScreen]; // performs screen pointer caching at this point
    [self cachePosition];
    [self storePreviouslyActiveApp];
    [NSApp activateIgnoringOtherApps:YES];
    [self maybeEnableEscapeKey:YES];
    [window makeKeyAndOrderFront:self];
    [window setHasShadow:YES];
    [self applyWindowPositioning:window];
    [window update];
    [self slideWindows:1 fast:fast];
    [window invalidateShadow];
    [window update];
}

-(void)makeVisorInvisible {
    [window orderOut:nil];
}

-(void)hideVisor:(BOOL)fast {
    if (isHidden) return;
    isHidden = true;
    [self restorePreviouslyActiveApp];
    [self maybeEnableEscapeKey:NO];
    [window update];
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
    float alpha = ALPHA_DIRECTION(direction, ALPHA_EASING(1));
    [window setAlphaValue: alpha];
}

- (void)resignKey:(id)sender {
    LOG(@"resignKey %@", sender);
    isKey = false;
    if (!isPinned && !isMain && !isKey && !isHidden){
        [self hideVisor:false];  
    }
}

- (void)resignMain:(id)sender {
    LOG(@"resignMain %@", sender);
    isMain = false;
    if (!isPinned && !isMain && !isKey && !isHidden){
        [self hideVisor:false];  
    }
}

- (void)becomeKey:(id)sender {
    LOG(@"becomeKey %@", sender);
    isKey = true;
}

- (void)becomeMain:(id)sender {
    LOG(@"becomeMain %@", sender);
    isMain = true;
    if (needPlacement) {
        LOG(@"... needPlacement");
        [self makeVisorInvisible]; // prevent gray background
        [self resetWindowPlacement];
        if (window) {
            [window setHasShadow:NO];
            [window invalidateShadow];
            [window update];
        }
        needPlacement = false;
        [self createPinButton];
    }
    if (isMain && isHidden) {
        [self showVisor:false];
    }
}

- (void)didChangeScreenScreenParameters:(id)sender {
    LOG(@"didChangeScreenScreenParameters %@", sender);
    [self resetWindowPlacement];
}

- (void)didResize:(id)sender {
    LOG(@"didResize %@", sender);
    [self cacheScreen];
    [self cachePosition];
    [self applyWindowPositioning:window];
    [self updatePinButton];
}

- (void)willClose:(id)sender {
    LOG(@"willClose %@", sender);
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
    if ([keyPath isEqualToString:@"values.VisorPosition"]) {
        [self cacheScreen];
        [self cachePosition];
        [self applyWindowPositioning:window];
    }
    if ([keyPath isEqualToString:@"values.VisorScreen"]) {
        [self cacheScreen];
        [self cachePosition];
        [self applyWindowPositioning:window];
    }
    if ([keyPath isEqualToString:@"values.VisorOnEverySpace"]) {
        [self cacheScreen];
        [self cachePosition];
        [self applyWindowPositioning:window];
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

- (IBAction)showPrefs:(id)sender {
    [NSApp activateIgnoringOtherApps:YES];
    [prefsWindow center];
    [prefsWindow makeKeyAndOrderFront:nil];
}
 
- (IBAction)showAboutBox:(id)sender {
    LOG(@"showAboutBox");
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

- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox {
    LOG(@"numberOfItemsInComboBox %@", aComboBox);
    return [[NSScreen screens] count]+1;
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index{
    LOG(@"comboBox %@, objectValueForItemAtIndex %d", aComboBox, index);
    VisorScreenTransformer* transformer = [[VisorScreenTransformer alloc] init];
    id res = [transformer transformedValue:[NSNumber numberWithInteger:index]];
    [transformer release];
    return res;
}

- (void)activateStatusMenu {
    LOG(@"activateStatusMenu");
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
    LOG(@"updateStatusMenu");
    if (!statusItem) return;
    
    // update icon
    BOOL status = [self status];
    if (status)
        [statusItem setImage:activeIcon];
    else
        [statusItem setImage:inactiveIcon];
}

@end