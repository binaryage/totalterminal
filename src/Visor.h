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
    NSString* lastPosition;
    BOOL ignoreResizeNotifications;
}
- (IBAction)pinAction:(id)sender;
- (IBAction)toggleVisor:(id)sender;
- (IBAction)showPrefs:(id)sender;
- (IBAction)visitHomepage:(id)sender;
@end