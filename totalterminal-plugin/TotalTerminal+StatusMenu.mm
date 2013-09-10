#import "TotalTerminal+StatusMenu.h"

@implementation TotalTerminal (StatusMenu)

-(void) initStatusMenu {
  DCHECK(!_statusItem);

  AUTO_LOGGER();
  [self updateStatusMenu];
}

-(void) activateStatusMenu {
  AUTO_LOGGER();
  if (_statusItem) return;

  NSStatusBar* bar = [NSStatusBar systemStatusBar];
  _statusItem = [bar statusItemWithLength:NSVariableStatusItemLength];

  [_statusItem setHighlightMode:YES];
  [_statusItem setTarget:self];

  [_statusItem setMenu:_statusMenu];
  [self updateStatusMenu];
}

-(void) deactivateStatusMenu {
  AUTO_LOGGER();
  if (!_statusItem) return;

  _statusItem = nil;
}

-(void) updateStatusMenu {
  static bool firstTime = true;

  if (firstTime) {
    NSMenuItem* item;
    item = [[NSMenuItem alloc] initWithTitle:(@"Show Visor") action:@selector(toggleVisor:) keyEquivalent:@""];
    [item setTarget:self];
    [_statusMenu addItem:item];
    [_statusMenu addItem:[NSMenuItem separatorItem]];
    item = [[NSMenuItem alloc] initWithTitle:(@"TotalTerminal Preferences…") action:@selector(showPrefs:) keyEquivalent:@""];
    [item setTarget:self];
    [_statusMenu addItem:item];
    [_statusMenu addItem:[NSMenuItem separatorItem]];
    item = [[NSMenuItem alloc] initWithTitle:(@"Visit Homepage…") action:@selector(visitHomepage:) keyEquivalent:@""];
    [item setTarget:self];
    [_statusMenu addItem:item];

    NSMenuItem* uninstallItem = [[NSMenuItem alloc] initWithTitle:(@"Uninstall TotalTerminal") action:@selector(uninstallMe:) keyEquivalent:@""];
    [uninstallItem setTarget:self];
    [_statusMenu insertItem:uninstallItem atIndex:4];
    NSMenuItem* updateItem = [[NSMenuItem alloc] initWithTitle:(@"Check for Updates") action:@selector(updateMe:) keyEquivalent:@""];
    [updateItem setTarget:self];
    [_statusMenu insertItem:updateItem atIndex:4];
    [_statusMenu insertItem:[NSMenuItem separatorItem] atIndex:5];

#if defined(DEBUG)
    NSMenuItem* crashItem = [[NSMenuItem alloc] initWithTitle:@"Crash me!" action:@selector(crashMe:) keyEquivalent:@""];
    [crashItem setTarget:self];
    [_statusMenu addItem:crashItem];
    NSMenuItem* exitItem = [[NSMenuItem alloc] initWithTitle:@"Exit" action:@selector(exitMe:) keyEquivalent:@""];
    [exitItem setTarget:self];
    [_statusMenu addItem:exitItem];
#endif
  }

  // update first menu item
  if (_statusItem) {
    NSMenuItem* showItem = [_statusMenu itemAtIndex:0];
    if (showItem) {
      BOOL status = [self status];
      if (status) {
        [_statusItem setImage:_activeIcon];
        if (_isHidden) {
          [showItem setTitle:(@"Show Visor")];
        } else {
          [showItem setTitle:(@"Hide Visor")];
        }
      } else {
        [_statusItem setImage:in_activeIcon];
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
    return !!_window;
  }
#if defined(DEBUG)
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
