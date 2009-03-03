#import <Cocoa/Cocoa.h>

@interface TTWindowController : NSWindowController {
}
- (NSRect)window:(NSWindow *)window willPositionSheet:(NSWindow *)sheet usingRect:(NSRect)rect;
- (void)setCloseDialogExpected:(BOOL)fp8;
@end