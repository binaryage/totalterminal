#import "GTMCarbonEvent.h"
#import "SRCommon.h"

@class ModifierButtonImageView;

@interface TotalTerminal : NSObject {
  NSWindow* _window;   // the one visorized terminal window (may be nil)
  IBOutlet NSWindow* _colorsWindow;
  NSWindow* _background;   // background window for quartz animations (will be nil if not enabled in settings!)
  NSStatusItem* _statusItem;
  NSMenu* _statusMenu;
  IBOutlet NSWindow* _settingsWindow;
  IBOutlet NSPanel* _transparencyHelpPanel;
  IBOutlet WebView* _infoLine;   // bottom info line on Visor preferences pane
  IBOutlet ModifierButtonImageView* _modifierIcon1;
  IBOutlet ModifierButtonImageView* _modifierIcon2;
  IBOutlet NSView* _preferencesView;
  IBOutlet NSButton* _createProfileButton;
  GTMCarbonHotKey* _hotKey;
  GTMCarbonHotKey* _escapeHotKey;
  GTMCarbonHotKey* _fullScreenKey;
  NSUInteger _hotModifiers;
  NSUInteger _hotModifiersState;
  NSTimeInterval _lastHotModifiersEventCheckedTime;
  int _previouslyActiveAppPID;
  BOOL _isHidden;
  BOOL _isMain;
  BOOL _isKey;
  NSImage* _activeIcon;
  NSImage* in_activeIcon;
  NSImage* _modifiersOption;
  NSImage* _modifiersControl;
  NSImage* _modifiersCommand;
  NSImage* _modifiersShift;
  NSString* _lastPosition;
  NSSize _originalPreferencesSize;
  NSSize _prefPaneSize;
  BOOL _isActiveAlternativeIcon;
  NSImage* _originalDockIcon;
  NSImage* _alternativeDockIcon;
  BOOL _preventShortcutUpdates;
  NSTimer* _universalTimer;
}

+(TotalTerminal*)sharedInstance;

-(void)updateShouldShowTransparencyAlert;

@property (weak, readonly, nonatomic) NSNumber* shouldShowTransparencyAlert;

@end

#import "TotalTerminal+Defaults.h"
#import "TotalTerminal+Debug.h"
#import "TotalTerminal+Observers.h"
#import "TotalTerminal+StatusMenu.h"
#import "TotalTerminal+Preferences.h"
#import "TotalTerminal+Commands.h"
#import "TotalTerminal+Helpers.h"
#import "TotalTerminal+Dock.h"
#import "TotalTerminal+UIElement.h"
#import "TotalTerminal+Sparkle.h"
#import "TotalTerminal+Shortcuts.h"
#import "TotalTerminal+Menu.h"
#import "TotalTerminal+Features.h"
#import "TotalTerminal+Visor.h"
#import "TotalTerminal+TerminalColours.h"
#import "TotalTerminal+CopyOnSelect.h"
#import "TotalTerminal+PasteOnRightClick.h"
#import "TotalTerminal+AutoSlide.h"
