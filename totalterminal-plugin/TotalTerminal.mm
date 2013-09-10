#import "TotalTerminal.h"

@implementation TotalTerminal

-(void) awakeFromNib {
  NSLOG(@"awakeFromNib");
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

#if defined(DEBUG)
  if (![[NSUserDefaults standardUserDefaults] boolForKey:@"TotalTerminalDoNotLaunchCrashWatcher"]) {
    NSString* path = [[NSBundle bundleForClass:[self class]] pathForResource:@"TotalTerminalCrashWatcher" ofType:@"app"];
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

  [[TotalTerminal sharedInstance] openVisor];
}

-(id) init {
  AUTO_LOGGER();

  self = [super init];
  if (!self) return self;

  _preventShortcutUpdates = FALSE;
  _originalPreferencesSize.width = 0;
  _lastPosition = nil;
  _hotKey = nil;
  _escapeHotKey = nil;
  _fullScreenKey = nil;
  _background = nil;
  _statusItem = nil;

  [self refreshFeedURLInUpdater];

  _statusMenu = [[NSMenu alloc] initWithTitle:@"Status Menu"];

  [self setWindow:nil];

  _activeIcon = [[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self classForCoder]] pathForImageResource:@"VisorActive"]];
  in_activeIcon = [[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self classForCoder]] pathForImageResource:@"VisorInactive"]];

  _previouslyActiveAppPID = 0;
  _isHidden = true;
  _isMain = false;
  _isKey = false;

  [NSBundle loadNibNamed:@"TotalTerminal" owner:self];

  _isActiveAlternativeIcon = FALSE;
  _alternativeDockIcon = [[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForImageResource:@"TotalTerminal"]];
  _originalDockIcon = [[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForImageResource:@"Terminal"]];

  _modifiersOption = [[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForImageResource:@"ModifiersOption"]];
  _modifiersCommand = [[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForImageResource:@"ModifiersCommand"]];
  _modifiersControl = [[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForImageResource:@"ModifiersControl"]];
  _modifiersShift = [[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForImageResource:@"ModifiersShift"]];

  [self setupDockIcon];
  [self updateUIElement];

  [self initializeBackground];
  [self initStatusMenu];
  [self updateCachedShortcuts];
  [self updateStatusMenu];
  [self startEventMonitoring];

  NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
  if ([ud boolForKey:@"TotalTerminalShowStatusItem"]) {
    [self activateStatusMenu];
  }

  [self augumentMainMenu];
  [self registerObservers];

  [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(inputSourceChanged) name:(NSString*)kTISNotifySelectedKeyboardInputSourceChanged object:nil];

  _universalTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(universalTimerFired:) userInfo:nil repeats:YES];

  return self;
}

-(void) universalTimerFired:(NSTimer*)timer {
  // this polling code is used to track previous app when visor is shown
  // see updatePreviouslyActiveApp for more info
  if (![self isHidden]) {
    [self updatePreviouslyActiveApp];
  }
}

-(void) updateShouldShowTransparencyAlert {
  [self willChangeValueForKey:@"shouldShowTransparencyAlert"];
  [self didChangeValueForKey:@"shouldShowTransparencyAlert"];
}

-(NSNumber*) shouldShowTransparencyAlert {
  return ([[NSUserDefaults standardUserDefaults] boolForKey:@"TotalTerminalVisorUseBackgroundAnimation"] &&
          ((float)[self getVisorProfileBackgroundAlpha] >= 1.0f))
         ? (NSNumber*)kCFBooleanTrue : (NSNumber*)kCFBooleanFalse;
}

@end
