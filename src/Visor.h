#import "GTMCarbonEvent.h"

@interface Visor: NSObject {
    NSWindow* window; // the one visorized terminal window (may be nil)
    NSStatusItem* statusItem;
    IBOutlet NSMenu* statusMenu;
    IBOutlet NSWindow* settingsWindow;
    IBOutlet WebView* infoLine; // on Visor preferences pane
    EventHotKeyRef hotKey_;  // the hot key we're looking for. 
    NSUInteger hotModifiers_;  // if we are getting double taps, the mods to look for.
    NSUInteger hotModifiersState_;
    NSTimeInterval lastHotModifiersEventCheckedTime_;
    EventHotKeyRef escapeKey;
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

-(void)enahanceTerminalPreferencesWindowsettingsWindow;
-(NSToolbarItem*)getVisorToolbarItem;
- (void) updateInfoLine;
@end