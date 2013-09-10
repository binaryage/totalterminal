#import "TotalTerminal+Dock.h"

@implementation TotalTerminal (Dock)
-(void) setupDockIcon {
  BOOL hasOriginalIcon = [[NSUserDefaults standardUserDefaults] boolForKey:@"TotalTerminalDontCustomizeDockIcon"];

  if (!hasOriginalIcon) {
    if (!_isActiveAlternativeIcon) {
      _isActiveAlternativeIcon = TRUE;
      [NSApp setApplicationIconImage:_alternativeDockIcon];
    }
  } else {
    if (_isActiveAlternativeIcon) {
      _isActiveAlternativeIcon = FALSE;
      [NSApp setApplicationIconImage:_originalDockIcon];
    }
  }
}

@end
