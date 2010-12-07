#import "GTMCarbonEvent.h"

@interface Visor: NSObject {
    NSWindow        *window_; // the one visorized terminal window (may be nil)
    NSWindow* background; // background window for quartz animations (will be nil if not enabled in settings!)
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
    BOOL    ignoreResizeNotifications;
    id      runningApplicationClass_;
    BOOL    runningOnLeopard_;
    BOOL    dontShowOnFirstTab;
}

- (NSWindow *)window;
- (void)setWindow:(NSWindow *)inWindow;
- (NSWindow*)background;
- (void)setBackground:(NSWindow*)newBackground;
- (BOOL)isHidden;

- (IBAction)chooseBackgroundComposition:(id)sender;
- (IBAction)pinAction:(id)sender;
- (IBAction)toggleVisor:(id)sender;
- (IBAction)showPrefs:(id)sender;
- (IBAction)visitHomepage:(id)sender;
@end