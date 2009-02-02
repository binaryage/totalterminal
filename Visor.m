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
#import <QuartzComposer/QuartzComposer.h>

#define VisorTerminalDefaults @"VisorTerminal"

NSString* stringForCharacter(const unsigned short aKeyCode, unichar aCharacter);

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
    
    // add the "Visor Preferences..." item to the Terminal menu
    id <NSMenuItem> prefsMenuItem = [[statusMenu itemAtIndex:[statusMenu numberOfItems] - 1] copy];
    [[[[NSApp mainMenu] itemAtIndex:0] submenu] insertItem:prefsMenuItem atIndex:3];
    [prefsMenuItem release];
    
    if ([ud boolForKey:@"VisorShowStatusItem"]) {
        [self activateStatusMenu];
    }
    
    [self enableHotKey];
    [self initEscapeKey];
    
    // watch for hotkey changes
    [udc addObserver:self forKeyPath:@"values.VisorHotKey" options:nil context:nil];
    [udc addObserver:self forKeyPath:@"values.VisorBackgroundAnimationFile" options:nil context:nil];
    [udc addObserver:self forKeyPath:@"values.VisorUseFade" options:nil context:nil];                                                           
    [udc addObserver:self forKeyPath:@"values.VisorUseSlide" options:nil context:nil];               
    [udc addObserver:self forKeyPath:@"values.VisorAnimationSpeed" options:nil context:nil];
    [udc addObserver:self forKeyPath:@"values.VisorShowStatusItem" options:nil context:nil];
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
    [dnc addObserver:self selector:@selector(resignKey:) name:NSWindowDidResignKeyNotification object:window];
    [dnc addObserver:self selector:@selector(becomeKey:) name:NSWindowDidBecomeKeyNotification object:window];
    [dnc addObserver:self selector:@selector(becomeMain:) name:NSWindowDidBecomeMainNotification object:window];
    [dnc addObserver:self selector:@selector(resized:) name:NSWindowDidResizeNotification object:window];
    
    needPlacement = true;
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem {
    if ([menuItem action]==@selector(toggleVisor:)){
        [menuItem setKeyEquivalent:stringForCharacter([hotkey keyCode],[hotkey character])];
        [menuItem setKeyEquivalentModifierMask:[hotkey modifierFlags]];
    }
    return YES;
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

- (void)activateStatusMenu {
    NSLog(@"activateStatusMenu");
    NSStatusBar *bar = [NSStatusBar systemStatusBar];
    statusItem = [bar statusItemWithLength:NSVariableStatusItemLength];
    [statusItem retain];
    
    // Set Icon
    NSString *imagePath=[[NSBundle bundleForClass:[self classForCoder]]pathForImageResource:@"Visor"];
    NSImage *image=[[[NSImage alloc]initWithContentsOfFile:imagePath]autorelease];
    [statusItem setImage:image];
    
    [statusItem setHighlightMode:YES];
    [statusItem setTarget:self];
    [statusItem setAction:@selector(toggleVisor:)];
    [statusItem setDoubleAction:@selector(toggleVisor:)];
    
    [statusItem setMenu:statusMenu];
}

- (IBAction)toggleVisor:(id)sender {
    NSLog(@"toggleVisor %@", sender);
    if (hidden){
        [self showWindow];
    }else{
        [self hideWindow];
    }
}

- (void)resetWindowPlace:(id)window {
    float offset = 1.0f;
    if (hidden) offset = 0.0f;
    NSLog(@"resetWindowPlace %@ %f", window, offset);
    [self placeWindow:window offset:offset];
    [self adoptScreenWidth:window];
}

// offset==0.0 means window is "hidden" above top screen edge
// offset==1.0 means window is visible right under top screen edge
- (void)placeWindow:(id)window offset:(float)offset {
    NSScreen* screen=[NSScreen mainScreen];
    NSRect screenRect=[screen frame];
    screenRect.size.height-=21; // ignore menu area
    NSRect frame=screenRect; // shown Frame
    frame=[window frame]; // respect the existing height
    frame.origin.y=NSMaxY(screenRect)-round(offset*NSHeight(frame)); // move above top of screen
    [window setFrame:frame display:NO];
}

- (void)adoptScreenWidth:(id)window {
    NSScreen* screen=[NSScreen mainScreen];
    NSRect screenRect=[screen frame];
    NSRect frame=screenRect; // shown Frame
    frame=[window frame]; // respect the existing height
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

- (void)showWindow {
    if (!hidden) return;
    hidden = false;
    [self storePreviouslyActiveApp];
    [NSApp activateIgnoringOtherApps:YES];
    [self maybeEnableEscapeKey:YES];
    [window makeKeyAndOrderFront:self];
    [window setHasShadow:YES];
    [self adoptScreenWidth:window];
    [self slideWindows:1];
    [window invalidateShadow];
}

-(void)hideWindow {
    if (hidden) return;
    hidden = true;
    [self maybeEnableEscapeKey:NO];
    [self restorePreviouslyActiveApp];
    [self saveDefaults];
    [self slideWindows:0];
    [window setHasShadow:NO];
    [window invalidateShadow];
}

#define SLIDE_EASING(x) sin(M_PI_2*(x))
#define ALPHA_EASING(x) (1.0f-(x))
#define SLIDE_DIRECTION(d,x) (d?(x):1.0f-(x))
#define ALPHA_DIRECTION(d,x) (d?1.0f-(x):(x))

- (void)slideWindows:(BOOL)direction { // true == down
    NSAutoreleasePool* pool=[[NSAutoreleasePool alloc]init];

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

    // apply final state
    float offset = SLIDE_DIRECTION(direction, SLIDE_EASING(1));
    [self placeWindow:window offset:offset];
    // always set final alpha to 1, for case off-screen window gets onto the screen somehow (imagine display resize?)
    [window setAlphaValue:1.0]; // NSWindow caches these values, so let it know
}

// callback for a closed shell
- (void)shell:(id)shell childDidExitWithStatus:(int)status {
    [self hideWindow];
    [self setController:nil];
}

- (void)saveDefaults {   
//  NSDictionary *defaults=[[controller defaults]dictionaryRepresentation];
//  [[NSUserDefaults standardUserDefaults]setObject:defaults forKey:VisorTerminalDefaults];
}

- (void)resignMain:(id)sender {
    NSLog(@"resignMain %@", sender);
    if (!hidden){
        [self hideWindow];  
    }
}

- (void)resignKey:(id)sender {
    NSLog(@"resignKey %@", sender);
}

- (void)becomeKey:(id)sender {
    NSLog(@"becomeKey %@", sender);
}

- (void)becomeMain:(id)sender {
    NSLog(@"becomeMain %@", sender);
    if (needPlacement) {
        NSLog(@"... needPlacement");
        [self resetWindowPlace:window];
        needPlacement = false;
    }
}

- (void)resized:(NSNotification *)notif {
    NSLog(@"resized %@", notif);
    [self adoptScreenWidth:window];
    [self saveDefaults];
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
        [self setBackground:nil];
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

@end