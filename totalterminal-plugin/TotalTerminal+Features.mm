#import "TotalTerminal+Features.h"

@implementation TotalTerminal (Features)

+(BOOL) shouldLoadFeature:(NSString*)feature {
    BOOL enabled = ![[NSUserDefaults standardUserDefaults] boolForKey:[@"TotalTerminalDisable" stringByAppendingString:feature]];

    return enabled;
}

+(void) loadFeatures {
    // load individual features
    if ([self shouldLoadFeature:@"PasteOnRightClick"]) {
        [self loadPasteOnRightClick];
    }
    if ([self shouldLoadFeature:@"CopyOnSelect"]) {
        [self loadCopyOnSelect];
    }
    // TerminalColours is not needed anymore under Lion, Apple has implemented 256 color support
    if ((terminalVersion() < FIRST_LION_VERSION) && [self shouldLoadFeature:@"TerminalColours"]) {
        [self loadTerminalColours];
    }
    if ([self shouldLoadFeature:@"Visor"]) {
        [self loadVisor];
    }
    if ([self shouldLoadFeature:@"AutoSlide"]) {
        [self loadAutoSlide];
    }
}

@end
