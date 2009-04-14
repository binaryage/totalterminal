#import "VisorScreenTransformer.h"

@class TTProfileManager;
@class TTProfile;
@class NDHotKeyEvent;

@interface Visor: NSObject {
    NSWindow* window; // the one visorized terminal window (may be nil)
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
- (BOOL)status;
- (void)adoptTerminal:(NSWindow*)window;
- (IBAction)showPrefs:(id)sender;
- (IBAction)toggleVisor:(id)sender;
- (IBAction)setHotKey:(id)sender;
- (IBAction)chooseFile:(id)sender;
- (IBAction)showAboutBox:(id)sender;
- (void)hideVisor;
- (void)showVisor;
- (void)makeVisorInvisible;
- (void)enableHotKey;
- (void)initEscapeKey;
- (void)maybeEnableEscapeKey:(BOOL)enable;
- (void)activateStatusMenu;
- (void)saveDefaults;
- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)item;
@end