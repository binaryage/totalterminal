#import <terminal/TTAppPrefsController.h>

#import "GTMHotKeyTextField.h"
#import "SRRecorderControl.h"

#import "TotalTerminal+Preferences.h"
#import "TotalTerminal+Visor.h"

@implementation ModifierButtonImageView

-(void) mouseDown:(NSEvent*)event {
  AUTO_LOGGER();
  [[TotalTerminal sharedInstance] rotateModifierHotKey];
  [NSApp sendAction:[self action] to:[self target] from:self];
}

@end

@implementation NSView (TotalTerminal)

-(NSView*) TotalTerminal_findSRRecorderFor:(NSString*)shortcut {
  if ([[self className] isEqualToString:@"SRRecorderControl"]) {
    SRRecorderControl* me = (SRRecorderControl*)self;
    if ([[me shortcut] isEqualToString:shortcut]) {
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
  [[TotalTerminal sharedInstance] updatePreferencesUI];
}

-(void) SMETHOD (TTAppPrefsController, selectVisorPane) {
  AUTO_LOGGER();
  // for some reason this function may be not called in rare case we started visor and created Visor profile
  [[TotalTerminal sharedInstance] updatePreferencesUI];
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
    NSToolbarItem* toolbarItem = [[TotalTerminal sharedInstance] getVisorToolbarItem];
    [toolbarItem setTarget:self];
    [toolbarItem setAction:@selector(SMETHOD(TTAppPrefsController,selectVisorPane))];
    return toolbarItem;
  }
  return [self SMETHOD (TTAppPrefsController, toolbar):arg1 itemForItemIdentifier:arg2 willBeInsertedIntoToolbar:arg3];
}

-(void) SMETHOD (TTAppPrefsController, tabView):(id)view didSelectTabViewItem:(NSTabViewItem*)tab {
  AUTO_LOGGERF(@"tab=%@", tab);
  TotalTerminal* totalTerminal = [TotalTerminal sharedInstance];
  NSSize originalSize;
  originalSize = (NSSize)[totalTerminal _originalPreferencesSize];
  NSWindow* prefsWindow = [self window];
  NSRect frame = [prefsWindow contentRectForFrameRect:[prefsWindow frame]];
  if (originalSize.width == 0) {
    [totalTerminal setOriginalPreferencesSize:frame.size];
    originalSize = frame.size;
  }
  if ([[tab identifier] isEqualToString:@"VisorPane"]) {
    NSRect viewItemFrame = [[[[self valueForKey:@"tabView"] tabViewItemAtIndex:0] view] frame];
    NSSize visorPrefpanelSize = [totalTerminal _prefPaneSize];
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
  if ([client isKindOfClass:[GTMHotKeyTextField class]]) {
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
  if ([client isKindOfClass:[GTMHotKeyTextField class]]) {
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
  LOG(@"updateInfoLine %@", _infoLine);
  [[_infoLine mainFrame] loadHTMLString:
   @"<style>html, body {margin:0; padding:0} html {font-family: 'Lucida Grande', arial; font-size: 10px; cursor: default; color: #999;} a, a:visited { color: #66f; } a:hover {color: #22f}</style><center><b>TotalTerminal ##VERSION##</b> by <a href=\"http://binaryage.com\">binaryage.com</a></center>"
                               baseURL:[NSURL URLWithString:@"http://totalterminal.binaryage.com"]];
  [_infoLine setDrawsBackground:NO];
}

-(void) enhanceTerminalPreferencesWindow {
  static bool alreadyEnhanced = NO;

  if (alreadyEnhanced) return;

  AUTO_LOGGER();

  TTAppPrefsController* prefsController = (TTAppPrefsController*)[NSClassFromString (@"TTAppPrefsController")sharedPreferencesController];
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
    ERROR(@"enhanceTerminalPreferencesWindow: Caught %@: %@", [exception name], [exception reason]);
    return;
  }

  NSWindow* prefsWindow = [prefsController window];
  if (!prefsWindow) {
    return;
  }

  NSTabView* sourceTabView = _settingsTabView;
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

-(NSSize) _originalPreferencesSize {
  return _originalPreferencesSize;
}

-(void) setOriginalPreferencesSize:(NSSize)size {
  _originalPreferencesSize = size;
}

-(NSSize) _prefPaneSize {
  return _prefPaneSize;
}

-(void) storePreferencesPaneSize {
  // Store size of Visor preferences panel as it was set in IB
  NSTabView* sourceTabView = _settingsTabView;
  if (!sourceTabView || ([[sourceTabView tabViewItems] count] <= 0)) {
    return;     // safety net
  }
  NSTabViewItem* item = [sourceTabView tabViewItemAtIndex:0];
  if (!item) {
    return;     // safety net
  }
  NSView* itemView = [item view];
  if (!itemView) {
    return;     // safety net
  }

  _prefPaneSize = [itemView frame].size;
}

-(NSInteger) numberOfItemsInComboBox:(NSComboBox*)aComboBox {
  LOG(@"numberOfItemsInComboBox %@", aComboBox);
  return [[NSScreen screens] count];
}

-(id) comboBox:(NSComboBox*)aComboBox objectValueForItemAtIndex:(NSInteger)index {
  LOG(@"comboBox %@, objectValueForItemAtIndex %d", aComboBox, (int)index);
  VisorScreenTransformer* transformer = [[VisorScreenTransformer alloc] init];
  id res = [transformer transformedValue:[NSNumber numberWithInteger:index]];
  return res;
}

-(NSToolbarItem*) getVisorToolbarItem {
  LOG(@"getVisorToolbarItem");
  if (!_visorToolbarItem) {
    _visorToolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:@"Visor"];
    [_visorToolbarItem setLabel:@"TotalTerminal"];
    [_visorToolbarItem setPaletteLabel:@"TotalTerminal"];
    [_visorToolbarItem setImage:[[NSBundle bundleForClass:[TotalTerminal class]] imageForResource:@"ToolbarIcon"]];
    [_visorToolbarItem setAutovalidates:YES];
    [_visorToolbarItem setEnabled:YES];
  }
  return _visorToolbarItem;
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

  _preventShortcutUpdates = TRUE;

  NSArray* keys = [hotkeys allKeys];
  for (size_t i = 0; i < [keys count]; ++i) {
    NSString* keyName = [keys objectAtIndex:i];
    NSDictionary* kd = [hotkeys objectForKey:keyName];
    KeyCombo combo = makeKeyComboFromDictionary(kd);

    SRRecorderControl* recorder = (SRRecorderControl*)[_preferencesView TotalTerminal_findSRRecorderFor:keyName];
    if (recorder) {
      [recorder setKeyCombo:combo];
    }
  }
  _preventShortcutUpdates = FALSE;
}

-(void) updatePreferencesUI {
  AUTO_LOGGER();
  [self enhanceTerminalPreferencesWindow];
  [self updateShouldShowTransparencyAlert];
  [self updateInfoLine];

  NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];

  NSImage* modifiersIcon = _modifiersOption;
  NSInteger mask = [ud integerForKey:@"TotalTerminalVisorHotKey2Mask"];
  if (mask == NSCommandKeyMask) {
    modifiersIcon = _modifiersCommand;
  } else if (mask == NSControlKeyMask) {
    modifiersIcon = _modifiersControl;
  } else if (mask == NSShiftKeyMask) {
    modifiersIcon = _modifiersShift;
  }
  [_modifierIcon1 setImage:modifiersIcon];
  [_modifierIcon1 setNeedsDisplay:YES];
  [_modifierIcon2 setImage:modifiersIcon];
  [_modifierIcon2 setNeedsDisplay:YES];

  if ([TotalTerminal hasVisorProfile]) {
    [_createProfileButton setEnabled:NO];
  } else {
    [_createProfileButton setEnabled:YES];
  }

  [self updatePreferencesUIForHotkeys];
}

-(void) inputSourceChanged {
  AUTO_LOGGER();
  [self updatePreferencesUI];
  [_preferencesView TotalTerminal_refreshSRRecorders];
}

@end
