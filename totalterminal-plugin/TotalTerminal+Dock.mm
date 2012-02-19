#include "TotalTerminal+Dock.h"

@implementation TotalTerminal (Dock)
-(void) setupDockIcon {
    BOOL hasOriginalIcon = [[NSUserDefaults standardUserDefaults] boolForKey:@"TotalTerminalDontCustomizeDockIcon"];

    if (!hasOriginalIcon) {
        if (!isActiveAlternativeIcon_) {
            isActiveAlternativeIcon_ = TRUE;
            [NSApp setApplicationIconImage:alternativeDockIcon];
        }
    } else {
        if (isActiveAlternativeIcon_) {
            isActiveAlternativeIcon_ = FALSE;
            [NSApp setApplicationIconImage:originalDockIcon];
        }
    }
}

@end
