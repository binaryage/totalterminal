#import "GTMCarbonEvent.h"
#import "SRCommon.h"

typedef enum  {
    eUnknownShortcut = -1,
    eToggleVisor = 0,
    ePinVisor,
    eShortcutsCount
} TShortcuts;

@interface ModifierButtonImageView : NSImageView { }
-(void)mouseDown:(NSEvent*)event;
@end

@interface NSView (TotalTerminal)
-(NSView*)TotalTerminal_findSRRecorderFor:(NSString*)shortcut;
-(void)TotalTerminal_refreshSRRecorders;
@end

NSDictionary* makeKeyModifiersDictionary(NSInteger code, NSUInteger flags);
KeyCombo makeKeyComboFromDictionary(NSDictionary* hotkey);

@interface TotalTerminal : NSObject {
    NSWindow* window_;        // the one visorized terminal window (may be nil)
    NSWindow* background; // background window for quartz animations (will be nil if not enabled in settings!)
    NSStatusItem* statusItem;
    IBOutlet NSMenu* statusMenu;
    IBOutlet NSWindow* settingsWindow;
    IBOutlet NSPanel* transparencyHelpPanel;
    IBOutlet WebView* infoLine; // bottom info line on Visor preferences pane
    IBOutlet ModifierButtonImageView* modifierIcon1_;
    IBOutlet ModifierButtonImageView* modifierIcon2_;
    IBOutlet NSView* preferencesView;
    IBOutlet NSButton* createProfileButton_;
    GTMCarbonHotKey* hotKey_;
    GTMCarbonHotKey* escapeHotKey;
    NSUInteger hotModifiers_;
    NSUInteger hotModifiersState_;
    NSTimeInterval lastHotModifiersEventCheckedTime_;
    NSString* previouslyActiveAppPath;
    NSNumber* previouslyActiveAppPID;
    BOOL isHidden;
    BOOL isMain;
    BOOL isKey;
    NSImage* activeIcon;
    NSImage* inactiveIcon;
    NSImage* modifiersOption_;
    NSImage* modifiersControl_;
    NSImage* modifiersCommand_;
    NSImage* modifiersShift_;
    NSScreen* cachedScreen;
    NSString* cachedPosition;
    NSString* lastPosition;
    NSString* restoreAppAppleScriptSource;
    NSDictionary* scriptError;
    BOOL ignoreResizeNotifications;
    NSSize originalPreferencesSize;
    NSSize prefPaneSize;
    BOOL isActiveAlternativeIcon;
    NSImage* originalDockIcon;
    NSImage* alternativeDockIcon;
    BOOL preventShortcutUpdates_;
}

-(NSWindow*)window;
-(void)setWindow:(NSWindow*)inWindow;
-(NSWindow*)background;
-(void)setBackground:(NSWindow*)newBackground;
-(BOOL)isHidden;
-(BOOL)isVisorWindow:(id)win;
-(BOOL)status;

-(NSSize)originalPreferencesSize;
-(void)setOriginalPreferencesSize:(NSSize)size;
-(NSSize)prefPaneSize;

-(IBAction)showTransparencyHelpPanel:(id)sender;
-(IBAction)closeTransparencyHelpPanel:(id)sender;
-(IBAction)chooseBackgroundComposition:(id)sender;
-(IBAction)toggleVisor:(id)sender;
-(IBAction)showPrefs:(id)sender;
-(IBAction)visitHomepage:(id)sender;
-(IBAction)updateMe:(id)sender;
-(IBAction)createVisorProfile:(id)sender;

@property (readonly, nonatomic) NSNumber* shouldShowTransparencyAlert;
@end
