#import "VisorScreenTransformer.h"

@class TTProfileManager;
@class TTProfile;
@class NDHotKeyEvent;

@interface Visor: NSObject {
    NSWindow* window; // the one visorized terminal window (may be nil)
    NSRect initialFrame; // initial window dimensions, used for size reseting
    NSStatusItem* statusItem;
    IBOutlet NSWindow* prefsWindow;
    IBOutlet NSMenu* statusMenu;
    IBOutlet NSWindow* aboutWindow;
    NDHotKeyEvent* hotkey;
    NDHotKeyEvent* escapeKey;
    NSString* previouslyActiveApp;
    BOOL isHidden;
    BOOL justLaunched;
    BOOL isMain;
    BOOL isKey;
    BOOL isPinned;
    NSImage* activeIcon;
    NSImage* inactiveIcon;
    NSImage* pinUpIcon;
    NSImage* pinDownIcon;
    NSScreen* cachedScreen;
    NSButton* pinButton;
    NSString* cachedPosition;
}
+ (Visor*)sharedInstance;
- (BOOL)status;
- (void)adoptTerminal:(id)window;
- (IBAction)showPrefs:(id)sender;
- (IBAction)pinAction:(id)sender;
- (IBAction)toggleVisor:(id)sender;
- (IBAction)showAboutBox:(id)sender;
- (IBAction)visitHomepage:(id)sender;
- (void)showVisor:(BOOL)fast;
- (void)hideVisor:(BOOL)fast;
- (void)slideWindows:(BOOL)direction fast:(bool)fast;
- (void)restorePreviouslyActiveApp;
- (void)storePreviouslyActiveApp;
- (void)cacheScreen;
- (void)cachePosition;
- (void)resetWindowPlacement;
- (void)makeVisorInvisible;
- (void)enableHotKey;
- (void)initEscapeKey;
- (void)maybeEnableEscapeKey:(BOOL)enable;
- (void)activateStatusMenu;
- (void)updateStatusMenu;
- (void)applyWindowPositioning:(id)window;
- (void)onReopenVisor;
- (void)placeWindow:(id)window offset:(float)offset;
- (void)moveWindowOffScreen;
- (OSStatus)setupExposeTags:(NSWindow*)win;
@end