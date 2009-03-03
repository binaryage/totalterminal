#import "Visor.h"
#import "VisorWindowController.h"

@implementation TTWindowController (Visor)

- (void)setCloseDialogExpected:(BOOL)fp8 {
    if (fp8) {
        // THIS IS MEGAHACK! (works for me on Leopard 10.5.6)
        // the problem: beginSheet causes UI to lock for NSBorderlessWindowMask NSWindow which is in "closing mode"
        //
        // this hack tries to open sheet before window starts it's closing procedure
        // we expect that setCloseDialogExpected is called by Terminal.app once BEFORE window gets into "closing mode"
        // in this case we are able to open sheet before window starts closing and this works even for window with NSBorderlessWindowMask
        // it works like a magic, took me few hours to figure out this random stuff
        Visor* visor = [Visor sharedInstance];
        [visor showVisor:false];
        [self displayWindowCloseSheet:1];
    }
}

- (NSRect)window:(NSWindow *)window willPositionSheet:(NSWindow *)sheet usingRect:(NSRect)rect {
    NSLog(@"willPositionSheet");
    Visor* visor = [Visor sharedInstance];
    [visor setupExposeTags:sheet];
    return rect;
}

@end