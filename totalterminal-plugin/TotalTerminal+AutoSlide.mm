#import "TotalTerminal+AutoSlide.h"

#undef PROJECT
#define PROJECT AutoSlide

#define MAGIC_FLAG (1 << 4)

@implementation NSApplication (TotalTerminal)

-(void) SMETHOD (TTApplication, sendEvent):(NSEvent*)event {
    NSUInteger type = [event type];

    // when selecting Terminal icon via CMD+TAB or clicking on icon in the dock while Terminal.app is not active app
    bool activationEvent = type == NSAppKitDefined && [event subtype] == NSApplicationActivatedEventType;

    if (activationEvent) {
        NSLOG1(@"activationEvent %@", event);

        // magic flag is set only when doing CMD+TAB, but not during other types of activation as described in #50 and in https://github.com/binaryage/totalterminal/issues/48#issuecomment-8409132
        bool isCmdTabActivation = [event modifierFlags] & MAGIC_FLAG;
        if (isCmdTabActivation && [[TotalTerminal sharedInstance] window] && [[TotalTerminal sharedInstance] isHidden]) {
            BOOL doAutoSlide = YES;

            BOOL autoSlideAlways = ![[NSUserDefaults standardUserDefaults] boolForKey:@"TotalTerminalAutoSlideAlways"];
            if (!autoSlideAlways) {
                // perform auto slide only if Visor is the only Terminal window
                doAutoSlide = NO;
                NSArray* windows = [[NSClassFromString (@"TTApplication")sharedApplication] windows];
                int count = 0;
                for (id window in windows) {
                    if ([[window className] isEqualToString:@"TTWindow"]) {
                        count++;
                    }
                }
                if (count == 1 && [[TotalTerminal sharedInstance] status]) {
                    doAutoSlide = YES;
                }
            }
            
            if (doAutoSlide) {
                // auto-slide only when visor is the only terminal window
                NSLOG1(@"Showing visor because of \"auto slide\" activation");
                [[TotalTerminal sharedInstance] performSelector:@selector(showVisor:) withObject:nil afterDelay:0];
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
