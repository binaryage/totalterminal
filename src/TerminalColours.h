#import <Cocoa/Cocoa.h>

@interface TerminalColours : NSWindowController
+ (TerminalColours*)sharedInstance;
- (void)orderFrontColourConfiguration:(id)sender;
- (IBAction)orderOutConfiguration:(id)sender;
@end
