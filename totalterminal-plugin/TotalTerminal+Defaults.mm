#include "TotalTerminal+Defaults.h"

#define CONVERT_KEY(from, to) \
    if ([ud objectForKey:from]) { \
        [ud setObject:[ud objectForKey:from] forKey:to]; \
        [ud removeObjectForKey:from]; \
    }

@implementation TotalTerminal (Defaults)

+(void) convertDefaultsFromPastVersions:(NSUserDefaults*)ud {
    AUTO_LOGGER();

    // conversion from TotalTerminal 1.0, Visor 2.2 (and prior) to new TotalTerminal-prefixed keys for 1.0.1 and later
    CONVERT_KEY(@"VisorShowStatusItem", @"TotalTerminalShowStatusItem");
    CONVERT_KEY(@"VisorShowOnReopen", @"TotalTerminalVisorShowOnReopen");
    CONVERT_KEY(@"VisorCopyOnSelect", @"TotalTerminalCopyOnSelect");
    CONVERT_KEY(@"VisorPasteOnRightclick", @"TotalTerminalPasteOnRightClick");
    CONVERT_KEY(@"VisorScreen", @"TotalTerminalVisorScreen");
    CONVERT_KEY(@"VisorOnEverySpace", @"TotalTerminalVisorOnEverySpace");
    CONVERT_KEY(@"VisorPosition", @"TotalTerminalVisorPosition");
    CONVERT_KEY(@"VisorHotKey", @"TotalTerminalVisorHotKey");
    CONVERT_KEY(@"VisorHotKeyEnabled", @"TotalTerminalVisorHotKeyEnabled");
    CONVERT_KEY(@"VisorHotKey2", @"TotalTerminalVisorHotKey2");
    CONVERT_KEY(@"VisorHotKey2Enabled", @"TotalTerminalVisorHotKey2Enabled");
    CONVERT_KEY(@"VisorUseFade", @"TotalTerminalVisorUseFade");
    CONVERT_KEY(@"VisorUseSlide", @"TotalTerminalVisorUseSlide");
    CONVERT_KEY(@"VisorAnimationSpeed", @"TotalTerminalVisorAnimationSpeed");
    CONVERT_KEY(@"VisorHideOnEscape", @"TotalTerminalVisorHideOnEscape");
    CONVERT_KEY(@"VisorUseBackgroundAnimation", @"TotalTerminalVisorUseBackgroundAnimation");
    CONVERT_KEY(@"VisorBackgroundAnimationOpacity", @"TotalTerminalVisorBackgroundAnimationOpacity");
    CONVERT_KEY(@"VisorBackgroundAnimationFile", @"TotalTerminalVisorBackgroundAnimationFile");
}

+(void) sanitizeDefaults:(NSUserDefaults*)ud {
    AUTO_LOGGER();
    [self convertDefaultsFromPastVersions:ud];

    if (![ud objectForKey:@"TotalTerminalShowStatusItem"]) {
        [ud setBool:YES forKey:@"TotalTerminalShowStatusItem"];
    }
    if (![ud objectForKey:@"TotalTerminalVisorShowOnReopen"]) {
        [ud setBool:YES forKey:@"TotalTerminalVisorShowOnReopen"];
    }
    if (![ud objectForKey:@"TotalTerminalCopyOnSelect"]) {
        [ud setBool:NO forKey:@"TotalTerminalCopyOnSelect"];
    }
    if (![ud objectForKey:@"TotalTerminalPasteOnRightClick"]) {
        [ud setBool:NO forKey:@"TotalTerminalPasteOnRightClick"];
    }
    if (![ud objectForKey:@"TotalTerminalVisorScreen"]) {
        [ud setInteger:0 forKey:@"TotalTerminalVisorScreen"]; // use screen 0 by default
    }
    if (![ud objectForKey:@"TotalTerminalVisorOnEverySpace"]) {
        [ud setBool:YES forKey:@"TotalTerminalVisorOnEverySpace"];
    }
    if (![ud objectForKey:@"TotalTerminalVisorPosition"]) {
        [ud setObject:@"Top-Stretch" forKey:@"TotalTerminalVisorPosition"];
    }
    // by default enable HotKey as Control+` (CTRL+tilde)
    if (![ud objectForKey:@"TotalTerminalShortcuts"]) {
        [ud setObject:[NSDictionary dictionaryWithObjectsAndKeys: \
                       makeKeyModifiersDictionary(50, NSControlKeyMask), @"ToggleVisor", \
                       makeKeyModifiersDictionary(35, NSCommandKeyMask | NSShiftKeyMask), @"PinVisor", \
                       nil]
               forKey:@"TotalTerminalShortcuts"];
    }
    // convert old visor HotKey structure if available
    if ([ud objectForKey:@"TotalTerminalHotKey"]) {
        NSDictionary* hotKey = [ud objectForKey:@"TotalTerminalHotKey"];
        BOOL enabled = [ud boolForKey:@"TotalTerminalHotKeyEnabled"];
        NSDictionary* shortcuts = [ud objectForKey:@"TotalTerminalShortcuts"];
        if (shortcuts) {
            NSMutableDictionary* ns = [NSMutableDictionary dictionaryWithDictionary:shortcuts];
            if (enabled) {
                NSNumber* code = [hotKey objectForKey:@"KeyCode"];
                NSNumber* modifiers = [hotKey objectForKey:@"Modifiers"];
                [ns setObject:makeKeyModifiersDictionary([code intValue], [modifiers unsignedIntValue]) forKey:@"ToggleVisor"];
            } else {
                [ns removeObjectForKey:@"ToggleVisor"];
            }
            [ud setObject:ns forKey:@"TotalTerminalShortcuts"];
            [ud removeObjectForKey:@"TotalTerminalHotKey"];
            [ud removeObjectForKey:@"TotalTerminalHotKeyEnabled"];
        }
    }

    // by default disable HotKey2 but set it to double Control
    if (![ud objectForKey:@"TotalTerminalVisorHotKey2"] || ![[ud objectForKey:@"TotalTerminalVisorHotKey2"] isKindOfClass:[NSDictionary class ]]) {
        [ud setObject:[NSDictionary dictionaryWithObjectsAndKeys: \
                       [NSNumber numberWithUnsignedInt:NSControlKeyMask], \
                       @"Modifiers", \
                       [NSNumber numberWithUnsignedInt:0], \
                       @"KeyCode", \
                       [NSNumber numberWithBool:YES], \
                       @"DoubleModifier", \
                       nil]
               forKey:@"TotalTerminalVisorHotKey2"];
    }
    if (![ud objectForKey:@"TotalTerminalVisorHotKey2Mask"]) {
        [ud setInteger:NSControlKeyMask forKey:@"TotalTerminalVisorHotKey2Mask"];
    }
    if (![ud objectForKey:@"TotalTerminalVisorHotKey2Enabled"]) {
        [ud setBool:NO forKey:@"TotalTerminalVisorHotKey2Enabled"];
    }
    if (![ud objectForKey:@"TotalTerminalVisorUseBackgroundAnimation"]) {
        [ud setBool:NO forKey:@"TotalTerminalVisorUseBackgroundAnimation"];
    }
    if (![ud objectForKey:@"TotalTerminalVisorBackgroundAnimationOpacity"]) {
        [ud setInteger:100 forKey:@"TotalTerminalVisorBackgroundAnimationOpacity"];
    }
    if (![ud objectForKey:@"TotalTerminalVisorHideOnEscape"]) {
        [ud setBool:NO forKey:@"TotalTerminalVisorHideOnEscape"];
    }
    if (![ud objectForKey:@"TotalTerminalVisorUseFade"]) {
        [ud setBool:YES forKey:@"TotalTerminalVisorUseFade"];
    }
    if (![ud objectForKey:@"TotalTerminalVisorUseSlide"]) {
        [ud setBool:YES forKey:@"TotalTerminalVisorUseSlide"];
    }
    if (![ud objectForKey:@"TotalTerminalVisorAnimationSpeed"]) {
        [ud setFloat:0.2f forKey:@"TotalTerminalVisorAnimationSpeed"];
    }
    if (![ud objectForKey:@"TotalTerminalDontCustomizeDockIcon"]) {
        [ud setBool:NO forKey:@"TotalTerminalDontCustomizeDockIcon"];
    }
    if (![ud objectForKey:@"TotalTerminalUsePreReleases"]) {
        [ud setBool:NO forKey:@"TotalTerminalUsePreReleases"];
    }
    if (![ud objectForKey:@"TotalTerminalDoNotLaunchCrashWatcher"]) {
        [ud setBool:NO forKey:@"TotalTerminalDoNotLaunchCrashWatcher"];
    }
    if (![ud objectForKey:@"TotalTerminalVisorPinned"]) {
        [ud setBool:NO forKey:@"TotalTerminalVisorPinned"];
    }
}

@end
