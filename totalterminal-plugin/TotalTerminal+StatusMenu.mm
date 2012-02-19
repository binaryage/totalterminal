#include "TotalTerminal+StatusMenu.h"

@implementation TotalTerminal (StatusMenu)

-(void) initStatusMenu {
    DCHECK(!statusItem_);

    AUTO_LOGGER();
    [self updateStatusMenu];
}

-(void) activateStatusMenu {
    AUTO_LOGGER();
    if (statusItem_) return;

    NSStatusBar* bar = [NSStatusBar systemStatusBar];
    statusItem_ = [bar statusItemWithLength:NSVariableStatusItemLength];
    [statusItem_ retain];

    [statusItem_ setHighlightMode:YES];
    [statusItem_ setTarget:self];

    [statusItem_ setMenu:statusMenu_];
    [self updateStatusMenu];
}

-(void) deactivateStatusMenu {
    AUTO_LOGGER();
    if (!statusItem_) return;

    [statusItem_ release];
    statusItem_ = nil;
}

-(void) updateStatusMenu {
    static bool firstTime = true;

    if (firstTime) {
        NSMenuItem* item;
        item = [[NSMenuItem alloc] initWithTitle:(@"Show Visor") action:@selector(toggleVisor:) keyEquivalent:@""];
        [item setTarget:self];
        [statusMenu_ addItem:item];
        [item release];
        [statusMenu_ addItem:[NSMenuItem separatorItem]];
        item = [[NSMenuItem alloc] initWithTitle:(@"TotalTerminal Preferences…") action:@selector(showPrefs:) keyEquivalent:@""];
        [item setTarget:self];
        [statusMenu_ addItem:item];
        [item release];
        [statusMenu_ addItem:[NSMenuItem separatorItem]];
        item = [[NSMenuItem alloc] initWithTitle:(@"Visit Homepage…") action:@selector(visitHomepage:) keyEquivalent:@""];
        [item setTarget:self];
        [statusMenu_ addItem:item];
        [item release];

        NSMenuItem* uninstallItem = [[NSMenuItem alloc] initWithTitle:(@"Uninstall TotalTerminal") action:@selector(uninstallMe:) keyEquivalent:@""];
        [uninstallItem setTarget:self];
        [statusMenu_ insertItem:uninstallItem atIndex:4];
        [uninstallItem release];
        NSMenuItem* updateItem = [[NSMenuItem alloc] initWithTitle:(@"Check for Updates") action:@selector(updateMe:) keyEquivalent:@""];
        [updateItem setTarget:self];
        [statusMenu_ insertItem:updateItem atIndex:4];
        [updateItem release];
        [statusMenu_ insertItem:[NSMenuItem separatorItem] atIndex:5];

#ifdef _DEBUG_MODE
        NSMenuItem* crashItem = [[NSMenuItem alloc] initWithTitle:@"Crash me!" action:@selector(crashMe:) keyEquivalent:@""];
        [crashItem setTarget:self];
        [statusMenu_ addItem:crashItem];
        [crashItem release];
        NSMenuItem* exitItem = [[NSMenuItem alloc] initWithTitle:@"Exit" action:@selector(exitMe:) keyEquivalent:@""];
        [exitItem setTarget:self];
        [statusMenu_ addItem:exitItem];
        [exitItem release];
#endif
    }

    // update first menu item
    if (statusItem_) {
        NSMenuItem* showItem = [statusMenu_ itemAtIndex:0];
        if (showItem) {
            BOOL status = [self status];
            if (status) {
                [statusItem_ setImage:activeIcon_];
                if (isHidden_) {
                    [showItem setTitle:(@"Show Visor")];
                } else {
                    [showItem setTitle:(@"Hide Visor")];
                }
            } else {
                [statusItem_ setImage:inactiveIcon_];
                [showItem setTitle:(@"Open Visor")];
            }
        }
    }

    firstTime = false;
}

-(BOOL) validateMenuItem:(NSMenuItem*)menuItem {
    AUTO_LOGGERF(@"menuItem=%@", menuItem);
    [self updateStatusMenu];
    if ([menuItem action] == @selector(toggleVisor:)) {
        return YES;
    }
    if ([menuItem action] == @selector(visitHomepage:)) {
        return YES;
    }
    if ([menuItem action] == @selector(restartMe:)) {
        return YES;
    }
    if ([menuItem action] == @selector(uninstallMe:)) {
        return YES;
    }
    if ([menuItem action] == @selector(updateMe:)) {
        return YES;
    }
    if ([menuItem action] == @selector(togglePinVisor:)) {
        return !!window_;
    }
#ifdef _DEBUG_MODE
    if ([menuItem action] == @selector(crashMe:)) {
        return YES;
    }
    if ([menuItem action] == @selector(exitMe:)) {
        return YES;
    }
#endif
    return YES;
}

@end
