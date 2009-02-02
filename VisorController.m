//
//  VisorController.m
//  Visor
//
//  Created by Nicholas Jitkoff on 6/1/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#define DEBUG_LOG_PATH "/Users/darwin/code/visor/Debug.log"

#import "VisorController.h"
#import "VisorWindow.h"
#import "NDHotKeyEvent_QSMods.h"
#import "VisorTermController.h"
#import <QuartzComposer/QuartzComposer.h>

#define VisorTerminalDefaults @"VisorTerminal"

NSString* stringForCharacter(const unsigned short aKeyCode, unichar aCharacter);

@implementation VisorController

+ (VisorController*) sharedInstance {
    static VisorController* plugin = nil;
    if (plugin == nil)
        plugin = [[VisorController alloc] init];
    return plugin;
}

+ (void) install {
    NSDictionary *defaults=[NSDictionary dictionaryWithContentsOfFile:[[NSBundle bundleForClass:[self class]]pathForResource:@"Defaults" ofType:@"plist"]];
    [[NSUserDefaults standardUserDefaults]registerDefaults:defaults];
    [VisorController sharedInstance];
}

// for SIMBL debugging
// http://www.atomicbird.com/blog/2007/07/code-quickie-redirect-nslog
- (void) redirectLog {
    // set permissions for our NSLog file
    NSBeep();
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
    
    if ([ud  boolForKey:@"VisorShowStatusItem"]) {
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
    
    [self controller]; // calls createController
    if ([ud boolForKey:@"VisorUseBackgroundAnimation"]) {
        [self backgroundWindow];
    }
    return self;
}

- (void)createController {
    if (controller) return;

    NSDisableScreenUpdates();
    NSNotificationCenter* dnc = [NSNotificationCenter defaultCenter];
    id profile = [[TTProfileManager sharedProfileManager] profileWithName:@"Visor"];
    controller = [NSApp newWindowControllerWithProfile:profile];

    NSWindow *window=[controller window];
    [window setLevel:NSFloatingWindowLevel];
    [window setOpaque:NO];
    [window setLevel:NSMainMenuWindowLevel-1];
    [self resetWindowPlace:window];
    [window setHasShadow:NO];

    [dnc addObserver:self selector:@selector(resignMain:) name:NSWindowDidResignMainNotification object:window];
    [dnc addObserver:self selector:@selector(resignKey:) name:NSWindowDidResignKeyNotification object:window];
    [dnc addObserver:self selector:@selector(becomeKey:) name:NSWindowDidBecomeKeyNotification object:window];
    [dnc addObserver:self selector:@selector(resized:) name:NSWindowDidResizeNotification object:window];
    NSEnableScreenUpdates();
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
    [NSApp activateIgnoringOtherApps:YES];
    [aboutWindow center];
    [aboutWindow makeKeyAndOrderFront:nil];
}

- (void)activateStatusMenu {
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
    if (hidden){
        [self showWindow];
    }else{
        [self hideWindow];
    }
}

- (void)resetWindowPlace:(id)window {
    float offset = 1.0f;
    if (hidden) offset = 0.0f;
    NSLog(@"offf %f", offset);
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
    [self updateBackgroundFrame];
}

- (void)adoptScreenWidth:(id)window {
    NSScreen* screen=[NSScreen mainScreen];
    NSRect screenRect=[screen frame];
    NSRect frame=screenRect; // shown Frame
    frame=[window frame]; // respect the existing height
    frame.size.width=screenRect.size.width; // make it the full screen width
    frame.origin.x+=NSMidX(screenRect)-NSMidX(frame); // center horizontally
    [window setFrame:frame display:NO];
    [self updateBackgroundFrame];
}

- (void)updateBackgroundFrame {
    BOOL useBackground = [[NSUserDefaults standardUserDefaults]boolForKey:@"VisorUseBackgroundAnimation"];
    if (useBackground) {
        [self backgroundWindow];
        NSWindow* window = [controller window];
        [backgroundWindow setFrame:[window frame] display:YES];
    } else {
        [self setBackgroundWindow:nil];
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

- (void)showWindow {
    if (!hidden) return;
    hidden = false;
    [self storePreviouslyActiveApp];
    [self maybeEnableEscapeKey:YES];
    [NSApp activateIgnoringOtherApps:YES];
    NSWindow *window=[controller window];
    [window makeKeyAndOrderFront:self];
    [window makeFirstResponder:[[controller selectedTabController] view]];
    [window setHasShadow:YES];
    if (backgroundWindow) {
        [[backgroundWindow contentView]startRendering];
    }
    [self slideWindows:1];
    [window invalidateShadow];
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
}

-(void)hideWindow {
    if (hidden) return;
    hidden = true;
    [self maybeEnableEscapeKey:NO];
    [self restorePreviouslyActiveApp];
    NSWindow *window=[[self controller] window];
    NSScreen *screen=[NSScreen mainScreen];
    NSRect screenRect=[screen frame];   
    NSRect showFrame=screenRect; // Shown Frame
    NSRect hideFrame=NSOffsetRect(showFrame,0,NSHeight(screenRect)/2+22); //hidden frame for start of animation
    [self saveDefaults];
    [self slideWindows:0];
    [window setHasShadow:NO];
    [window invalidateShadow];
    if (backgroundWindow) {
        [[backgroundWindow contentView]stopRendering];
    }
}

#define SLIDE_EASING(x) sin(M_PI_2*(x))
#define ALPHA_EASING(x) (1.0f-(x))
#define SLIDE_DIRECTION(d,x) (d?(x):1.0f-(x))
#define ALPHA_DIRECTION(d,x) (d?1.0f-(x):(x))

- (void)slideWindows:(BOOL)direction { // true == down
    NSAutoreleasePool* pool=[[NSAutoreleasePool alloc]init];
    NSWindow* window=[controller window];

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
                if (backgroundWindow) [backgroundWindow setAlphaValue:alpha];
                [window setAlphaValue:alpha];
            }
            usleep(5000); // 5ms
        }
    }

    // apply final state
    float offset = SLIDE_DIRECTION(direction, SLIDE_EASING(1));
    [self placeWindow:window offset:offset];
    // always set final alpha to 1, for case off-screen window gets onto the screen somehow (imagine display resize?)
    if (backgroundWindow) [backgroundWindow setAlphaValue:1.0]; // NSWindow caches these values, so let it know
    [window setAlphaValue:1.0]; // NSWindow caches these values, so let it know
}

// Callback for a closed shell
- (void)shell:(id)shell childDidExitWithStatus:(int)status {
    [self hideWindow];
    [self setController:nil];
}

- (void)saveDefaults {   
//  NSDictionary *defaults=[[controller defaults]dictionaryRepresentation];
//  [[NSUserDefaults standardUserDefaults]setObject:defaults forKey:VisorTerminalDefaults];
}

- (void)resignMain:(id)sender {
    if (!hidden){
        [self hideWindow];  
    }
}

- (void)resignKey:(id)sender {
    if ([[controller window]isVisible]){
        [[controller window]setLevel:NSFloatingWindowLevel];
        [backgroundWindow setLevel:NSFloatingWindowLevel-1];
    }
}

- (void)becomeKey:(id)sender {
    if ([[controller window]isVisible]){
        [[controller window]setLevel:NSMainMenuWindowLevel-1];
        [backgroundWindow setLevel:NSMainMenuWindowLevel-2];
    }
}

- (IBAction)chooseFile:(id)sender {
    NSOpenPanel *panel=[NSOpenPanel openPanel];
    [panel setTitle:@"Select a Quartz Composer (qtz) file"];
    if ([panel runModalForTypes:[NSArray arrayWithObject:@"qtz"]]){
        NSString *path=[panel filename];
        path=[path stringByAbbreviatingWithTildeInPath];
        [[NSUserDefaults standardUserDefaults]setObject:path forKey:@"VisorBackgroundAnimationFile"];
        [[NSUserDefaults standardUserDefaults]setBool:YES forKey:@"VisorUseBackgroundAnimation"];
    }
}

- (void)windowResized {
    [self adoptScreenWidth:[controller window]];
    [self saveDefaults];
}

- (void)resized:(NSNotification *)notif {
    [self adoptScreenWidth:[controller window]];
    [self saveDefaults];
}

- (NSWindow *)backgroundWindow {
    if (backgroundWindow) return [[backgroundWindow retain] autorelease];

    backgroundWindow = [[[NSWindow class] alloc] initWithContentRect:NSZeroRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
    [backgroundWindow orderFront:nil];
    [backgroundWindow setLevel:NSMainMenuWindowLevel-2];    
    [backgroundWindow setIgnoresMouseEvents:YES];
    [backgroundWindow setBackgroundColor: [NSColor blueColor]];
    [backgroundWindow setOpaque:NO];
    [backgroundWindow setHasShadow:NO];
    [backgroundWindow setReleasedWhenClosed:YES];
    [backgroundWindow setLevel:NSFloatingWindowLevel];
    [backgroundWindow setHasShadow:NO];
    QCView *content=[[[QCView alloc]init]autorelease];
    
    [backgroundWindow setContentView:content];
    
    NSString *path=[[NSUserDefaults standardUserDefaults]stringForKey:@"VisorBackgroundAnimationFile"];
    path=[path stringByStandardizingPath];
    
    NSFileManager *fm=[NSFileManager defaultManager];
    if (![fm fileExistsAtPath:path]){
        NSLog(@"animation does not exist: %@",path);
        path=nil;
    }
    
    if (!path)
        path=[[NSBundle bundleForClass:[self class]]pathForResource:@"Visor" ofType:@"qtz"];
    
    [content loadCompositionFromFile:path];
    [content startRendering];
    [content setMaxRenderingFrameRate:15.0];

    return [[backgroundWindow retain] autorelease];
}

- (void) setBackgroundWindow: (NSWindow *) newBackgroundWindow {
    if (backgroundWindow != newBackgroundWindow) {
        [backgroundWindow release];
        backgroundWindow = [newBackgroundWindow retain];
    }
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
        [self setBackgroundWindow:nil];
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

- (TermController*)controller {
    if (!controller)[self createController];
    return [[controller retain] autorelease];
}

- (void)setController:(TermController *)value {
    if (controller==value) return;
    [controller release];
    controller = [value retain];
}

@end