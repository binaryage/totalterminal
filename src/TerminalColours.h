// taken from http://github.com/evanphx/terminalcolours/commit/20eb738a5c81349a3b0189ee7eb25de589abf987

#import <Cocoa/Cocoa.h>

@interface TerminalColours : NSWindowController
+ (TerminalColours*)sharedInstance;
- (void)orderFrontColourConfiguration:(id)sender;
- (IBAction)orderOutConfiguration:(id)sender;
@end
