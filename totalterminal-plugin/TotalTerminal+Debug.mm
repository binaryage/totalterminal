#import "TotalTerminal+Debug.h"

@interface NSObject ()
+(void) insertInMainMenu;
@end

@implementation TotalTerminal (Debug)

+(bool) initDebugSubsystems {
#if defined(DEBUG)
    [self injectFScript];
#endif
}

+(void) injectFScript {
    NSLOG(@"Injecting FScript ...");
    [[NSBundle bundleWithPath:@"~/Library/Frameworks/FScript.framework"] load];
    [NSClassFromString (@"FScriptMenuItem")insertInMainMenu];
}

@end
