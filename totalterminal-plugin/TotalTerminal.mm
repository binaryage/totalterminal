#import "TotalTerminal.h"
#include "TotalTerminal.h"

@implementation TotalTerminal

-(void) awakeFromNib {
    LOG(@"awakeFromNib");
    [self storePreferencesPaneSize];
}

+(TotalTerminal*) sharedInstance {
    static TotalTerminal* plugin = nil;

    if (!plugin) {
        plugin = [[TotalTerminal alloc] init];
    }
    return plugin;
}

+(void) launchCrashWatcher {
    AUTO_LOGGER();

#ifndef _DEBUG_MODE
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"TotalTerminalDoNotLaunchCrashWatcher"]) {
        NSString* path = [[NSBundle bundleForClass:[self class ]] pathForResource:@"TotalTerminalCrashWatcher" ofType:@"app"];
        INFO(@"Launching TotalTerminalCrashWatcher from '%@'", path);
        [[NSWorkspace sharedWorkspace] launchApplication:path];
    }
#endif
}

+(void) install {
    AUTO_LOGGER();

    [self launchCrashWatcher];

    [self initDebugSubsystems];

    // under 10.7 when TotalTerminal is injected during Terminal launch some windows may be going through restoration process
    // so the Terminal windows are not fully re-created
    [self performSelector:@selector(delayedBoot) withObject:nil afterDelay:2.0];
}

+(void) delayedBoot {
    AUTO_LOGGER();
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    [self sanitizeDefaults:ud];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"TotalTerminalCloseWindowsOnStart"]) {
        [self closeExistingWindows];
    }

    SWIZZLE(TTAppPrefsController, windowDidLoad);
    SWIZZLE(TTAppPrefsController, toolbar: itemForItemIdentifier: willBeInsertedIntoToolbar:);
    SWIZZLE(TTAppPrefsController, windowWillReturnFieldEditor: toObject:);
    SWIZZLE(TTAppPrefsController, tabView: didSelectTabViewItem:);

    [self loadFeatures];

    TotalTerminal* tt = [TotalTerminal sharedInstance];

    [tt openVisor];
}

-(id) init {
    AUTO_LOGGER();

    self = [super init];
    if (!self) return self;

    preventShortcutUpdates_ = FALSE;
    originalPreferencesSize.width = 0;
    lastPosition_ = nil;

    [self refreshFeedURLInUpdater];

    statusMenu = [[NSMenu alloc] initWithTitle:@"Status Menu"];

    [self setWindow:nil];

    activeIcon = [[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self classForCoder]] pathForImageResource:@"VisorActive"]];
    inactiveIcon = [[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self classForCoder]] pathForImageResource:@"VisorInactive"]];

    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    NSUserDefaultsController* udc = [NSUserDefaultsController sharedUserDefaultsController];

    previouslyActiveAppPID_ = 0;
    isHidden = true;
    isMain = false;
    isKey = false;

    [NSBundle loadNibNamed:@"TotalTerminal" owner:self];

    isActiveAlternativeIcon = FALSE;
    alternativeDockIcon = [[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class ]] pathForImageResource:@"TotalTerminal"]];
    originalDockIcon = [[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class ]] pathForImageResource:@"Terminal"]];

    modifiersOption_ = [[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class ]] pathForImageResource:@"ModifiersOption"]];
    modifiersCommand_ = [[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class ]] pathForImageResource:@"ModifiersCommand"]];
    modifiersControl_ = [[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class ]] pathForImageResource:@"ModifiersControl"]];
    modifiersShift_ = [[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class ]] pathForImageResource:@"ModifiersShift"]];

    [self setupDockIcon];

    [self initStatusMenu];
    [self updateCachedShortcuts];
    [self updateStatusMenu];
    [self updateHotKeyRegistration];
    [self updateEscapeHotKeyRegistration];
    [self startEventMonitoring];

    if ([ud boolForKey:@"TotalTerminalShowStatusItem"]) {
        [self activateStatusMenu];
    }

    [self augumentMainMenu];
    [self registerObservers];

    if ([ud boolForKey:@"TotalTerminalVisorUseBackgroundAnimation"]) {
        [self background];
    }

    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(inputSourceChanged) name:(NSString*)kTISNotifySelectedKeyboardInputSourceChanged object:nil];

    return self;
}

@end
