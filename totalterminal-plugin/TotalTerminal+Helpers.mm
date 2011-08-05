#include "TotalTerminal+Helpers.h"

@implementation TotalTerminal (Helpers)

-(bool) isCurrentylyActive {
    NSRunningApplication* app = [NSRunningApplication currentApplication];

    DCHECK(app);
    if (!app) return false;
    return [app isActive];
}

-(void) storePreviouslyActiveApp {
    LOG(@"storePreviouslyActiveApp");
    NSDictionary* activeAppDict = [[NSWorkspace sharedWorkspace] activeApplication];
    previouslyActiveAppPID = nil;
    NSString* bundleIdentifier = [activeAppDict objectForKey:@"NSApplicationBundleIdentifier"];
    if ([bundleIdentifier compare:@"com.apple.Terminal"]) {
        previouslyActiveAppPID = [activeAppDict objectForKey:@"NSApplicationProcessIdentifier"];
    }
    LOG(@"  (10.6) -> %@", previouslyActiveAppPID);
}

-(void) restorePreviouslyActiveApp {
    if (!previouslyActiveAppPID) return;
    LOG(@"restorePreviouslyActiveApp %@", previouslyActiveAppPID);
    id app = [NSRunningApplication runningApplicationWithProcessIdentifier:[previouslyActiveAppPID intValue]];
    if (app) {
        LOG(@"  ... activating %@", app);
        [app activateWithOptions:0];
    }
    previouslyActiveAppPID = nil;
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
