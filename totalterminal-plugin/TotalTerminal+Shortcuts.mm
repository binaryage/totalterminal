#import "TotalTerminal+Shortcuts.h"
#import "SRRecorderControl.h"

static KeyCombo cachedShortcuts[eShortcutsCount];

NSDictionary* makeKeyModifiersDictionary(NSInteger code, NSUInteger flags) {
    return [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:flags], @"Modifiers", [NSNumber numberWithInt:code], @"KeyCode", nil];
}

NSInteger readKeyFromDictionary(NSDictionary* dictionary) {
    NSNumber* x = [dictionary objectForKey:@"KeyCode"];

    if (!x) return -1;

    if (![x respondsToSelector:@selector(intValue)]) return -1;

    return [x intValue];
}

NSUInteger readModifiersFromDictionary(NSDictionary* dictionary) {
    NSNumber* x = [dictionary objectForKey:@"Modifiers"];

    if (!x) return -1;

    if (![x respondsToSelector:@selector(unsignedIntValue)]) return 0;

    return [x unsignedIntValue];
}

KeyCombo makeKeyComboFromDictionary(NSDictionary* hotkey) {
    KeyCombo res;

    res.flags = readModifiersFromDictionary(hotkey);
    res.code = readKeyFromDictionary(hotkey);
    return res;
}

bool testKeyCombo(KeyCombo combo, NSInteger code, NSUInteger flags) {
    if (combo.code == -1) return false;

    return combo.code == code && combo.flags == flags;
}

@implementation TotalTerminal (Shortcuts)

#pragma mark -
#pragma mark Shortcuts Helpers
#pragma mark -

-(TShortcuts) translateShortcutNameToIndex:(NSString*)name {
    TShortcuts index = eUnknownShortcut;

    if ([name isEqualToString:@"ToggleVisor"]) {
        index = eToggleVisor;
    } else if ([name isEqualToString:@"PinVisor"]) {
        index = ePinVisor;
    }
    return index;
}

-(void) updateShortcut:(NSString*)name withCombo:(KeyCombo)combo {
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    NSDictionary* shortcuts = [ud objectForKey:@"TotalTerminalShortcuts"];

    if (!shortcuts)
        shortcuts = [NSDictionary dictionary];
    NSMutableDictionary* ns = [NSMutableDictionary dictionaryWithDictionary:shortcuts];
    [ns setObject:makeKeyModifiersDictionary(combo.code, combo.flags) forKey:name];
    [ud setObject:ns forKey:@"TotalTerminalShortcuts"];
}

#pragma mark -
#pragma mark Operations
#pragma mark -

-(KeyCombo) keyComboForShortcut:(TShortcuts)index {
    return cachedShortcuts[index];
}

-(void) updateCachedShortcuts {
    AUTO_LOGGER();

    for (int i = 0; i < eShortcutsCount; i++) {
        cachedShortcuts[i].code = -1; // no code
    }

    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    NSDictionary* hotkeys = [ud objectForKey:@"TotalTerminalShortcuts"];
    if (!hotkeys) return;

    NSArray* keys = [hotkeys allKeys];
    for (size_t i = 0; i < [keys count]; ++i) {
        NSString* keyName = [keys objectAtIndex:i];
        NSDictionary* kd = [hotkeys objectForKey:keyName];
        KeyCombo combo = makeKeyComboFromDictionary(kd);
        TShortcuts shortcut = [self translateShortcutNameToIndex:keyName];
        if (shortcut != eUnknownShortcut) {
            cachedShortcuts[shortcut] = combo;
        }
    }
}

#pragma mark -
#pragma mark Delegate methods for Prefrence Panel
#pragma mark -

-(void) shortcutRecorder:(SRRecorderControl*)aRecorder keyComboDidChange:(KeyCombo)newKeyCombo {
    if (preventShortcutUpdates_) return;

    AUTO_LOGGERF(@"shortcutRecorder=%@ keyComboDidChange=%08lx code=%ld value=%@", aRecorder, (unsigned long)newKeyCombo.flags, (unsigned long)newKeyCombo.code, [aRecorder shortcut]);
    [self updateShortcut:[aRecorder shortcut] withCombo:newKeyCombo];
}

@end
