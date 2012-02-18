#include "Versions.h"

static TSupportedTerminalVersions terminalImageVersion = vUnknown;

TSupportedTerminalVersions initializeTerminalVersion() {
    NSBundle* mainBundle = [NSBundle mainBundle];
    id terminalVersion = [mainBundle objectForInfoDictionaryKey:@"CFBundleVersion"];
    
    if (!terminalVersion || ![terminalVersion isKindOfClass:[NSString class]]) {
        return vUnknown;
    }

    // TODO: here should be more intelligent parsing code
    TSupportedTerminalVersions version = vUnknown;
    if ([terminalVersion isEqualToString:@"273.1"]) {
        version = v273_1;
    } else if ([terminalVersion isEqualToString:@"297"]) {
        version = v297;
    } else if ([terminalVersion isEqualToString:@"299"]) {
        version = v299;
    } else if ([terminalVersion isEqualToString:@"303"]) {
        version = v303;
    } else if ([terminalVersion isEqualToString:@"304"]) {
        version = v304;
    }
    if (version == vUnknown) {
        // try to parse it and detect historical version
        int parsedVersion = [terminalVersion intValue];
        if ((parsedVersion > 0) && (parsedVersion < 273)) {
            version = vHistorical;
        } else {
            NSLog(@"Warning: Terminal has unknown version %@. Visor has not been tested with this Terminal version.", terminalVersion);
        }
    }
    return version;
}

TSupportedTerminalVersions terminalVersion() {
    static bool terminalImageVersionDetected = false;

    if (!terminalImageVersionDetected) {
        terminalImageVersionDetected = true;
        terminalImageVersion = initializeTerminalVersion();
    }
    return terminalImageVersion;
}

