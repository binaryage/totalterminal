#include "TotalTerminal+Preferences.h"
#include "TotalTerminal+Visor.h"

#import "GTMHotKeyTextField.h"
#import "SRRecorderControl.h"

@implementation ModifierButtonImageView

-(void) mouseDown:(NSEvent*)event {
    AUTO_LOGGER();
    TotalTerminal* tt = [TotalTerminal sharedInstance];
    [tt rotateModifierHotKey];
    [NSApp sendAction:[self action] to:[self target] from:self];
}

@end

@implementation NSView (TotalTerminal)

-(NSView*) TotalTerminal_findSRRecorderFor:(NSString*)shortcut {
    if ([[self className] isEqualToString:@"SRRecorderControl"]) {
        if ([[self shortcut] isEqualToString:shortcut]) {
            return self;
        }
    }

    NSArray* subviews = [self subviews];
    DCHECK(subviews);
    if (!subviews) return nil;

    size_t count = [subviews count];
    for (size_t i = 0; i < count; ++i) {
        NSView* view = [subviews objectAtIndex:i];
        NSView* found = [view TotalTerminal_findSRRecorderFor:shortcut];
        if (found) {
            return found;
        }
    }
    return nil;
}

-(void) TotalTerminal_refreshSRRecorders {
    if ([[self className] isEqualToString:@"SRRecorderControl"]) {
        [self setNeedsDisplay:YES];
    }

    NSArray* subviews = [self subviews];
    DCHECK(subviews);
    if (!subviews) return;

    size_t count = [subviews count];
    for (size_t i = 0; i < count; ++i) {
        NSView* view = [subviews objectAtIndex:i];
        [view TotalTerminal_refreshSRRecorders];
    }
}

@end

@implementation NSWindowController (TotalTerminal)

// ------------------------------------------------------------
// TTAppPrefsController hacks

// Add Visor preference pane into Preferences window
-(void) SMETHOD (TTAppPrefsController, windowDidLoad) {
    AUTO_LOGGER();
    [self SMETHOD (TTAppPrefsController, windowDidLoad)];
    TotalTerminal* tt = [TotalTerminal sharedInstance];
    [tt updatePreferencesUI];
}

-(void) SMETHOD (TTAppPrefsController, selectVisorPane) {
    AUTO_LOGGER();
    TotalTerminal* tt = [TotalTerminal sharedInstance]; // for some reason this function may be not called in rare case we started visor and created Visor profile
    [tt updatePreferencesUI];
    NSWindow* prefsWindow = [self window];
    [prefsWindow setTitle:@"Visor"];
    NSToolbar* toolbar = [prefsWindow toolbar];
    [toolbar setSelectedItemIdentifier:@"Visor"];
    NSTabView* tabView = [self valueForKey:@"tabView"];
    [tabView selectTabViewItemWithIdentifier:@"VisorPane"];
}

-(id) SMETHOD (TTAppPrefsController, toolbar):(id)arg1 itemForItemIdentifier:(id)arg2 willBeInsertedIntoToolbar:(BOOL)arg3 {
    AUTO_LOGGERF(@"item=%@", arg2);
    if ([arg2 isEqualToString:@"Visor"]) {
        TotalTerminal* tt = [TotalTerminal sharedInstance];
        NSToolbarItem* toolbarItem = [tt getVisorToolbarItem];
        [toolbarItem setTarget:self];
        [toolbarItem setAction:@selector(SMETHOD(TTAppPrefsController,selectVisorPane))];
        return toolbarItem;
    }
    return [self SMETHOD (TTAppPrefsController, toolbar):arg1 itemForItemIdentifier:arg2 willBeInsertedIntoToolbar:arg3];
}

-(void) SMETHOD (TTAppPrefsController, tabView):(id)view didSelectTabViewItem:(NSTabViewItem*)tab {
    AUTO_LOGGERF(@"tab=%@", tab);
    TotalTerminal* tt = [TotalTerminal sharedInstance];
    NSSize originalSize;
    originalSize = (NSSize)[tt originalPreferencesSize];
    NSWindow* prefsWindow = [self window];
    NSRect frame = [prefsWindow contentRectForFrameRect:[prefsWindow frame]];
    if (originalSize.width == 0) {
        [tt setOriginalPreferencesSize:frame.size];
        originalSize = frame.size;
    }
    if ([[tab identifier] isEqualToString:@"VisorPane"]) {
        NSRect viewItemFrame = [[[[self valueForKey:@"tabView"] tabViewItemAtIndex:0] view] frame];
        NSSize visorPrefpanelSize = [tt prefPaneSize];
        // / frame.size.width += visorPrefpanelSize.width - viewItemFrame.size.width;
        frame.size.height += visorPrefpanelSize.height - viewItemFrame.size.height;
        frame.origin.y -= visorPrefpanelSize.height - viewItemFrame.size.height;
    } else {
        frame.origin.y += frame.size.height - originalSize.height;
        frame.size = originalSize;
    }
    frame = [prefsWindow frameRectForContentRect:frame];
    [prefsWindow setFrame:frame display:YES animate:NO];
    return [self SMETHOD (TTAppPrefsController, tabView):view didSelectTabViewItem:tab];
}

-(id) SMETHOD (TTAppPrefsController, windowWillReturnFieldEditor):(NSWindow*)sender toObject:(id)client {
    if ([client isKindOfClass:[GTMHotKeyTextField class ]]) {
        LOG(@"TTAppPrefsController windowWillReturnFieldEditor called with GTMHotKeyTextField");
        return [GTMHotKeyFieldEditor sharedHotKeyFieldEditor];
    }
    return [self SMETHOD (TTAppPrefsController, windowWillReturnFieldEditor):sender toObject:client];
}

-(id) windowWillReturnFieldEditor:(NSWindow*)sender toObject:(id)client {
    return nil;
}

@end

@implementation TotalTerminal (Preferences)

-(id) windowWillReturnFieldEditor:(NSWindow*)sender toObject:(id)client {
    if ([client isKindOfClass:[GTMHotKeyTextField class ]]) {
        return [GTMHotKeyFieldEditor sharedHotKeyFieldEditor];
    }
    return nil;
}

-(void) webView:(WebView*)sender decidePolicyForNavigationAction:(NSDictionary*)actionInformation request:(NSURLRequest*)request frame:(WebFrame*)frame decisionListener:(id<WebPolicyDecisionListener> )
   listener {
    LOG(@"webView:decidePolicyForNavigationAction...");
    if ([[actionInformation objectForKey:WebActionNavigationTypeKey] intValue] != WebNavigationTypeOther) {
        [listener ignore];
        [[NSWorkspace sharedWorkspace] openURL:[request URL]];
    } else {
        [listener use];
    }
}

-(void) updateInfoLine {
    LOG(@"updateInfoLine %@", infoLine);
    [[infoLine mainFrame] loadHTMLString:
     @"<style>html, body {margin:0; padding:0} html {font-family: 'Lucida Grande', arial; font-size: 10px; cursor: default; color: #999;} a, a:visited { color: #66f; } a:hover {color: #22f}</style><center><b>TotalTerminal ##VERSION##</b> by <a href=\"http://binaryage.com\">binaryage.com</a></center>"
                                 baseURL:[NSURL URLWithString:@"http://totalterminal.binaryage.com"]];
    [infoLine setDrawsBackground:NO];
}

-(void) enahanceTerminalPreferencesWindow {
    static bool alreadyEnhanced = NO;

    if (alreadyEnhanced) return;

    AUTO_LOGGER();

    id prefsController = [NSClassFromString (@"TTAppPrefsController")sharedPreferencesController];
    if (!prefsController) {
        return;
    }

    NSTabView* tabView = nil;
    @try {
        tabView = [prefsController valueForKey:@"tabView"];
        if (!tabView) {
            return;
        }
    } @catch (NSException* exception) {
        ERROR(@"enahanceTerminalPreferencesWindow: Caught %@: %@", [exception name], [exception reason]);
        return;
    }

    NSWindow* prefsWindow = [prefsController window];
    if (!prefsWindow) {
        return;
    }

    NSTabView* sourceTabView = [[[settingsWindow contentView] subviews] objectAtIndex:0];
    if (!sourceTabView) {
        return;
    }
    NSTabViewItem* item = [sourceTabView tabViewItemAtIndex:0];
    if (!item) {
        return;
    }

    NSToolbar* toolbar = [prefsWindow toolbar];
    if (!toolbar) {
        return;
    }
    [toolbar insertItemWithItemIdentifier:@"Visor" atIndex:4];
    [tabView addTabViewItem:item];
    alreadyEnhanced = YES;
}

-(NSSize) originalPreferencesSize {
    return originalPreferencesSize;
}

-(void) setOriginalPreferencesSize:(NSSize)size {
    originalPreferencesSize = size;
}

-(NSSize) prefPaneSize {
    return prefPaneSize;
}

-(void) storePreferencesPaneSize {
    // Store size of Visor preferences panel as it was set in IB
    NSTabView* sourceTabView = [[[settingsWindow contentView] subviews] objectAtIndex:0];
    NSTabViewItem* item = [sourceTabView tabViewItemAtIndex:0];

    prefPaneSize = [[item view] frame].size;
}

-(NSInteger) numberOfItemsInComboBox:(NSComboBox*)aComboBox {
    LOG(@"numberOfItemsInComboBox %@", aComboBox);
    return [[NSScreen screens] count];
}

-(id) comboBox:(NSComboBox*)aComboBox objectValueForItemAtIndex:(NSInteger)index {
    LOG(@"comboBox %@, objectValueForItemAtIndex %d", aComboBox, index);
    VisorScreenTransformer* transformer = [[VisorScreenTransformer alloc] init];
    id res = [transformer transformedValue:[NSNumber numberWithInteger:index]];
    [transformer release];
    return res;
}

-(NSToolbarItem*) getVisorToolbarItem {
    LOG(@"getVisorToolbarItem");
    NSToolbar* sourceToolbar = [settingsWindow toolbar];
    NSToolbarItem* toolbarItem = [[sourceToolbar items] objectAtIndex:0];
    return toolbarItem;
}

-(void) rotateModifierHotKey {
    AUTO_LOGGER();
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    NSInteger mask = [ud integerForKey:@"TotalTerminalVisorHotKey2Mask"];

    if (mask == NSAlternateKeyMask) {
        mask = NSCommandKeyMask;
    } else if (mask == NSCommandKeyMask) {
        mask = NSControlKeyMask;
    } else if (mask == NSControlKeyMask) {
        mask = NSShiftKeyMask;
    } else {
        mask = NSAlternateKeyMask;
    }
    [ud setInteger:mask forKey:@"TotalTerminalVisorHotKey2Mask"];
}

-(void) updatePreferencesUIForHotkeys {
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    NSDictionary* hotkeys = [ud objectForKey:@"TotalTerminalShortcuts"];

    AUTO_LOGGERF(@"hotkeys=%@", hotkeys);

    if (!hotkeys) return;
    preventShortcutUpdates_ = TRUE;

    NSArray* keys = [hotkeys allKeys];
    for (size_t i = 0; i < [keys count]; ++i) {
        NSString* keyName = [keys objectAtIndex:i];
        NSDictionary* kd = [hotkeys objectForKey:keyName];
        KeyCombo combo = makeKeyComboFromDictionary(kd);

        SRRecorderControl* recorder = (SRRecorderControl*)[preferencesView TotalTerminal_findSRRecorderFor:keyName];
        if (recorder) {
            [recorder setKeyCombo:combo];
        }
    }
    preventShortcutUpdates_ = FALSE;
}

-(void) updatePreferencesUI {
    AUTO_LOGGER();
    [self enahanceTerminalPreferencesWindow];
    [self updateShouldShowTransparencyAlert];
    [self updateInfoLine];

    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];

    NSImage* modifiersIcon = modifiersOption_;
    NSInteger mask = [ud integerForKey:@"TotalTerminalVisorHotKey2Mask"];
    if (mask == NSCommandKeyMask) {
        modifiersIcon = modifiersCommand_;
    } else if (mask == NSControlKeyMask) {
        modifiersIcon = modifiersControl_;
    } else if (mask == NSShiftKeyMask) {
        modifiersIcon = modifiersShift_;
    }
    [modifierIcon1_ setImage:modifiersIcon];
    [modifierIcon1_ setNeedsDisplay:YES];
    [modifierIcon2_ setImage:modifiersIcon];
    [modifierIcon2_ setNeedsDisplay:YES];

    if ([TotalTerminal hasVisorProfile]) {
        [createProfileButton_ setEnabled:NO];
    } else {
        [createProfileButton_ setEnabled:YES];
    }

    [self updatePreferencesUIForHotkeys];
}

-(void) inputSourceChanged {
    AUTO_LOGGER();
    [self updatePreferencesUI];
    [preferencesView TotalTerminal_refreshSRRecorders];
}

@end
