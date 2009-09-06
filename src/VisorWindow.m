#import "Macros.h"
#import "VisorWindow.h"
#import "Visor.h"
#import "VisorWindowController.h"
#import "VisorApplication.h"

@implementation TTWindow (Visor)

- (id) initWithContentRect: (NSRect) contentRect
                 styleMask: (unsigned int) aStyle
                   backing: (NSBackingStoreType) bufferingType
                     defer: (BOOL) flag 
{
    LOG(@"Creating a new terminal window");
    Visor* visor = [Visor sharedInstance];
    BOOL shouldBeVisorized = ![visor status];
    if (shouldBeVisorized) {
        aStyle =  NSBorderlessWindowMask;
        bufferingType = NSBackingStoreBuffered;
    }
    self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag];
    if (shouldBeVisorized) {
        [visor adoptTerminal:self];
        applyVisorProfileASAP = TRUE; // cannot call applyVisorProfile, window is not ready for profile setup
    }
    return self;
}

- (void) applyVisorProfile {
    LOG(@"applyVisorProfile");
    TTProfileManager* profileManager = [TTProfileManager sharedProfileManager];
    TTProfile* visorProfile = [profileManager profileWithName:@"Visor"];
    if (!visorProfile) {
        LOG(@"   ... initialising Visor profile");
        
        // create visor profile in case it does not exist yet, use startup profile as a template
        TTProfile* startupProfile = [profileManager startupProfile];
        visorProfile = [startupProfile copyWithZone:nil];

        // apply Darwin's preferred Visor settings
        Visor* visor = [Visor sharedInstance];
        NSData *plistData;
        NSString *error;
        NSPropertyListFormat format;
        id plist;
        NSString *path = [[NSBundle bundleForClass:[visor class]] pathForResource:@"VisorProfile" ofType:@"plist"]; 
        plistData = [NSData dataWithContentsOfFile:path]; 
        plist = [NSPropertyListSerialization propertyListFromData:plistData mutabilityOption:NSPropertyListImmutable format:&format errorDescription:&error];
        if (!plist) {
            LOG(@"Error reading plist from file '%s', error = '%s'", [path UTF8String], [error UTF8String]);
            [error release];
        }
        [visorProfile setPropertyListRepresentation:plist];

        // set profile into manager
        [profileManager setProfile:visorProfile forName:@"Visor"];
    }

    // apply visor profile to the opening window
    [[self windowController] applyProfileToAllShellsInWindow:visorProfile];

// this code serializes current Visor profile (should have same effect like going to Terminal.app preferences and doing profile Export ...) 
#ifdef _DEBUG_MODE
    // NSMutableDictionary* plist = [visorProfile propertyListRepresentation];
    // NSData *xmlData;
    // NSString *error; 
    // NSString *path = @"/Users/darwin/temp/visor.plist";
    // xmlData = [NSPropertyListSerialization dataFromPropertyList:plist format:NSPropertyListXMLFormat_v1_0 errorDescription:&error];
    // if (xmlData) {
    //     [xmlData writeToFile:path atomically:YES];
    // } else {
    //     NSBeep();
    //     NSLog(@"Error writing plist to file '%s', error = '%s'", [path UTF8String], [error UTF8String]);
    //     [error release];
    // }
#endif
}

- (BOOL) canBecomeKeyWindow {
    // does anybody know better place where to call this?
    if (applyVisorProfileASAP) {
        applyVisorProfileASAP = FALSE;
        [self applyVisorProfile];
        Visor* visor = [Visor sharedInstance];
        [visor moveWindowOffScreen];
    }
    LOG(@"canBecomeKeyWindow");
    return YES;
}
- (BOOL) canBecomeMainWindow {
    LOG(@"canBecomeMainWindow");
    return YES;
}

@end