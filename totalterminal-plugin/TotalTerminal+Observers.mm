#include "TotalTerminal+Observers.h"

@implementation TotalTerminal (Observers)

+(BOOL) automaticallyNotifiesObserversForKey:(NSString*)theKey {
    if ([theKey isEqualToString:@"shouldShowTransparencyAlert"]) return NO;

    return [super automaticallyNotifiesObserversForKey:theKey];
}

-(void) registerObservers {
    NSUserDefaultsController* udc = [NSUserDefaultsController sharedUserDefaultsController];

    [udc addObserver:self forKeyPath:@"values.TotalTerminalShowStatusItem" options:0 context:nil];
    [udc addObserver:self forKeyPath:@"values.TotalTerminalVisorHotKey" options:0 context:nil];
    [udc addObserver:self forKeyPath:@"values.TotalTerminalVisorHotKeyEnabled" options:0 context:nil];
    [udc addObserver:self forKeyPath:@"values.TotalTerminalVisorHotKey2" options:0 context:nil];
    [udc addObserver:self forKeyPath:@"values.TotalTerminalVisorHotKey2Enabled" options:0 context:nil];
    [udc addObserver:self forKeyPath:@"values.TotalTerminalVisorHotKey2Mask" options:0 context:nil];
    [udc addObserver:self forKeyPath:@"values.TotalTerminalVisorOnEverySpace" options:0 context:nil];
    [udc addObserver:self forKeyPath:@"values.TotalTerminalVisorUseFade" options:0 context:nil];
    [udc addObserver:self forKeyPath:@"values.TotalTerminalVisorUseSlide" options:0 context:nil];
    [udc addObserver:self forKeyPath:@"values.TotalTerminalVisorAnimationSpeed" options:0 context:nil];
    [udc addObserver:self forKeyPath:@"values.TotalTerminalVisorScreen" options:0 context:nil];
    [udc addObserver:self forKeyPath:@"values.TotalTerminalVisorPosition" options:0 context:nil];
    [udc addObserver:self forKeyPath:@"values.TotalTerminalVisorHideOnEscape" options:0 context:nil];
    [udc addObserver:self forKeyPath:@"values.TotalTerminalVisorUseBackgroundAnimation" options:0 context:nil];
    [udc addObserver:self forKeyPath:@"values.TotalTerminalVisorBackgroundAnimationOpacity" options:0 context:nil];
    [udc addObserver:self forKeyPath:@"values.TotalTerminalDontCustomizeDockIcon" options:0 context:nil];
    [udc addObserver:self forKeyPath:@"values.TotalTerminalShortcuts" options:0 context:nil];
    [udc addObserver:self forKeyPath:@"values.TotalTerminalUsePreReleases" options:0 context:nil];
    [udc addObserver:self forKeyPath:@"values.TotalTerminalVisorPinned" options:0 context:nil];
    [udc addObserver:self forKeyPath:@"values.TotalTerminalVisorFullScreen" options:0 context:nil];
    [udc addObserver:self forKeyPath:@"values.TotalTerminalVisorWindowOnHighLevel" options:0 context:nil];

    // ----------
    [[[self class] getVisorProfile] addObserver:self forKeyPath:@"BackgroundColor" options:0 context:@"UpdateBackground"];
}

-(void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    AUTO_LOGGERF(@"keyPath=%@", keyPath);

    if ([keyPath isEqualToString:@"values.TotalTerminalShowStatusItem"]) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"TotalTerminalShowStatusItem"]) {
            [self activateStatusMenu];
        } else {
            [self deactivateStatusMenu];
        }
    } else {
        [self updateHotKeyRegistration];
    }
    if ([keyPath isEqualToString:@"values.TotalTerminalVisorPosition"]) {
        [self resetWindowPlacement];
    }
    if ([keyPath isEqualToString:@"values.TotalTerminalVisorScreen"]) {
        [self resetWindowPlacement];
    }
    if ([keyPath isEqualToString:@"values.TotalTerminalVisorOnEverySpace"]) {
        [self updateVisorWindowSpacesSettings];
        [self resetWindowPlacement];
    }
    if ([keyPath isEqualToString:@"values.TotalTerminalVisorHideOnEscape"]) {
        [self updateEscapeHotKeyRegistration];
    }
    if ([keyPath isEqualToString:@"values.TotalTerminalVisorUseBackgroundAnimation"]) {
        [self initializeBackground];
        [self updateShouldShowTransparencyAlert];
    }
    if ([keyPath isEqualToString:@"values.TotalTerminalVisorBackgroundAnimationOpacity"]) {
        [self updateAnimationAlpha];
    }
    if ([keyPath isEqualToString:@"values.TotalTerminalDontCustomizeDockIcon"]) {
        [self setupDockIcon];
    }
    if ([keyPath isEqualToString:@"values.TotalTerminalVisorFullScreen"]) {
        [self resetWindowPlacement];
    }
    if ([keyPath isEqualToString:@"values.TotalTerminalUsePreReleases"]) {
        [self refreshFeedURLInUpdater];
    }
    if ([keyPath isEqualToString:@"values.TotalTerminalShortcuts"]) {
        [self updateCachedShortcuts];
    }
    if ([keyPath isEqualToString:@"values.TotalTerminalVisorHotKey2Mask"]) {
        [self updatePreferencesUI];
    }
    if ([keyPath isEqualToString:@"values.TotalTerminalVisorWindowOnHighLevel"]) {
        [self updateVisorWindowLevel];
    }
    if ([keyPath isEqualToString:@"BackgroundColor"] &&
        (context != nil) &&
        [context isEqualToString:@"UpdateBackground"]) {
        [self initializeBackground];
        [self updateShouldShowTransparencyAlert];
    }

    [self updateMainMenuState];
    [self updateStatusMenu];
    [self updateHotKeyRegistration];
}

@end
