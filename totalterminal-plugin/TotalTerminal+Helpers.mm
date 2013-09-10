#import <terminal/TTProfileManager.h>

#import "TotalTerminal+Helpers.h"

@implementation TotalTerminal (Helpers)

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

-(bool) isCurrentylyActive {
  NSRunningApplication* app = [NSRunningApplication currentApplication];

  return [app isActive];
}

-(void) storePreviouslyActiveApp {
  AUTO_LOGGERF(@"front-most=%@", [[NSWorkspace sharedWorkspace] frontmostApplication]);

  // TODO: use frontmostApplication in 10.7+
  NSDictionary* activeAppDict = [[NSWorkspace sharedWorkspace] activeApplication];
  _previouslyActiveAppPID = 0;
  NSString* bundleIdentifier = [activeAppDict objectForKey:@"NSApplicationBundleIdentifier"];
  if ([bundleIdentifier compare:@"com.apple.Terminal"]) {
    _previouslyActiveAppPID = [[activeAppDict objectForKey:@"NSApplicationProcessIdentifier"] intValue];
  }
  NSLOG(@"  remember previous app pid=%d", _previouslyActiveAppPID);
}

// this function is called periodically during open Visor session ([TotalTermina isHidden] is false)
// imagine you have pinned visor and switched temporarily to some other app and returned back
// the goal here is to track last such app and return focus to it after closing visor session
// originally visor would return focus to active app immediatelly prior visor opening
-(void) updatePreviouslyActiveApp {
  // TODO: use frontmostApplication in 10.7+
  NSDictionary* activeAppDict = [[NSWorkspace sharedWorkspace] activeApplication];
  NSString* bundleIdentifier = [activeAppDict objectForKey:@"NSApplicationBundleIdentifier"];

  if ([bundleIdentifier compare:@"com.apple.Terminal"]) {
    int newPID = [[activeAppDict objectForKey:@"NSApplicationProcessIdentifier"] intValue];
    if (newPID != _previouslyActiveAppPID) {
      _previouslyActiveAppPID = newPID;
      NSLOG(@"  new previous app pid=%d", _previouslyActiveAppPID);
    }
  } else {
    if (_window && !_isKey) {
      // some other terminal window has key focus => reset
      int newPID = 0;
      if (newPID != _previouslyActiveAppPID) {
        _previouslyActiveAppPID = newPID;
        NSLOG(@"  reset previous app pid=%d", _previouslyActiveAppPID);
      }
    }
  }
}

-(void) restorePreviouslyActiveApp {
  AUTO_LOGGERF(@"pid=%d", _previouslyActiveAppPID);
  if (!_previouslyActiveAppPID) {
    // no previous app recorded
    return;
  }

  id app = [NSRunningApplication runningApplicationWithProcessIdentifier:_previouslyActiveAppPID];
  LOG(@"  ... activating %@", app);
  [app activateWithOptions:0];
  _previouslyActiveAppPID = 0;
}

@end
