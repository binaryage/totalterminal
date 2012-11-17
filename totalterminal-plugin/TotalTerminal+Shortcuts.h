#import "TotalTerminal.h"

typedef enum  {
  eUnknownShortcut = -1,
  eToggleVisor = 0,
  ePinVisor,
  eShortcutsCount
} TShortcuts;

NSDictionary* makeKeyModifiersDictionary(NSInteger code, NSUInteger flags);
KeyCombo makeKeyComboFromDictionary(NSDictionary* hotkey);

@interface TotalTerminal (Shortcuts)

-(KeyCombo)keyComboForShortcut:(TShortcuts)index;
-(void)updateCachedShortcuts;

@end
