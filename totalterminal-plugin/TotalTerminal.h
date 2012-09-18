#import "GTMCarbonEvent.h"
#import "SRCommon.h"

@class ModifierButtonImageView;

@interface TotalTerminal : NSObject {
    NSWindow* window_; // the one visorized terminal window (may be nil)
    IBOutlet NSWindow* colorsWindow_;
    NSWindow* background_; // background window for quartz animations (will be nil if not enabled in settings!)
    NSStatusItem* statusItem_;
    NSMenu* statusMenu_;
    IBOutlet NSWindow* settingsWindow;
    IBOutlet NSPanel* transparencyHelpPanel;
    IBOutlet WebView* infoLine; // bottom info line on Visor preferences pane
    IBOutlet ModifierButtonImageView* modifierIcon1_;
    IBOutlet ModifierButtonImageView* modifierIcon2_;
    IBOutlet NSView* preferencesView;
    IBOutlet NSButton* createProfileButton_;
    GTMCarbonHotKey* hotKey_;
    GTMCarbonHotKey* escapeHotKey_;
    GTMCarbonHotKey* fullScreenKey_;
    NSUInteger hotModifiers_;
    NSUInteger hotModifiersState_;
    NSTimeInterval lastHotModifiersEventCheckedTime_;
    int previouslyActiveAppPID_;
    BOOL isHidden_;
    BOOL isMain_;
    BOOL isKey_;
    NSImage* activeIcon_;
    NSImage* inactiveIcon_;
    NSImage* modifiersOption_;
    NSImage* modifiersControl_;
    NSImage* modifiersCommand_;
    NSImage* modifiersShift_;
    NSString* lastPosition_;
    NSSize originalPreferencesSize;
    NSSize prefPaneSize;
    BOOL isActiveAlternativeIcon_;
    NSImage* originalDockIcon;
    NSImage* alternativeDockIcon;
    BOOL preventShortcutUpdates_;
    NSTimer* universalTimer_;
}

+(TotalTerminal*)sharedInstance;

-(void)updateShouldShowTransparencyAlert;

@property (readonly, nonatomic) NSNumber* shouldShowTransparencyAlert;

@end

#import "TotalTerminal+Defaults.h"
#import "TotalTerminal+Debug.h"
#import "TotalTerminal+Observers.h"
#import "TotalTerminal+StatusMenu.h"
#import "TotalTerminal+Preferences.h"
#import "TotalTerminal+Commands.h"
#import "TotalTerminal+Helpers.h"
#import "TotalTerminal+Dock.h"
#import "TotalTerminal+Sparkle.h"
#import "TotalTerminal+Shortcuts.h"
#import "TotalTerminal+Menu.h"
#import "TotalTerminal+Features.h"
#import "TotalTerminal+Visor.h"
#import "TotalTerminal+TerminalColours.h"
#import "TotalTerminal+CopyOnSelect.h"
#import "TotalTerminal+PasteOnRightClick.h"
#import "TotalTerminal+AutoSlide.h"
