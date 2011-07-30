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
    if (runningOnLeopard_) {
        // 10.5 path
        NSDictionary* activeAppDict = [[NSWorkspace sharedWorkspace] activeApplication];
        previouslyActiveAppPath = nil;
        NSString* bundleIdentifier = [activeAppDict objectForKey:@"NSApplicationBundleIdentifier"];
        if ([bundleIdentifier compare:@"com.apple.Terminal"]) {
            previouslyActiveAppPath = [activeAppDict objectForKey:@"NSApplicationPath"];
        }
        LOG(@"  (10.5) -> %@", previouslyActiveAppPath);
    } else {
        // 10.6+ path
        NSDictionary* activeAppDict = [[NSWorkspace sharedWorkspace] activeApplication];
        previouslyActiveAppPID = nil;
        NSString* bundleIdentifier = [activeAppDict objectForKey:@"NSApplicationBundleIdentifier"];
        if ([bundleIdentifier compare:@"com.apple.Terminal"]) {
            previouslyActiveAppPID = [activeAppDict objectForKey:@"NSApplicationProcessIdentifier"];
        }
        LOG(@"  (10.6) -> %@", previouslyActiveAppPID);
    }
}

-(void) restorePreviouslyActiveApp {
    if (runningOnLeopard_) {
        if (!previouslyActiveAppPath) return;
        LOG(@"restorePreviouslyActiveApp %@", previouslyActiveAppPath);
        // 10.5 path
        // Visor crashes when trying to return focus to non-running application? (http://github.com/darwin/visor/issues#issue/12)
        NSString* scriptSource = [[NSString alloc] initWithFormat:restoreAppAppleScriptSource, previouslyActiveAppPath];
        NSAppleScript* appleScript = [[NSAppleScript alloc] initWithSource:scriptSource];
        [appleScript executeAndReturnError:&scriptError];
        [appleScript release];
        [scriptSource release];
        previouslyActiveAppPath = nil;
    } else {
        // 10.6+ path
        if (!previouslyActiveAppPID) return;
        LOG(@"restorePreviouslyActiveApp %@", previouslyActiveAppPID);
        id app = [runningApplicationClass_ runningApplicationWithProcessIdentifier:[previouslyActiveAppPID intValue]];
        if (app) {
            LOG(@"  ... activating %@", app);
            [app activateWithOptions:0];
        }
        previouslyActiveAppPID = nil;
    }
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