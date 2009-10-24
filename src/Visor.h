#import "GTMCarbonEvent.h"

@interface Visor: NSObject {
    NSWindow* window; // the one visorized terminal window (may be nil)
    NSStatusItem* statusItem;
    IBOutlet NSMenu* statusMenu;
    IBOutlet NSWindow* settingsWindow;
    IBOutlet WebView* infoLine; // bottom info line on Visor preferences pane
    EventHotKeyRef hotKey_;
    NSUInteger hotModifiers_;
    NSUInteger hotModifiersState_;
    NSTimeInterval lastHotModifiersEventCheckedTime_;
    EventHotKeyRef escapeHotKey;
    NSString* previouslyActiveAppPath;
    NSNumber* previouslyActiveAppPID;
    BOOL isHidden;
    BOOL isMain;
    BOOL isKey;
    BOOL isPinned;
    NSImage* activeIcon;
    NSImage* inactiveIcon;
    NSScreen* cachedScreen;
    NSString* cachedPosition;
    NSString* lastPosition;
    NSString* restoreAppAppleScriptSource;
    NSDictionary* scriptError;
    BOOL ignoreResizeNotifications;
    id runningApplicationClass;
}

- (NSWindow *)window;
- (BOOL)isHidden;

- (IBAction)pinAction:(id)sender;
- (IBAction)toggleVisor:(id)sender;
- (IBAction)showPrefs:(id)sender;
- (IBAction)visitHomepage:(id)sender;
@end