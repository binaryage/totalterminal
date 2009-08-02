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
        [profileManager setProfile:visorProfile forName:@"Visor"];
    }
    TTApplication* app = [TTApplication sharedApplication];
    [app applyProfileToAllWindowControllers:visorProfile];
}

- (BOOL) canBecomeKeyWindow {
    // does anybody know better place where to call this?
    if (applyVisorProfileASAP) {
        applyVisorProfileASAP = FALSE;
        [self applyVisorProfile];
    }
    LOG(@"canBecomeKeyWindow");
    return YES;
}
- (BOOL) canBecomeMainWindow {
    LOG(@"canBecomeMainWindow");
    return YES;
}

@end