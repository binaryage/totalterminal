#import <Cocoa/Cocoa.h>

#import "TotalTerminal.h"

@interface TotalTerminal (Shortcuts)
-(KeyCombo)keyComboForShortcut:(TShortcuts)index;
-(void)updateCachedShortcuts;
@end
