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
    LOG(@"  remember pid=%d", previouslyActiveAppPID_);
}

-(void) restorePreviouslyActiveApp {
    AUTO_LOGGERF(@"pid=%d", previouslyActiveAppPID_);
    if (!previouslyActiveAppPID_) return;
    id app = [NSRunningApplication runningApplicationWithProcessIdentifier:previouslyActiveAppPID_];
    LOG(@"  ... activating %@", app);
    [app activateWithOptions:0];
    previouslyActiveAppPID_ = 0;
}

+(void) closeExistingWindows {
    AUTO_LOGGER();
    id wins = [[NSClassFromString (@"TTApplication")sharedApplication] windows];
    for (id win in wins) {
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
