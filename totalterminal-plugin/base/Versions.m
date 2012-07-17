#import "Versions.h"

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
    } else if ([terminalVersion isEqualToString:@"303.1"]) {
        version = v303dot1;
    } else if ([terminalVersion isEqualToString:@"303.2"]) {
        version = v303dot2;
    } else if ([terminalVersion isEqualToString:@"304"]) {
        version = v304;
    } else if ([terminalVersion isEqualToString:@"305"]) {
        version = v305;
    } else if ([terminalVersion isEqualToString:@"306"]) {
        version = v306;
    } else if ([terminalVersion isEqualToString:@"307"]) {
        version = v307;
    } else if ([terminalVersion isEqualToString:@"308"]) {
        version = v308;
    } else if ([terminalVersion isEqualToString:@"309"]) {
        version = v309;
    }
    if (version == vUnknown) {
        // try to parse it and detect historical version
        int parsedVersion = [terminalVersion intValue];
        if ((parsedVersion > 0) && (parsedVersion < 273)) {
            version = vHistorical;
        } else {
            NSLog(@"Warning: Terminal has unknown version %@. TotalTerminal has not been tested with this Terminal version.", terminalVersion);
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
