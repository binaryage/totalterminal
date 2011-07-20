#import <dlfcn.h>
#import <mach-o/dyld.h>

#include "Versions.h"

static TSupportedTerminalVersions terminalImageVersion = vUnknown;

TSupportedTerminalVersions initializeTerminalVersion() {
    Dl_info dlinfo;

    void* x = NSClassFromString(@"TTApplication"); // this should be some class we believe exists in all versions, ideally NSPrincipalClass

    if ((dladdr(x, &dlinfo) == 0) || (dlinfo.dli_fbase == NULL)) {
        NSLog(@"Cannot find Terminal's image base address (very odd)");
        return vUnknown;
    }

    NSString* terminalInfoPlistPath = [[NSString stringWithCString:dlinfo.dli_fname encoding:NSASCIIStringEncoding] stringByStandardizingPath];
    terminalInfoPlistPath = [[[terminalInfoPlistPath stringByDeletingLastPathComponent] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"Info.plist"];
    NSDictionary* terminalInfoPlist = [NSDictionary dictionaryWithContentsOfFile:terminalInfoPlistPath];
    if (!terminalInfoPlist) {
        NSLog(@"Cannot load Terminal's Info.plist: %@", terminalInfoPlistPath);
        return vUnknown;
    }
    NSString* terminalVersion = [terminalInfoPlist objectForKey:@"CFBundleVersion"];
    if (!terminalVersion) {
        return vUnknown;
    }

    TSupportedTerminalVersions version = vUnknown;
    if ([terminalVersion isEqualToString:@"273.1"]) { // 10.6.8
        version = v273_1;
    } else if ([terminalVersion isEqualToString:@"297"]) { // 10.7 (GM)
        version = v297;
    }
    if (version == vUnknown) {
        // try to parse it and detect historical version
        int parsedVersion = [terminalVersion intValue];
        if (parsedVersion>0 && parsedVersion<273) {
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