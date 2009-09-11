#import "Macros.h"
#import "JRSwizzle.h"
#import "CGSPrivate.h"
#import "NDHotKeyEvent_QSMods.h"
#import "Visor.h"
#import "VisorWindow.h"
#import "VisorScreenTransformer.h"

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

@implementation NSObject (Visor)
// swizzled function for original TTWindowController::newTabWithProfile
// this seems to be a good point to intercept new tab creation
// responsible for opening all tabs in Visored window with Visor profile (regardless of "default profile" setting)
- (id)Visor_newTabWithProfile:(id)arg1 {
    LOG(@"creating a new tab");
    Visor* visor = [Visor sharedInstance];
    BOOL isVisoredWindow = [visor isVisoredWindow:[self window]];
    if (isVisoredWindow) {
        LOG(@"  in visored window ... so apply visor profile");
        TTProfileManager* profileManager = [TTProfileManager sharedProfileManager];
        TTProfile* visorProfile = [profileManager profileWithName:@"Visor"];
        if (!visorProfile) {
            LOG(@"  ... unable to lookup Visor profile!");
            return;
        }
        arg1 = visorProfile;
    }
    return [self Visor_newTabWithProfile:arg1];
}

// this is variant of the ^^^
// this seems to be an alternative point to intercept new tab creation
- (id)Visor_newTabWithProfile:(id)arg1 command:(id)arg2 runAsShell:(BOOL)arg3 {
    LOG(@"creating a new tab (with runAsShell)");
    Visor* visor = [Visor sharedInstance];
    BOOL isVisoredWindow = [visor isVisoredWindow:[self window]];
    if (isVisoredWindow) {
        LOG(@"  in visored window ... so apply visor profile");
        TTProfileManager* profileManager = [TTProfileManager sharedProfileManager];
        TTProfile* visorProfile = [profileManager profileWithName:@"Visor"];
        if (!visorProfile) {
            LOG(@"  ... unable to lookup Visor profile!");
            return;
        }
        arg1 = visorProfile;
    }
    return [self Visor_newTabWithProfile:arg1 command:arg2 runAsShell:arg3];
}

@end

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

- (BOOL)isVisoredWindow:(id)win {
    return window==win;
}

// for SIMBL debugging
// http://www.atomicbird.com/blog/2007/07/code-quickie-redirect-nslog
- (void) redirectLog {
    // set permissions for our LOG file
    umask(022);
    // send stderr to our file
    freopen(DEBUG_LOG_PATH, "w", stderr);
}

- (id) init {
    self = [super init];
    if (!self) return self;

    // sizzling responsible for forcing all tabs opened in visored window to start with profile "Visor"
    [NSClassFromString(@"TTWindowController") jr_swizzleMethod:@selector(newTabWithProfile:) withMethod:@selector(Visor_newTabWithProfile:) error:NULL];
    [NSClassFromString(@"TTWindowController") jr_swizzleMethod:@selector(newTabWithProfile:command:runAsShell:) withMethod:@selector(Visor_newTabWithProfile:command:runAsShell:) error:NULL];
    
#ifdef _DEBUG_MODE
    [self redirectLog];
#endif
    LOG(@"init");
    
    window = NULL;
    
    activeIcon=[[NSImage alloc]initWithContentsOfFile:[[NSBundle bundleForClass:[self classForCoder]]pathForImageResource:@"VisorActive"]];
    inactiveIcon=[[NSImage alloc]initWithContentsOfFile:[[NSBundle bundleForClass:[self classForCoder]]pathForImageResource:@"VisorInactive"]];
    
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
    if (![ud objectForKey:@"VisorShowOnReopen"]) {
        [ud setBool:YES forKey:@"VisorShowOnReopen"];
    }
    if (![ud objectForKey:@"VisorCopyOnSelect"]) {
        [ud setBool:NO forKey:@"VisorCopyOnSelect"];
    }
    if (![ud objectForKey:@"VisorScreen"]) {
        [ud setInteger:0 forKey:@"VisorScreen"]; // use screen 0 by default
    }
    if (![ud objectForKey:@"VisorOnEverySpace"]) {
        [ud setBool:YES forKey:@"VisorOnEverySpace"];
    }
    if (![ud objectForKey:@"VisorPosition"]) {
        [ud setObject:@"Top-Stretch" forKey:@"VisorPosition"];
    }
    
    // add the "Visor Preferences..." item to the Terminal menu
    NSMenuItem* prefsMenuItem = [statusMenu itemWithTitle:@"Visor Preferences..."];
    NSMenuItem* copy = [prefsMenuItem copyWithZone:nil];
    [[[[NSApp mainMenu] itemAtIndex:0] submenu] insertItem:copy atIndex:3];
    [copy release];
    
    if ([ud boolForKey:@"VisorShowStatusItem"]) {
        [self activateStatusMenu];
    }
    
    [self enableHotKey];
    [self initEscapeKey];
    
    // watch for hotkey changes
    [udc addObserver:self forKeyPath:@"values.VisorHotKey" options:0 context:nil];
    [udc addObserver:self forKeyPath:@"values.VisorUseFade" options:0 context:nil];                                                           
    [udc addObserver:self forKeyPath:@"values.VisorUseSlide" options:0 context:nil];               
    [udc addObserver:self forKeyPath:@"values.VisorAnimationSpeed" options:0 context:nil];
    [udc addObserver:self forKeyPath:@"values.VisorShowStatusItem" options:0 context:nil];
    [udc addObserver:self forKeyPath:@"values.VisorScreen" options:0 context:nil];
    [udc addObserver:self forKeyPath:@"values.VisorPosition" options:0 context:nil];

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
    [dnc addObserver:self selector:@selector(willClose:) name:NSWindowWillCloseNotification object:window];
    [dnc addObserver:self selector:@selector(didChangeScreenScreenParameters:) name:NSApplicationDidChangeScreenParametersNotification object:nil];
    
    justLaunched = true;
    [self updateStatusMenu];
}

- (IBAction)pinAction:(id)sender {
    LOG(@"pinAction %@", sender);
    isPinned = !isPinned;
    [self updateStatusMenu];
}

- (IBAction)toggleVisor:(id)sender {
    LOG(@"toggleVisor %@ %d", sender, isHidden);
    if (!window) {
        LOG(@"visor is detached");
        NSBeep();
        return;
    }
    if (isHidden) {
        [self showVisor:false];
    } else {
        [self restorePreviouslyActiveApp];
        [self hideVisor:false];
    }
}

- (void)moveWindowOffScreen {
    if (!window) return;
    LOG(@"moveWindowOffScreen");

    NSRect r;
    r.origin.x = 0;
    r.origin.y = -400;
    r.size.width = 1000;
    r.size.height = 400;
    [window setFrame:r display:YES];
    [window setHasShadow:NO];
    [window invalidateShadow];
    [window update];
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
    NSArray* screens = [NSScreen screens];
    if (!(screenIndex>0 && screenIndex<[screens count])) screenIndex = 0;
    cachedScreen = [screens objectAtIndex:screenIndex];
    LOG(@"Cached screen %d %@", screenIndex, cachedScreen);
}

// offset==0.0 means window is "hidden" above top screen edge
// offset==1.0 means window is visible right under top screen edge
- (void)placeWindow:(id)win offset:(float)offset {
    NSScreen* screen=cachedScreen;
    NSRect screenRect=[screen frame];
    NSRect frame=[win frame];
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
    [win setFrame:frame display:YES];
}

- (void)resetVisorWindowSize:(id)win {
    // this block is needed to prevent "<NSSplitView>: the delegate <InterfaceController> was sent -splitView:resizeSubviewsWithOldSize: and left the subview frames in an inconsistent state" type of message
    // http://cocoadev.com/forums/comments.php?DiscussionID=1092
    // this issue is only on Snow Leopard (10.6), because it is newly using NSSplitViews
    NSRect safeFrame;
    safeFrame.origin.x = 0;
    safeFrame.origin.y = 0;
    safeFrame.size.width = 1;
    safeFrame.size.height = 1;
    [win setFrame:safeFrame display:NO];

    // this is kind of a hack
    // I'm using scripting API to update main window geometry according to profile settings
    // note: this will resize all Terminal.app windows using "Visor" profile
    //       this should not be an issue because only Visor-ed window should use this profile
    TTProfileManager* profileManager = [TTProfileManager sharedProfileManager];
    TTProfile* visorProfile = [profileManager profileWithName:@"Visor"];
    if (!visorProfile) {
        LOG(@"  ... unable to lookup Visor profile!");
        return;
    }
    NSNumber* cols = [visorProfile scriptNumberOfColumns];
    NSNumber* rows = [visorProfile scriptNumberOfRows];
    [visorProfile setScriptNumberOfColumns:cols];
    [visorProfile setScriptNumberOfRows:rows];
}

- (void)applyWindowPositioning:(id)win {
    [self setupExposeTags:win];
    NSScreen* screen = cachedScreen;
    NSRect screenRect = [screen frame];
    NSString* position = [[NSUserDefaults standardUserDefaults] stringForKey:@"VisorPosition"];
    LOG(@"applyWindowPositioning %@", position);
    int shift = 0; // see http://code.google.com/p/blacktree-visor/issues/detail?id=19
    if (screen == [[NSScreen screens] objectAtIndex: 0]) shift = 21; // menu area
    [self resetVisorWindowSize:win];
    if ([position isEqualToString:@"Top-Stretch"]) {
        NSRect frame = [win frame];
        frame.size.width = screenRect.size.width;
        frame.origin.x = screenRect.origin.x;
        frame.origin.y = screenRect.origin.y + NSHeight(screenRect) - shift;
        [win setFrame:frame display:YES];
    }
    if ([position isEqualToString:@"Top-Left"]) {
        NSRect frame = [win frame];
        frame.origin.x = screenRect.origin.x;
        frame.origin.y = screenRect.origin.y + NSHeight(screenRect) - shift;
        [win setFrame:frame display:YES];
    }
    if ([position isEqualToString:@"Top-Right"]) {
        NSRect frame = [win frame];
        frame.origin.x = screenRect.origin.x + NSWidth(screenRect) - NSWidth(frame);
        frame.origin.y = screenRect.origin.y + NSHeight(screenRect) - shift;
        [win setFrame:frame display:YES];
    }
    if ([position isEqualToString:@"Top-Center"]) {
        NSRect frame = [win frame];
        frame.origin.x = screenRect.origin.x + (NSWidth(screenRect)-NSWidth(frame))/2;
        frame.origin.y = screenRect.origin.y + NSHeight(screenRect) - shift;
        [win setFrame:frame display:YES];
    }
    if ([position isEqualToString:@"Left-Stretch"]) {
        NSRect frame = [win frame];
        frame.size.height = screenRect.size.height - shift;
        frame.origin.x = screenRect.origin.x - NSWidth(frame);
        frame.origin.y = screenRect.origin.y + NSHeight(screenRect) - NSHeight(frame) - shift;
        [win setFrame:frame display:YES];
    }
    if ([position isEqualToString:@"Left-Top"]) {
        NSRect frame = [win frame];
        frame.origin.x = screenRect.origin.x - NSWidth(frame);
        frame.origin.y = screenRect.origin.y + NSHeight(screenRect) - NSHeight(frame) - shift;
        [win setFrame:frame display:YES];
    }
    if ([position isEqualToString:@"Left-Bottom"]) {
        NSRect frame = [win frame];
        frame.origin.x = screenRect.origin.x - NSWidth(frame);
        frame.origin.y = screenRect.origin.y;
        [win setFrame:frame display:YES];
    }
    if ([position isEqualToString:@"Left-Center"]) {
        NSRect frame = [win frame];
        frame.origin.x = screenRect.origin.x - NSWidth(frame);
        frame.origin.y = screenRect.origin.y + (NSHeight(screenRect)-NSHeight(frame))/2;
        [win setFrame:frame display:YES];
    }
    if ([position isEqualToString:@"Right-Stretch"]) {
        NSRect frame = [win frame];
        frame.size.height = screenRect.size.height - shift;
        frame.origin.x = screenRect.origin.x + NSWidth(screenRect);
        frame.origin.y = screenRect.origin.y + NSHeight(screenRect) - NSHeight(frame) - shift;
        [win setFrame:frame display:YES];
    }
    if ([position isEqualToString:@"Right-Top"]) {
        NSRect frame = [win frame];
        frame.origin.x = screenRect.origin.x + NSWidth(screenRect);
        frame.origin.y = screenRect.origin.y + NSHeight(screenRect) - NSHeight(frame) - shift;
        [win setFrame:frame display:YES];
    }
    if ([position isEqualToString:@"Right-Bottom"]) {
        NSRect frame = [win frame];
        frame.origin.x = screenRect.origin.x + NSWidth(screenRect);
        frame.origin.y = screenRect.origin.y;
        [win setFrame:frame display:YES];
    }
    if ([position isEqualToString:@"Right-Center"]) {
        NSRect frame = [win frame];
        frame.origin.x = screenRect.origin.x + NSWidth(screenRect);
        frame.origin.y = screenRect.origin.y + (NSHeight(screenRect)-NSHeight(frame))/2;
        [win setFrame:frame display:YES];
    }
    if ([position isEqualToString:@"Bottom-Stretch"]) {
        NSRect frame = [win frame];
        frame.size.width = screenRect.size.width;
        frame.origin.x = screenRect.origin.x;
        frame.origin.y = screenRect.origin.y - NSHeight(frame);
        [win setFrame:frame display:YES];
    }
    if ([position isEqualToString:@"Bottom-Left"]) {
        NSRect frame = [win frame];
        frame.origin.x = screenRect.origin.x;
        frame.origin.y = screenRect.origin.y - NSHeight(frame);
        [win setFrame:frame display:YES];
    }
    if ([position isEqualToString:@"Bottom-Right"]) {
        NSRect frame = [win frame];
        frame.origin.x = screenRect.origin.x + NSWidth(screenRect) - NSWidth(frame);
        frame.origin.y = screenRect.origin.y - NSHeight(frame);
        [win setFrame:frame display:YES];
    }
    if ([position isEqualToString:@"Bottom-Center"]) {
        NSRect frame = [win frame];
        frame.origin.x = screenRect.origin.x + (NSWidth(screenRect)-NSWidth(frame))/2;
        frame.origin.y = screenRect.origin.y - NSHeight(frame);
        [win setFrame:frame display:YES];
    }
    if ([position isEqualToString:@"Full Screen"]) {
        NSRect frame = [win frame];
        frame.size.width = screenRect.size.width;
        frame.size.height = screenRect.size.height - shift;
        frame.origin.x = screenRect.origin.x;
        frame.origin.y = screenRect.origin.y;
        [win setFrame:frame display:YES];
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
    // see: http://lists.apple.com/archives/Applescript-users/2007/Mar/msg00265.html
    NSString *scriptSource = [NSString stringWithFormat: @"tell application \"%@\"\nwith timeout of 1 seconds\nactivate\nend timeout\nend tell", previouslyActiveApp]; 
    NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:scriptSource]; 
    [appleScript executeAndReturnError: &scriptError];
    [appleScript release];
    [scriptError release];
    [previouslyActiveApp release];
    previouslyActiveApp = nil;
}

- (void)onReopenVisor {
    bool showOnReopen = [[NSUserDefaults standardUserDefaults] boolForKey:@"VisorShowOnReopen"];
    if (!showOnReopen) return;
    [self showVisor:false];
}

- (void)showVisor:(BOOL)fast {
    if (!isHidden) return;
    LOG(@"showVisor %d", fast);
    isHidden = false;
    [self updateStatusMenu];
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
    LOG(@"hideVisor %d", fast);
    isHidden = true;
    [self updateStatusMenu];
    [self maybeEnableEscapeKey:NO];
    [window update];
    [self slideWindows:0 fast:fast];
    [window setHasShadow:NO];
    [window invalidateShadow];
    [window update];
}

#define SLIDE_EASING(x) sin(M_PI_2*(x))
#define ALPHA_EASING(x) (1.0f-(x))
#define SLIDE_DIRECTION(d,x) (d?(x):(1.0f-(x)))
#define ALPHA_DIRECTION(d,x) (d?(1.0f-(x)):(x))

- (void)slideWindows:(BOOL)direction fast:(bool)fast { // true == down
    if (!fast) {
        BOOL doSlide = [[NSUserDefaults standardUserDefaults]boolForKey:@"VisorUseSlide"];
        BOOL doFade = [[NSUserDefaults standardUserDefaults]boolForKey:@"VisorUseFade"];
        float animSpeed = [[NSUserDefaults standardUserDefaults]floatForKey:@"VisorAnimationSpeed"];

        // animation loop
        if (doFade || doSlide) {
            if (!doSlide && direction) { // setup final slide position in case of no sliding
                float offset = SLIDE_DIRECTION(direction, SLIDE_EASING(1));
                [self placeWindow:window offset:offset];
            }
            if (!doFade && direction) { // setup final alpha state in case of no alpha
                float alpha = ALPHA_DIRECTION(direction, ALPHA_EASING(1));
                [window setAlphaValue: alpha];
            }
            NSTimeInterval t;
            NSDate* date=[NSDate date];
            while (animSpeed>(t=-[date timeIntervalSinceNow])) { // animation update loop
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
    
    // apply final slide and alpha states
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
}

- (void)didChangeScreenScreenParameters:(id)sender {
    LOG(@"didChangeScreenScreenParameters %@", sender);
    [self resetWindowPlacement];
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

- (IBAction)visitHomepage:(id)sender {
    LOG(@"visitHomepage");
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://visor.binaryage.com"]];
}

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem {
    if ([menuItem action]==@selector(toggleVisor:)){
        [menuItem setKeyEquivalent:stringForCharacter([hotkey keyCode],[hotkey character])];
        [menuItem setKeyEquivalentModifierMask:[hotkey modifierFlags]];
        return [self status];
    }
    return YES;
}

- (NSInteger)numberOfItemsInComboBox:(NSComboBox*)aComboBox {
    LOG(@"numberOfItemsInComboBox %@", aComboBox);
    return [[NSScreen screens] count];
}

- (id)comboBox:(NSComboBox*)aComboBox objectValueForItemAtIndex:(NSInteger)index{
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

    // update first menu item
    NSMenuItem* showItem = [statusMenu itemAtIndex:0];
    if (isHidden)
        [showItem setTitle:@"Show Visor"];
    else
        [showItem setTitle:@"Hide Visor"];

    // update second menu item
    NSMenuItem* pinItem = [statusMenu itemAtIndex:1];
    if (!isPinned)
        [pinItem setTitle:@"Pin Visor"];
    else
        [pinItem setTitle:@"Unpin Visor"];
    
    // update icon
    BOOL status = [self status];
    if (status)
        [statusItem setImage:activeIcon];
    else
        [statusItem setImage:inactiveIcon];
}

@end