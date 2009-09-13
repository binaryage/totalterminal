#import "GTMCarbonEvent.h"

@interface Visor: NSObject {
    NSWindow* window; // the one visorized terminal window (may be nil)
    NSStatusItem* statusItem;
    IBOutlet NSWindow* prefsWindow;
    IBOutlet NSMenu* statusMenu;
    IBOutlet NSWindow* aboutWindow;
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
}

@end