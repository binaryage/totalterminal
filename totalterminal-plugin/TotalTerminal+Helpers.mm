#include "TotalTerminal+Helpers.h"

@implementation TotalTerminal (Helpers)

-(bool) isCurrentylyActive {
    NSRunningApplication* app = [NSRunningApplication currentApplication];
    return [app isActive];
}

-(void) storePreviouslyActiveApp {
    AUTO_LOGGER();
    NSDictionary* activeAppDict = [[NSWorkspace sharedWorkspace] activeApplication];
    previouslyActiveAppPID_ = 0;
    NSString* bundleIdentifier = [activeAppDict objectForKey:@"NSApplicationBundleIdentifier"];
    if ([bundleIdentifier compare:@"com.apple.Terminal"]) {
        previouslyActiveAppPID_ = [[activeAppDict objectForKey:@"NSApplicationProcessIdentifier"] intValue];
    }
    LOG(@"  -> pid=%d", previouslyActiveAppPID_);
}

-(void) restorePreviouslyActiveApp {
    AUTO_LOGGER();
    if (!previouslyActiveAppPID_) return;
    LOG(@"restorePreviouslyActiveApp %d", previouslyActiveAppPID_);
    id app = [NSRunningApplication runningApplicationWithProcessIdentifier:previouslyActiveAppPID_];
    LOG(@"  ... activating %@", app);
    [app activateWithOptions:0];
    previouslyActiveAppPID_ = 0;
}

+(void) closeExistingWindows {
    id wins = [[NSClassFromString (@"TTApplication")sharedApplication] windows];
    int winCount = [wins count];
    int i;

    for (i = 0; i < winCount; i++) {
        id win = [wins objectAtIndex:i];
        if (!win) continue;
        if ([[win className] isEqualToString:@"TTWindow"]) {
            @try {
                [win close];
            } @catch (NSException* exception) {
                ERROR(@"closeExistingWindows: Caught %@: %@", [exception name], [exception reason]);
            }
        }
    }
}

+(BOOL) hasVisorProfile {
    id profileManager = [NSClassFromString (@"TTProfileManager")sharedProfileManager];
    id visorProfile = [profileManager profileWithName:@"Visor"];

    return !!visorProfile;
}

+(id) getVisorProfile {
    id profileManager = [NSClassFromString (@"TTProfileManager")sharedProfileManager];
    id visorProfile = [profileManager profileWithName:@"Visor"];

    if (visorProfile) {
        return visorProfile;
    }
    return [profileManager defaultProfile];
}

@end
