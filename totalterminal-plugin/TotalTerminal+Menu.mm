#import "TotalTerminal+Menu.h"
#import "TotalTerminal+Shortcuts.h"
#import "SRCommon.h"

// In System Preferences->Keyboard->Keyboard Shortcuts, it is possible to add
// arbitrary keyboard shortcuts to applications. It is not documented how this
// works in detail, but |NSMenuItem| has a method |userKeyEquivalent| that
// sounds related.
// However, it looks like |userKeyEquivalent| is equal to |keyEquivalent| when
// a user shortcut is set in system preferences, i.e. Cocoa automatically
// sets/overwrites |keyEquivalent| as well. Hence, this method can ignore
// |userKeyEquivalent| and check |keyEquivalent| only.

@implementation TotalTerminal (Menu)

-(NSMenuItem*) findMenuItem:(NSMenu*)menu withSelector:(SEL)selector {
  size_t count = [menu numberOfItems];

  for (size_t i = 0; i < count; ++i) {
    NSMenuItem* item = [menu itemAtIndex:i];
    if (!item)
      continue;
    if ([item action] == selector) return item;
  }
  return NULL;
}

-(size_t) findMenuItemIndex:(NSMenu*)menu withSelector:(SEL)selector {
  size_t count = [menu numberOfItems];

  for (size_t i = 0; i < count; ++i) {
    NSMenuItem* item = [menu itemAtIndex:i];
    if (!item)
      continue;
    if ([item action] == selector) return i;
  }
  return NULL;
}

-(void) setKeyCombo:(KeyCombo)combo forMenuItem:(NSMenuItem*)menuItem {
  if (combo.code == -1) {
    [menuItem setKeyEquivalent:@""];
    [menuItem setKeyEquivalentModifierMask:0];
  } else {
    NSString* key = [SRCharacterForKeyCodeAndCocoaFlags (combo.code, combo.flags)lowercaseString];
    if (combo.flags & NSShiftKeyMask) {
      key = [key uppercaseString];
    }
    [menuItem setKeyEquivalent:key];

    // The NSShiftKeyMask constant is only used in conjunction with special keys, such as the F1 and F2 function keys,
    // and navigation keys like Page Up, Home, and arrow keys. It is not used for letters or symbols painted on the
    // key caps. As another example, use @"#" as the key equivalent instead of using @"3" with the NSShiftKeyMask set.
    NSUInteger flags = combo.flags;
    if (![key isEqualToString:[key lowercaseString]]) {
      flags &= ~NSShiftKeyMask;
    }
    [menuItem setKeyEquivalentModifierMask:flags];
  }
}

-(void) updateMainMenuWindowState:(NSMenu*)menu {
  NSMenuItem* menuItem;

  menuItem = [menu itemWithTag:4101];   // Pin Visor
  if (menuItem) {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"TotalTerminalVisorPinned"]) {
      [menuItem setState:NSOnState];
    } else {
      [menuItem setState:NSOffState];
    }
    [self setKeyCombo:[self keyComboForShortcut:ePinVisor] forMenuItem:menuItem];
  }
}

-(void) updateMainMenuState {
  NSMenu* menu = [NSApp mainMenu];

  AUTO_LOGGER();

  NSInteger menuIndex;
  NSMenuItem* viewMenuItem = [menu itemAtIndex:4];   // @"Window"
  DCHECK(viewMenuItem);
  if (viewMenuItem) {
    NSMenu* viewMenu = [viewMenuItem submenu];
    DCHECK(viewMenu);
    if (viewMenu) {
      [self updateMainMenuWindowState:viewMenu];
    }
  }
}

-(void) augumentWindowMenu {
  AUTO_LOGGER();
  NSMenu* menu = [NSApp mainMenu];
  NSMenuItem* menuItem;
  NSInteger menuIndex;
  NSMenuItem* windowMenuItem = [menu itemAtIndex:4];   // @"Window"
  DCHECK(windowMenuItem);
  if (windowMenuItem) {
    NSMenu* windowMenu = [windowMenuItem submenu];
    DCHECK(windowMenu);
    if (windowMenu) {
      menuIndex = [self findMenuItemIndex:windowMenu withSelector:@selector(_cycleWindows:)];
      DCHECK(menuIndex != -1);
      if (menuIndex != -1) {
        if (![windowMenu itemWithTag:4100]) {
          menuItem = [NSMenuItem separatorItem];
          [menuItem setTag:4100];
          [menuItem setTarget:self];
          [windowMenu insertItem:menuItem atIndex:menuIndex + 1];
        }
        if (![windowMenu itemWithTag:4101]) {
          menuItem = [[NSMenuItem alloc] initWithTitle:(@"Pin Visor") action:@selector(togglePinVisor:) keyEquivalent:@""];
          [menuItem setTag:4101];
          [menuItem setTarget:self];
          [windowMenu insertItem:menuItem atIndex:menuIndex + 2];
          [menuItem release];
        }
      }
    }
  }
}

-(void) augumentMainMenu {
  AUTO_LOGGER();
  [self augumentWindowMenu];
  [self updateMainMenuState];
}

@end
