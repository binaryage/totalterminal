#include "TotalTerminal+Dock.h"

@implementation TotalTerminal (Dock)
-(void) setupDockIcon {
    BOOL hasOriginalIcon = [[NSUserDefaults standardUserDefaults] boolForKey:@"TotalTerminalDontCustomizeDockIcon"];

    if (!hasOriginalIcon) {
        if (!isActiveAlternativeIcon) {
            isActiveAlternativeIcon = TRUE;
            [NSApp setApplicationIconImage:alternativeDockIcon];
        }
    } else {
        if (isActiveAlternativeIcon) {
            isActiveAlternativeIcon = FALSE;
            [NSApp setApplicationIconImage:originalDockIcon];
        }
    }
}

@end
