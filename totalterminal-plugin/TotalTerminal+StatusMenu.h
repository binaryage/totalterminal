#import "TotalTerminal.h"

@interface TotalTerminal (StatusMenu)

-(void)initStatusMenu;
-(void)activateStatusMenu;
-(void)deactivateStatusMenu;
-(void)updateStatusMenu;

-(BOOL)validateMenuItem:(NSMenuItem*)menuItem;

@end
