#import "Macros.h"
#import "JRSwizzle.h"
#import "CGSPrivate.h"
#import "Visor.h"
#import "GTMHotKeyTextField.h"
#import "QSBKeyMap.h"
#import "GTMCarbonEvent.h"

@interface NSEvent (Visor)
- (NSUInteger)qsbModifierFlags;
@end

@implementation NSEvent (QSBApplicationEventAdditions)

- (NSUInteger)qsbModifierFlags {
  NSUInteger flags = ([self modifierFlags] & NSDeviceIndependentModifierFlagsMask);
  // Ignore caps lock if it's set http://b/issue?id=637380
  if (flags & NSAlphaShiftKeyMask) flags -= NSAlphaShiftKeyMask;
  // Ignore numeric lock if it's set http://b/issue?id=637380
  if (flags & NSNumericPadKeyMask) flags -= NSNumericPadKeyMask;
  return flags;
}

@end

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// main entry point

int main(int argc, char *argv[]) {
    return NSApplicationMain(argc,  (const char **) argv);
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// VisorScreenTransformer - helper class for properties dialog

@interface VisorScreenTransformer: NSValueTransformer {
}
@end

@implementation VisorScreenTransformer

+ (Class)transformedValueClass {
    LOG(@"transformedValueClass");
    return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation {
    LOG(@"allowsReverseTransformation");
    
    return YES;
}

- (id)transformedValue:(id)value {
    LOG(@"transformedValue %@", value);
    return [NSString stringWithFormat: @"Screen %d", [value integerValue]];
}

- (id)reverseTransformedValue:(id)value {
    LOG(@"reverseTransformedValue %@", value);
    return [NSNumber numberWithInteger:[[value substringFromIndex:6] integerValue]];
}

@end

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// NSWindowController monkey patching

@implementation NSWindowController (Visor)

//------------------------------------------------------------
// TTAppPrefsController hacks

// Add Visor preference pane into Preferences window
- (void)Visor_TTAppPrefsController_windowDidLoad {
    [self Visor_TTAppPrefsController_windowDidLoad];
    LOG(@"Visor_TTAppPrefsController_windowDidLoad");
    id visor = [Visor sharedInstance];
    [visor enahanceTerminalPreferencesWindow];
}

- (void)Visor_TTAppPrefsController_selectVisorPane {
    LOG(@"Visor_TTAppPrefsController_selectVisorPane");
    id visor = [Visor sharedInstance]; // for some reason Visor_TTAppPrefsController_windowDidLoad may be not called in rare case we started visor and created Visor profile
    [visor enahanceTerminalPreferencesWindow];
    NSWindow* prefsWindow = [self window];
    [prefsWindow setTitle:@"Visor"];
    NSToolbar* toolbar = [prefsWindow toolbar];
    [toolbar setSelectedItemIdentifier:@"Visor"];
    NSTabView* tabView = [self valueForKey:@"tabView"];
    [tabView selectTabViewItemWithIdentifier:@"VisorPane"];
}

- (id)Visor_TTAppPrefsController_toolbar:(id)arg1 itemForItemIdentifier:(id)arg2 willBeInsertedIntoToolbar:(BOOL)arg3 {
    LOG(@"Visor_TTAppPrefsController_toolbar:itemForItemIdentifier:willBeInsertedIntoToolbar => %@", arg2);
    if ([arg2 isEqualToString:@"Visor"]) {
        id visor = [Visor sharedInstance];
        NSToolbarItem* toolbarItem = [visor getVisorToolbarItem];
        [toolbarItem setTarget:self];
        [toolbarItem setAction:@selector(Visor_TTAppPrefsController_selectVisorPane)];
        return toolbarItem;
    }
    return [self Visor_TTAppPrefsController_toolbar:arg1 itemForItemIdentifier:arg2 willBeInsertedIntoToolbar:arg3];
}

- (id) Visor_TTAppPrefsController_windowWillReturnFieldEditor:(NSWindow *)sender toObject:(id)client {
    if ([client isKindOfClass:[GTMHotKeyTextField class]]) {
        LOG(@"Visor_TTAppPrefsController_windowWillReturnFieldEditor with GTMHotKeyTextField");
        return [GTMHotKeyFieldEditor sharedHotKeyFieldEditor];
    }
    return [self Visor_TTAppPrefsController_windowWillReturnFieldEditor:sender toObject:client];
}

- (id) windowWillReturnFieldEditor:(NSWindow *)sender toObject:(id)client {
    return nil;
}

//------------------------------------------------------------
// TTWindowController hacks

- (void)Visor_TTWindowController_setCloseDialogExpected:(BOOL)fp8 {
    LOG(@"Visor_TTWindowController_setCloseDialogExpected");
    if (fp8) {
        // THIS IS A MEGAHACK! (works for me on Leopard 10.5.6)
        // the problem: beginSheet causes UI to lock for NSBorderlessWindowMask NSWindow which is in "closing mode"
        //
        // this hack tries to open sheet before window starts it's closing procedure
        // we expect that setCloseDialogExpected is called by Terminal.app once BEFORE window gets into "closing mode"
        // in this case we are able to open sheet before window starts closing and this works even for window with NSBorderlessWindowMask
        // it works like a magic, took me few hours to figure out this random stuff
        Visor* visor = [Visor sharedInstance];
        [visor showVisor:false];
        [self displayWindowCloseSheet:1];
    }
}

- (NSRect)window:(NSWindow *)window willPositionSheet:(NSWindow *)sheet usingRect:(NSRect)rect {
    return rect;
}

- (NSRect)Visor_TTWindowController_window:(NSWindow *)window willPositionSheet:(NSWindow *)sheet usingRect:(NSRect)rect {
    LOG(@"Visor_TTWindowController_window");
    Visor* visor = [Visor sharedInstance];
    [visor setupExposeTags:sheet];
    return rect;
}

// swizzled function for original TTWindowController::newTabWithProfile
// this seems to be a good point to intercept new tab creation
// responsible for opening all tabs in Visored window with Visor profile (regardless of "default profile" setting)
- (id)Visor_TTWindowController_newTabWithProfile:(id)arg1 {
    LOG(@"creating a new tab");
    id this = self;
    id visor = [Visor sharedInstance];
    BOOL isVisoredWindow = [visor isVisoredWindow:[this window]];
    if (isVisoredWindow) {
        LOG(@"  in visored window ... so apply visor profile");
        id profileManagerClass = NSClassFromString(@"TTProfileManager");
        id profileManager = [profileManagerClass sharedProfileManager];
        id visorProfile = [profileManager profileWithName:@"Visor"];
        if (visorProfile) {
            arg1 = visorProfile;
        } else {
            LOG(@"  ... unable to lookup Visor profile!");
        }
    }
    return [self Visor_TTWindowController_newTabWithProfile:arg1];
}

// this is variant of the ^^^
// this seems to be an alternative point to intercept new tab creation
- (id)Visor_TTWindowController_newTabWithProfile:(id)arg1 command:(id)arg2 runAsShell:(BOOL)arg3 {
    LOG(@"creating a new tab (with runAsShell)");
    id this = self;
    id visor = [Visor sharedInstance];
    BOOL isVisoredWindow = [visor isVisoredWindow:[this window]];
    if (isVisoredWindow) {
        LOG(@"  in visored window ... so apply visor profile");
        id profileManager = [NSClassFromString(@"TTProfileManager") sharedProfileManager];
        id visorProfile = [profileManager profileWithName:@"Visor"];
        if (visorProfile) {
            arg1 = visorProfile;
        } else {
            LOG(@"  ... unable to lookup Visor profile!");
        }
    }
    return [self Visor_TTWindowController_newTabWithProfile:arg1 command:arg2 runAsShell:arg3];
}

@end

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// NSApplication monkey patching

@implementation NSApplication (Visor)

- (void)Visor_sendEvent:(NSEvent *)theEvent {
    NSUInteger type = [theEvent type];
    if (type == NSFlagsChanged) {
        Visor* visor = [Visor sharedInstance];
        [visor modifiersChangedWhileActive:theEvent];
    } else if (type == NSKeyDown || type == NSKeyUp) {
        Visor* visor = [Visor sharedInstance];
        [visor keysChangedWhileActive:theEvent];
    }
    [self Visor_sendEvent:theEvent];
}

- (BOOL)Visor_TTAplication_applicationShouldHandleReopen:(id)fp8 hasVisibleWindows:(BOOL)fp12 {
    LOG(@"Visor_TTAplication_applicationShouldHandleReopen");
    Visor* visor = [Visor sharedInstance];
    [visor onReopenVisor];
    return [self Visor_TTAplication_applicationShouldHandleReopen:fp8 hasVisibleWindows:(BOOL)fp12];
}

@end

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// NSWindow monkey patching

@implementation NSWindow (Visor)

- (id) Visor_initWithContentRect: (NSRect) contentRect styleMask: (unsigned int) aStyle backing: (NSBackingStoreType) bufferingType defer: (BOOL) flag {
    LOG(@"Creating a new terminal window %@", [self class]);
    Visor* visor = [Visor sharedInstance];
    BOOL shouldBeVisorized = ![visor status];
    if (shouldBeVisorized) {
        aStyle = NSBorderlessWindowMask;
        bufferingType = NSBackingStoreBuffered;
    }
    self = [self Visor_initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag];
    if (shouldBeVisorized) {
        [visor adoptTerminal:self];
    }
    return self;
}

- (BOOL) Visor_canBecomeKeyWindow {
    LOG(@"canBecomeKeyWindow");
    return YES;
}

- (BOOL) Visor_canBecomeMainWindow {
    LOG(@"canBecomeMainWindow");
    return YES;
}

@end

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Visor implementation

@implementation Visor

-(NSToolbarItem*)getVisorToolbarItem {
    LOG(@"getVisorToolbarItem");
    NSToolbar* sourceToolbar = [settingsWindow toolbar];
    NSToolbarItem* toolbarItem = [[sourceToolbar items] objectAtIndex:0];
    return toolbarItem;
}

- (void) enahanceTerminalPreferencesWindow {
    static bool alreadyEnhanced = NO;
    if (alreadyEnhanced) return;
    alreadyEnhanced = YES;

    LOG(@"enahanceTerminalPreferencesWindow");

    id prefsController = [NSClassFromString(@"TTAppPrefsController") sharedPreferencesController];
    NSTabView* tabView = [prefsController valueForKey:@"tabView"];

    NSWindow* prefsWindow = [prefsController window];
    NSToolbar* toolbar = [prefsWindow toolbar];
    
    NSTabView* sourceTabView = [[[settingsWindow contentView] subviews] objectAtIndex:0];
    NSTabViewItem* item = [sourceTabView tabViewItemAtIndex:0];
    
    [toolbar insertItemWithItemIdentifier:@"Visor" atIndex:4];
    [tabView addTabViewItem:item];
}

+ (Visor*) sharedInstance {
    static Visor* plugin = nil;
    if (plugin == nil)
        plugin = [[Visor alloc] init];
    return plugin;
}

+ (id) getOrCreateVisorProfile {
    LOG(@"createVisorProfileIfNeeded");
    id profileManager = [NSClassFromString(@"TTProfileManager") sharedProfileManager];
    id visorProfile = [profileManager profileWithName:@"Visor"];
    if (!visorProfile) {
        LOG(@"   ... initialising Visor profile");
        
        // create visor profile in case it does not exist yet, use startup profile as a template
        id startupProfile = [profileManager startupProfile];
        visorProfile = [startupProfile copyWithZone:nil];

        // apply Darwin's preferred Visor settings
        Visor* visor = [Visor sharedInstance];
        NSData *plistData;
        NSString *error;
        NSPropertyListFormat format;
        id plist;
        NSString *path = [[NSBundle bundleForClass:[visor class]] pathForResource:@"VisorProfile" ofType:@"plist"]; 
        plistData = [NSData dataWithContentsOfFile:path]; 
        plist = [NSPropertyListSerialization propertyListFromData:plistData mutabilityOption:NSPropertyListImmutable format:&format errorDescription:&error];
        if (!plist) {
            LOG(@"Error reading plist from file '%s', error = '%s'", [path UTF8String], [error UTF8String]);
            [error release];
        }
        [visorProfile setPropertyListRepresentation:plist];

        // set profile into manager
        [profileManager setProfile:visorProfile forName:@"Visor"];
        [visorProfile release];
    }
    return visorProfile;
}

+ (void) closeExistingWindows {
    id wins = [[NSClassFromString(@"TTApplication") sharedApplication] windows];
    int winCount = [wins count];
    for (int i=0; i<winCount; i++) {
        id win = [wins objectAtIndex:i];
        if (!win) continue;
        if ([[win className] isEqualToString:@"TTWindow"]) {
            [win close];
        }
    }
}

+ (void) install {
    LOG(@"Visor installed");

    [NSClassFromString(@"TTWindowController") jr_swizzleMethod:@selector(newTabWithProfile:) withMethod:@selector(Visor_TTWindowController_newTabWithProfile:) error:NULL];
    [NSClassFromString(@"TTWindowController") jr_swizzleMethod:@selector(newTabWithProfile:command:runAsShell:) withMethod:@selector(Visor_TTWindowController_newTabWithProfile:command:runAsShell:) error:NULL];
    [NSClassFromString(@"TTWindowController") jr_swizzleMethod:@selector(setCloseDialogExpected:) withMethod:@selector(Visor_TTWindowController_setCloseDialogExpected:) error:NULL];
    [NSClassFromString(@"TTWindowController") jr_swizzleMethod:@selector(window:willPositionSheet:usingRect:) withMethod:@selector(Visor_TTWindowController_window:willPositionSheet:usingRect:) error:NULL];
    
    [NSClassFromString(@"TTWindow") jr_swizzleMethod:@selector(initWithContentRect:styleMask:backing:defer:) withMethod:@selector(Visor_initWithContentRect:styleMask:backing:defer:) error:NULL];
    [NSClassFromString(@"TTWindow") jr_swizzleMethod:@selector(canBecomeKeyWindow) withMethod:@selector(Visor_canBecomeKeyWindow) error:NULL];
    [NSClassFromString(@"TTWindow") jr_swizzleMethod:@selector(canBecomeMainWindow) withMethod:@selector(Visor_canBecomeMainWindow) error:NULL];

    [NSClassFromString(@"TTApplication") jr_swizzleMethod:@selector(sendEvent:) withMethod:@selector(Visor_sendEvent:) error:NULL];
    [NSClassFromString(@"TTApplication") jr_swizzleMethod:@selector(applicationShouldHandleReopen:hasVisibleWindows:) withMethod:@selector(Visor_TTAplication_applicationShouldHandleReopen:hasVisibleWindows:) error:NULL];

    [NSClassFromString(@"TTAppPrefsController") jr_swizzleMethod:@selector(windowDidLoad) withMethod:@selector(Visor_TTAppPrefsController_windowDidLoad) error:NULL];
    [NSClassFromString(@"TTAppPrefsController") jr_swizzleMethod:@selector(toolbar:itemForItemIdentifier:willBeInsertedIntoToolbar:) withMethod:@selector(Visor_TTAppPrefsController_toolbar:itemForItemIdentifier:willBeInsertedIntoToolbar:) error:NULL];
    [NSClassFromString(@"TTAppPrefsController") jr_swizzleMethod:@selector(windowWillReturnFieldEditor:toObject:) withMethod:@selector(Visor_TTAppPrefsController_windowWillReturnFieldEditor:toObject:) error:NULL];
    
    NSDictionary* defaults = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle bundleForClass:[self class]]pathForResource:@"Defaults" ofType:@"plist"]];
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    [ud registerDefaults:defaults];
    [self sanitizeDefaults:ud];

    [self closeExistingWindows];
    id visorProfile = [self getOrCreateVisorProfile];
    id app = [NSClassFromString(@"TTApplication") sharedApplication];
    id controller = [app newWindowControllerWithProfile:visorProfile];
    
    Visor* visor = [Visor sharedInstance];
    [visor resetWindowPlacement];

    [controller release];
}


- (BOOL)status {
    return !!window;
}

- (BOOL)isVisoredWindow:(id)win {
    return window==win;
}

+ (void) load {
    LOG(@"Visor loaded");
}

static const EventTypeSpec kModifierEventTypeSpec[] = { { kEventClassKeyboard, kEventRawKeyModifiersChanged } };
static const size_t kModifierEventTypeSpecSize = sizeof(kModifierEventTypeSpec) / sizeof(EventTypeSpec);

// Allows me to intercept the "control" double tap to activate QSB. There 
// appears to be no way to do this from straight Cocoa.
- (void)startEventMonitoring {
    GTMCarbonEventMonitorHandler *handler = [GTMCarbonEventMonitorHandler sharedEventMonitorHandler];
    [handler registerForEvents:kModifierEventTypeSpec count:kModifierEventTypeSpecSize];
    [handler setDelegate:self];
}

- (void)stopEventMonitoring {
    GTMCarbonEventMonitorHandler *handler = [GTMCarbonEventMonitorHandler sharedEventMonitorHandler];
    [handler unregisterForEvents:kModifierEventTypeSpec count:kModifierEventTypeSpecSize];
    [handler setDelegate:nil];
}

- (OSStatus)gtm_eventHandler:(GTMCarbonEventHandler *)sender 
               receivedEvent:(GTMCarbonEvent *)event 
                     handler:(EventHandlerCallRef)handler {
  OSStatus status = eventNotHandledErr;
  if ([event eventClass] == kEventClassKeyboard &&
      [event eventKind] == kEventRawKeyModifiersChanged) {
    UInt32 modifiers;
    if ([event getUInt32ParameterNamed:kEventParamKeyModifiers data:&modifiers]) {
      NSUInteger cocoaMods = GTMCarbonToCocoaKeyModifiers(modifiers);
      NSEvent *nsEvent = [NSEvent keyEventWithType:NSFlagsChanged
                                          location:[NSEvent mouseLocation]
                                     modifierFlags:cocoaMods
                                         timestamp:[event time]
                                      windowNumber:0
                                           context:nil
                                        characters:nil
                       charactersIgnoringModifiers:nil
                                         isARepeat:NO
                                           keyCode:0];
      [self modifiersChangedWhileInactive:nsEvent];
    }
  }
  return status;
}

+ (void) sanitizeDefaults:(NSUserDefaults*) ud {
    LOG(@"sanitizeDefaults");
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
    if (![ud objectForKey:@"VisorPosition"]) {
        [ud setObject:@"Top-Stretch" forKey:@"VisorPosition"];
    }
    // by default enable HotKey as Control+` (CTRL+tilde)
    if (![ud objectForKey:@"VisorHotKey"]) {
        [ud setObject:[NSDictionary dictionaryWithObjectsAndKeys: \
                         [NSNumber numberWithUnsignedInt:NSControlKeyMask], \
                         kGTMHotKeyModifierFlagsKey, \
                         [NSNumber numberWithUnsignedInt:50], \
                         kGTMHotKeyKeyCodeKey, \
                         [NSNumber numberWithBool:NO], \
                         kGTMHotKeyDoubledModifierKey, \
                         nil]
            forKey:@"VisorHotKey"];
    }
    // convert hot-key format from 2.0 -> 2.1
    NSDictionary* hotkey = [ud objectForKey:@"VisorHotKey"];
    NSNumber* keyCode = [hotkey objectForKey:@"keyCode"];
    NSNumber* modifiers = [hotkey objectForKey:@"modifiers"];
    if (keyCode && modifiers) {
        LOG(@"-> conversion of hotkey from 2.0 format %@ %@ %@", hotkey, keyCode, modifiers);
        [ud setObject:[NSDictionary dictionaryWithObjectsAndKeys: \
                         modifiers, \
                         kGTMHotKeyModifierFlagsKey, \
                         keyCode, \
                         kGTMHotKeyKeyCodeKey, \
                         [NSNumber numberWithBool:NO], \
                         kGTMHotKeyDoubledModifierKey, \
                         nil]
            forKey:@"VisorHotKey"];
    }
    
    if (![ud objectForKey:@"VisorHotKeyEnabled"]) {
        [ud setBool:YES forKey:@"VisorHotKeyEnabled"];
    }
    // by default disable HotKey2 but set it to double Control
    if (![ud objectForKey:@"VisorHotKey2"]) {
        [ud setObject:[NSDictionary dictionaryWithObjectsAndKeys: \
                         [NSNumber numberWithUnsignedInt:NSControlKeyMask], \
                         kGTMHotKeyModifierFlagsKey, \
                         [NSNumber numberWithUnsignedInt:0], \
                         kGTMHotKeyKeyCodeKey, \
                         [NSNumber numberWithBool:YES], \
                         kGTMHotKeyDoubledModifierKey, \
                         nil]
            forKey:@"VisorHotKey2"];
    }
    if (![ud objectForKey:@"VisorHotKey2Enabled"]) {
        [ud setBool:NO forKey:@"VisorHotKey2Enabled"];
    }
}

- (void)webView:(WebView *)sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id<WebPolicyDecisionListener>)listener {    
    LOG(@"webView:decidePolicyForNavigationAction...");
    if ([[actionInformation objectForKey:WebActionNavigationTypeKey] intValue] != WebNavigationTypeOther) {
        [listener ignore];
        [[NSWorkspace sharedWorkspace] openURL:[request URL]];
    } else {
        [listener use];
    }
}

- (void) updateInfoLine {
    LOG(@"updateInfoLine %@", infoLine);
    [[infoLine mainFrame] loadHTMLString:@"<style>html {font-family: 'Lucida Grande', arial; font-size: 10px; cursor: default; color: #999;} a, a:visited { color: #66f; } a:hover {color: #22f}</style><center><b>Visor **VERSION**</b> (<a href=\"http://github.com/darwin/visor/commit/**SHA**\">**REVISION**</a>) by <a href=\"http://binaryage.com\">binaryage.com</a>, based on Visor 1.5 by <a href=\"http://blacktree.com\">blacktree.com</a></center>" baseURL:[NSURL URLWithString:@"http://visor.binaryage.com"]];
    [infoLine setDrawsBackground:NO];
}

- (void)awakeFromNib {
    LOG(@"awakeFromNib");
    [self updateInfoLine];
}

- (id) init {
    self = [super init];
    if (!self) return self;

    LOG(@"Visor init");
    
    runningApplicationClass = NSClassFromString(@"NSRunningApplication"); // 10.6

    NSString* path = [[NSBundle bundleForClass:[self class]] pathForResource:@"RestoreApp" ofType:@"scpt"];
    restoreAppAppleScriptSource = [[NSString alloc] initWithContentsOfFile:path encoding:NSMacOSRomanStringEncoding error:NULL]; 
    scriptError = [[NSDictionary alloc] init]; 
    
    window = NULL;
    
    activeIcon=[[NSImage alloc]initWithContentsOfFile:[[NSBundle bundleForClass:[self classForCoder]]pathForImageResource:@"VisorActive"]];
    inactiveIcon=[[NSImage alloc]initWithContentsOfFile:[[NSBundle bundleForClass:[self classForCoder]]pathForImageResource:@"VisorInactive"]];
    
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    NSUserDefaultsController* udc = [NSUserDefaultsController sharedUserDefaultsController];
    
    previouslyActiveAppPath = nil;
    isHidden = true;
    isMain = false;
    isKey = false;
    
    [NSBundle loadNibNamed:@"Visor" owner:self];
    
    [self updateHotKeyRegistration];
    [self updateEscapeHotKeyRegistration];
    [self startEventMonitoring];

    if ([ud boolForKey:@"VisorShowStatusItem"]) {
        [self activateStatusMenu];
    }
    
    // watch for hotkey changes
    [udc addObserver:self forKeyPath:@"values.VisorHotKey" options:0 context:nil];
    [udc addObserver:self forKeyPath:@"values.VisorHotKeyEnabled" options:0 context:nil];
    [udc addObserver:self forKeyPath:@"values.VisorHotKey2" options:0 context:nil];
    [udc addObserver:self forKeyPath:@"values.VisorHotKey2Enabled" options:0 context:nil];
    [udc addObserver:self forKeyPath:@"values.VisorUseFade" options:0 context:nil];                                                           
    [udc addObserver:self forKeyPath:@"values.VisorUseSlide" options:0 context:nil];               
    [udc addObserver:self forKeyPath:@"values.VisorAnimationSpeed" options:0 context:nil];
    [udc addObserver:self forKeyPath:@"values.VisorShowStatusItem" options:0 context:nil];
    [udc addObserver:self forKeyPath:@"values.VisorScreen" options:0 context:nil];
    [udc addObserver:self forKeyPath:@"values.VisorPosition" options:0 context:nil];
    [udc addObserver:self forKeyPath:@"values.VisorHideOnEscape" options:0 context:nil];
    
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
    [dnc addObserver:self selector:@selector(didResize:) name:NSWindowDidResizeNotification object:window];
    
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
        return;
    }
    if (isHidden) {
        [self showVisor:false];
    } else {
        [self restorePreviouslyActiveApp];
        [self hideVisor:false];
    }
}

- (IBAction)showPrefs:(id)sender {
    [NSApp activateIgnoringOtherApps:YES];
    id terminalApp = [NSClassFromString(@"TTApplication") sharedApplication];
    [terminalApp showPreferencesWindow:nil];
    id prefsController = [NSClassFromString(@"TTAppPrefsController") sharedPreferencesController];
    [prefsController Visor_TTAppPrefsController_selectVisorPane];
}
 
- (IBAction)visitHomepage:(id)sender {
    LOG(@"visitHomepage");
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://visor.binaryage.com"]];
}

- (void)resetWindowPlacement {
    lastPosition = nil;
    if (!window) return;
    float offset = 1.0f;
    if (isHidden) offset = 0.0f;
    LOG(@"resetWindowPlacement %@ %f", window, offset);
    [self cacheScreen];
    [self cachePosition];
    [self applyWindowPositioning:window];
    [self slideWindows:!isHidden fast:YES];
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
    LOG(@"resetVisorWindowSize");
    
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
    id profileManagerClass = NSClassFromString(@"TTProfileManager");
    id profileManager = [profileManagerClass sharedProfileManager];
    id visorProfile = [profileManager profileWithName:@"Visor"];
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
    ignoreResizeNotifications = TRUE;
    [self setupExposeTags:win];
    NSScreen* screen = cachedScreen;
    NSRect screenRect = [screen frame];
    NSString* position = [[NSUserDefaults standardUserDefaults] stringForKey:@"VisorPosition"];
    if (![position isEqualToString:lastPosition]) {
        // note: cursor may jump during this operation, so do it only in rare cases when position changes
        // for more info see http://github.com/darwin/visor/issues#issue/27
        [self resetVisorWindowSize:win];
    }
    lastPosition = position;
    LOG(@"applyWindowPositioning %@", position);
    int shift = 0; // see http://code.google.com/p/blacktree-visor/issues/detail?id=19
    if (screen == [[NSScreen screens] objectAtIndex: 0]) shift = 21; // menu area
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
    ignoreResizeNotifications = FALSE;
}

- (void)storePreviouslyActiveApp {
    LOG(@"storePreviouslyActiveApp");
    if (!runningApplicationClass) {
        // 10.5 path
        NSDictionary *activeAppDict = [[NSWorkspace sharedWorkspace] activeApplication];
        previouslyActiveAppPath = nil;
        if ([[activeAppDict objectForKey:@"NSApplicationBundleIdentifier"] compare:@"com.apple.Terminal"]) {
            previouslyActiveAppPath = [[NSString alloc] initWithString:[activeAppDict objectForKey:@"NSApplicationPath"]];
        }
        LOG(@"  (10.5) -> %@", previouslyActiveAppPath);
    } else {
        // 10.6+ path
        NSDictionary *activeAppDict = [[NSWorkspace sharedWorkspace] activeApplication];
        previouslyActiveAppPID = nil;
        if ([[activeAppDict objectForKey:@"NSApplicationBundleIdentifier"] compare:@"com.apple.Terminal"]) {
            previouslyActiveAppPID = [activeAppDict objectForKey:@"NSApplicationProcessIdentifier"];
        }
        LOG(@"  (10.6) -> %@", previouslyActiveAppPID);
    }
}

- (void)restorePreviouslyActiveApp {
    if (!runningApplicationClass) {
        if (!previouslyActiveAppPath) return;
        LOG(@"restorePreviouslyActiveApp %@", previouslyActiveAppPath);
        // 10.5 path
        // Visor crashes when trying to return focus to non-running application? (http://github.com/darwin/visor/issues#issue/12)
        NSString* scriptSource = [[NSString alloc] initWithFormat:restoreAppAppleScriptSource, previouslyActiveAppPath];
        NSAppleScript* appleScript = [[NSAppleScript alloc] initWithSource:scriptSource]; 
        [appleScript executeAndReturnError: &scriptError];
        [appleScript release];
        [scriptSource release];
        previouslyActiveAppPath = nil;
    } else {
        // 10.6+ path
        LOG(@"xrestorePreviouslyActiveApp %@", previouslyActiveAppPID);
        if (!previouslyActiveAppPID) return;
        LOG(@"restorePreviouslyActiveApp %@", previouslyActiveAppPID);
        id app = [runningApplicationClass runningApplicationWithProcessIdentifier: [previouslyActiveAppPID intValue]];
        if (app) {
            LOG(@"  ... activating %@", app);
            [app activateWithOptions:0];
        }
        previouslyActiveAppPID = nil;
    }
}

- (void)onReopenVisor {
    bool showOnReopen = [[NSUserDefaults standardUserDefaults] boolForKey:@"VisorShowOnReopen"];
    if (!showOnReopen) return;
    [self showVisor:NO];
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
    [window makeKeyAndOrderFront:self];
    [window setHasShadow:YES];
    [self applyWindowPositioning:window];
    [window update];
    [self slideWindows:1 fast:fast];
    [window invalidateShadow];
    [window update];
}

-(void)hideOnEscape {
    LOG(@"hideOnEscape");
    [self hideVisor:NO];
}

-(void)hideVisor:(BOOL)fast {
    if (isHidden) return;
    LOG(@"hideVisor %d", fast);
    isHidden = true;
    [self updateStatusMenu];
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
    [self updateEscapeHotKeyRegistration];
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
    [self updateEscapeHotKeyRegistration];
}

- (void)becomeMain:(id)sender {
    LOG(@"becomeMain %@", sender);
    isMain = true;
}

- (void)didChangeScreenScreenParameters:(id)sender {
    LOG(@"didChangeScreenScreenParameters %@", sender);
    [self resetWindowPlacement];
}

- (void)didResize:(id)sender {
    if (ignoreResizeNotifications) return;
    LOG(@"didResize %@", sender);
    lastPosition = nil;
}

- (void)willClose:(id)sender {
    LOG(@"willClose %@", sender);
    window = nil;
    [self updateStatusMenu];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    LOG(@"observeValueForKeyPath %@", keyPath);
    if ([keyPath isEqualToString:@"values.VisorShowStatusItem"]) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"VisorShowStatusItem"]) {
            [self activateStatusMenu];
        } else {
            [self deactivateStatusMenu];
        }
    } else {
        [self updateHotKeyRegistration];
    }
    if ([keyPath isEqualToString:@"values.VisorPosition"]) {
        [self resetWindowPlacement];
    }
    if ([keyPath isEqualToString:@"values.VisorScreen"]) {
        [self resetWindowPlacement];
    }
    if ([keyPath isEqualToString:@"values.VisorOnEverySpace"]) {
        [self resetWindowPlacement];
    }
    if ([keyPath isEqualToString:@"values.VisorHideOnEscape"]) {
        [self updateEscapeHotKeyRegistration];
    }
}

- (void)updateHotKeyRegistration {
    LOG(@"updateHotKeyRegistration");
    GTMCarbonEventDispatcherHandler *dispatcher = [GTMCarbonEventDispatcherHandler sharedEventDispatcherHandler];

    if (hotKey_) {
        [dispatcher unregisterHotKey:hotKey_];
        hotKey_ = nil;
    }

    NSMenuItem *statusMenuItem = [statusMenu itemAtIndex:0];
    NSString *statusMenuItemKey = @"";
    uint statusMenuItemModifiers = 0;
    [statusMenuItem setKeyEquivalent:statusMenuItemKey];
    [statusMenuItem setKeyEquivalentModifierMask:statusMenuItemModifiers];
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSDictionary *newKey = [ud valueForKeyPath:@"VisorHotKey"];
    NSNumber *value = [newKey objectForKey:kGTMHotKeyDoubledModifierKey];
    BOOL hotKey1UseDoubleModifier = [value boolValue];
    BOOL hotkey1Enabled = [ud boolForKey:@"VisorHotKeyEnabled"];
    BOOL hotkey2Enabled = [ud boolForKey:@"VisorHotKey2Enabled"];
    if (!newKey || hotKey1UseDoubleModifier || hotkey2Enabled) {
        // set up double tap if appropriate
        hotModifiers_ = NSControlKeyMask;
        statusMenuItemKey = [NSString stringWithUTF8String:"⌃"];
        statusMenuItemModifiers = NSControlKeyMask;
    } else {
        hotModifiers_ = 0;
    }
    if (hotkey1Enabled && !hotKey1UseDoubleModifier) {
        // setting hotModifiers_ means we're not looking for a double tap
        value = [newKey objectForKey:kGTMHotKeyModifierFlagsKey];
        uint modifiers = [value unsignedIntValue];
        value = [newKey objectForKey:kGTMHotKeyKeyCodeKey];
        uint keycode = [value unsignedIntValue];
        hotKey_ = [dispatcher registerHotKey:keycode
                                   modifiers:modifiers
                                      target:self
                                      action:@selector(toggleVisor:)
                                 whenPressed:YES];

        NSBundle *bundle = [NSBundle bundleForClass:[GTMHotKeyTextField class]];
        statusMenuItemKey = [GTMHotKeyTextField stringForKeycode:keycode
                                                        useGlyph:YES
                                                  resourceBundle:bundle];
        statusMenuItemModifiers = modifiers;
    }
    [statusMenuItem setKeyEquivalent:statusMenuItemKey];
    [statusMenuItem setKeyEquivalentModifierMask:statusMenuItemModifiers];
}

- (void)updateEscapeHotKeyRegistration {
    BOOL hideOnEscape = [[NSUserDefaults standardUserDefaults] boolForKey:@"VisorHideOnEscape"];
    if (hideOnEscape && isKey) {
        if (!escapeHotKey) {
            GTMCarbonEventDispatcherHandler *dispatcher = [GTMCarbonEventDispatcherHandler sharedEventDispatcherHandler];
            escapeHotKey = [dispatcher registerHotKey:53
                                       modifiers:0
                                          target:self
                                          action:@selector(hideOnEscape)
                                     whenPressed:YES];
        }
    } else {
        if (escapeHotKey) {
            GTMCarbonEventDispatcherHandler *dispatcher = [GTMCarbonEventDispatcherHandler sharedEventDispatcherHandler];
            [dispatcher unregisterHotKey:escapeHotKey];
            escapeHotKey = nil;
        }
    }
}

NSString* stringForCharacter(const unsigned short aKeyCode, unichar aCharacter);

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem {
    if ([menuItem action]==@selector(toggleVisor:)){
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
    if (statusItem) return;
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

- (void)deactivateStatusMenu {
    if (!statusItem) return;
    [statusItem release];
    statusItem = nil;
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

// Returns the amount of time between two clicks to be considered a double click
- (NSTimeInterval)doubleClickTime {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSTimeInterval doubleClickThreshold = [defaults doubleForKey:@"com.apple.mouse.doubleClickThreshold"];

    // if we couldn't find the value in the user defaults, take a 
    // conservative estimate
    if (doubleClickThreshold <= 0.0) {
        doubleClickThreshold = 1.0;
    }
    return doubleClickThreshold;
}

- (void)modifiersChangedWhileActive:(NSEvent*)event {
    // A statemachine that tracks our state via hotModifiersState_.
    // Simple incrementing state.
    if (!hotModifiers_) {
        return;
    }
    NSTimeInterval timeWindowToRespond = lastHotModifiersEventCheckedTime_ + [self doubleClickTime];
    lastHotModifiersEventCheckedTime_ = [event timestamp];
    if (hotModifiersState_ && lastHotModifiersEventCheckedTime_ > timeWindowToRespond) {
        // Timed out. Reset.
        hotModifiersState_ = 0;
        return;
    }
    NSUInteger flags = [event qsbModifierFlags];
    BOOL isGood = NO;
    if (!(hotModifiersState_ % 2)) {
        // This is key down cases
        isGood = flags == hotModifiers_;
    } else {
        // This is key up cases
        isGood = flags == 0;
    }
    if (!isGood) {
        // reset
        hotModifiersState_ = 0;
        return;
    } else {
        hotModifiersState_ += 1;
    }
    LOG(@"  => %d", hotModifiersState_);
    if (hotModifiersState_ >= 3) {
        // We've worked our way through the state machine to success!
        [self toggleVisor:self];
        hotModifiersState_ = 0;
    }
}

// method that is called when a key changes state and we are active
- (void)keysChangedWhileActive:(NSEvent*)event {
    if (!hotModifiers_) return;
    hotModifiersState_ = 0;
}

// method that is called when the modifier keys are hit and we are inactive
- (void)modifiersChangedWhileInactive:(NSEvent*)event {
    // If we aren't activated by hotmodifiers, we don't want to be here
    // and if we are in the process of activating, we want to ignore the hotkey
    // so we don't try to process it twice.
    if (!hotModifiers_ || [NSApp keyWindow]) return;

    NSUInteger flags = [event qsbModifierFlags];
    if (flags != hotModifiers_) return;
    const useconds_t oneMilliSecond = 10000;
    UInt16 modifierKeys[] = {
        0,
        kVK_Shift,
        kVK_CapsLock,
        kVK_RightShift,
    };
    if (hotModifiers_ == NSControlKeyMask) {
        modifierKeys[0] = kVK_Control;
    } else if (hotModifiers_ == NSAlternateKeyMask) {
        modifierKeys[0]  = kVK_Option;
    } else if (hotModifiers_ == NSCommandKeyMask) {
        modifierKeys[0]  = kVK_Command;
    }
    QSBKeyMap *hotMap = [[[QSBKeyMap alloc] initWithKeys:modifierKeys count:1] autorelease];
    QSBKeyMap *invertedHotMap = [[[QSBKeyMap alloc] initWithKeys:modifierKeys count:sizeof(modifierKeys) / sizeof(UInt16)] autorelease];
    invertedHotMap = [invertedHotMap keyMapByInverting];
    NSTimeInterval startDate = [NSDate timeIntervalSinceReferenceDate];
    BOOL isGood = NO;
    while(([NSDate timeIntervalSinceReferenceDate] - startDate) < [self doubleClickTime]) {
        QSBKeyMap *currentKeyMap = [QSBKeyMap currentKeyMap];
        if ([currentKeyMap containsAnyKeyIn:invertedHotMap] || GetCurrentButtonState()) {
            return;
        }
        if (![currentKeyMap containsAnyKeyIn:hotMap]) {
            // Key released;
            isGood = YES;
            break;
        }
        usleep(oneMilliSecond);
    }
    if (!isGood) return;
    isGood = NO;
    startDate = [NSDate timeIntervalSinceReferenceDate];
    while(([NSDate timeIntervalSinceReferenceDate] - startDate) < [self doubleClickTime]) {
        QSBKeyMap *currentKeyMap = [QSBKeyMap currentKeyMap];
        if ([currentKeyMap containsAnyKeyIn:invertedHotMap] || GetCurrentButtonState()) {
            return;
        }
        if ([currentKeyMap containsAnyKeyIn:hotMap]) {
            // Key down
            isGood = YES;
            break;
        }
        usleep(oneMilliSecond);
    }
    if (!isGood) return;
    startDate = [NSDate timeIntervalSinceReferenceDate];
    while(([NSDate timeIntervalSinceReferenceDate] - startDate) < [self doubleClickTime]) {
        QSBKeyMap *currentKeyMap = [QSBKeyMap currentKeyMap];
        if ([currentKeyMap containsAnyKeyIn:invertedHotMap]) {
            return;
        }
        if (![currentKeyMap containsAnyKeyIn:hotMap]) {
            // Key Released
            isGood = YES;
            break;
        }
        usleep(oneMilliSecond);
    }
    if (isGood) {
        [self toggleVisor:self];
    }
}

- (id)windowWillReturnFieldEditor:(NSWindow *)sender toObject:(id)client {
    if ([client isKindOfClass:[GTMHotKeyTextField class]]) {
        return [GTMHotKeyFieldEditor sharedHotKeyFieldEditor];
    }
    return nil;
}

@end