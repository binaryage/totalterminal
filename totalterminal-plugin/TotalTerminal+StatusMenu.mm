#include "TotalTerminal+StatusMenu.h"

@implementation TotalTerminal (StatusMenu)

-(void) initStatusMenu {
    DCHECK(!statusItem);

    AUTO_LOGGER();
    [self updateStatusMenu];
}

-(void) activateStatusMenu {
    AUTO_LOGGER();
    if (statusItem) return;

    NSStatusBar* bar = [NSStatusBar systemStatusBar];
    statusItem = [bar statusItemWithLength:NSVariableStatusItemLength];
    [statusItem retain];

    [statusItem setHighlightMode:YES];
    [statusItem setTarget:self];
    [statusItem setAction:@selector(toggleVisor:)];
    [statusItem setDoubleAction:@selector(toggleVisor:)];

    [statusItem setMenu:statusMenu];
    [self updateStatusMenu];
}

-(void) deactivateStatusMenu {
    AUTO_LOGGER();
    if (!statusItem) return;
    [statusItem release];
    statusItem = nil;
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

-(void) updateStatusMenu {
    static bool firstTime = true;

    if (firstTime) {
        NSMenuItem* item;
        item = [[NSMenuItem alloc] initWithTitle:(@"Show Visor") action:@selector(toggleVisor:) keyEquivalent:@""];
        [item setTarget:self];
        [statusMenu addItem:item];
        [statusMenu addItem:[NSMenuItem separatorItem]];
        item = [[NSMenuItem alloc] initWithTitle:(@"TotalTerminal Preferences…") action:@selector(showPrefs:) keyEquivalent:@""];
        [item setTarget:self];
        [statusMenu addItem:item];
        [statusMenu addItem:[NSMenuItem separatorItem]];
        item = [[NSMenuItem alloc] initWithTitle:(@"Visit Homepage…") action:@selector(visitHomepage:) keyEquivalent:@""];
        [item setTarget:self];
        [statusMenu addItem:item];

        NSMenuItem* uninstallItem = [[NSMenuItem alloc] initWithTitle:(@"Uninstall TotalTerminal") action:@selector(uninstallMe:) keyEquivalent:@""];
        [uninstallItem setTarget:self];
        [statusMenu insertItem:uninstallItem atIndex:4];
        NSMenuItem* updateItem = [[NSMenuItem alloc] initWithTitle:(@"Check for Updates") action:@selector(updateMe:) keyEquivalent:@""];
        [updateItem setTarget:self];
        [statusMenu insertItem:updateItem atIndex:4];
        [statusMenu insertItem:[NSMenuItem separatorItem] atIndex:5];

#ifdef _DEBUG_MODE
        NSMenuItem* crashItem = [[NSMenuItem alloc] initWithTitle:@"Crash me!" action:@selector(crashMe:) keyEquivalent:@""];
        [crashItem setTarget:self];
        [statusMenu addItem:crashItem];
        NSMenuItem* exitItem = [[NSMenuItem alloc] initWithTitle:@"Exit" action:@selector(exitMe:) keyEquivalent:@""];
        [exitItem setTarget:self];
        [statusMenu addItem:exitItem];
#endif
    }

    // update first menu item
    NSMenuItem* showItem = [statusMenu itemAtIndex:0];
    BOOL status = [self status];
    if (status) {
        [statusItem setImage:activeIcon];
        if (isHidden) {
            [showItem setTitle:(@"Show Visor")];
        } else {
            [showItem setTitle:(@"Hide Visor")];
        }
    } else {
        [statusItem setImage:inactiveIcon];
        [showItem setTitle:(@"Open Visor")];
    }

    firstTime = false;
}

@end
