// taken from http://github.com/evanphx/terminalcolours/commit/20eb738a5c81349a3b0189ee7eb25de589abf987

#include "TotalTerminal.h"

@interface TotalTerminal (TerminalColours)

+(void)loadTerminalColours;

-(IBAction)orderFrontColourConfiguration:(id)sender;
-(IBAction)orderOutConfiguration:(id)sender;

@end
