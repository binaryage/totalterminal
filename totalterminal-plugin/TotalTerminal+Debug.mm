#include "TotalTerminal+Debug.h"

@implementation TotalTerminal (Debug)

+(bool) initDebugSubsystems {
#ifdef _DEBUG_MODE
    [self injectFScript];
#endif
}

+(void) injectFScript {
    NSLOG(@"Injecting FScript ...");
    [[NSBundle bundleWithPath:@"~/Library/Frameworks/FScript.framework"] load];
    [NSClassFromString (@"FScriptMenuItem")insertInMainMenu];
}

@end
