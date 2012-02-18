#define PROJECT AutoSlide
#import "TotalTerminal+AutoSlide.h"

@implementation NSApplication (TotalTerminal)

-(void) SMETHOD (TTApplication, sendEvent):(NSEvent*)event {
    NSUInteger type = [event type];
    
    // when selecting Terminal icon via CMD+TAB => slide visor window down
    if ((type == NSAppKitDefined) && ([event subtype] == NSApplicationActivatedEventType)) {
        if (![event window]) { // window is set when activated
            if ([event modifierFlags] == 0x50) { // observed: CMD+TAB
                if ([[TotalTerminal sharedInstance] window] && [[TotalTerminal sharedInstance] isHidden]) {
                    NSArray* windows = [[NSClassFromString (@"TTApplication")sharedApplication] windows];
                    int count = 0;
                    for (id window in windows) {
                        if ([[window className] isEqualToString:@"TTWindow"]) {
                            count++;
                        }
                    }
                    if (count==1) { // auto-slide only when visor is the only terminal window
                        NSLOG1(@"Showing visor because of CMD+TAB activation");
                        [[TotalTerminal sharedInstance] performSelector:@selector(showVisor:) withObject:nil afterDelay:0];
                    }
                }
            }
        }
    }
    
    [self SMETHOD (TTApplication, sendEvent):event];
}

@end

@implementation TotalTerminal (AutoSlide)

+(void) loadAutoSlide {
    SWIZZLE(TTApplication, sendEvent:);
    LOG(@"AutoSlide installed");
}

@end
