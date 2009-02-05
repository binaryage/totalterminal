//
//  Visor.h
//  Visor
//
//  Created by Nicholas Jitkoff on 6/1/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NDHotKeyEvent.h"
@class TermDefaults;
@class TTProfileManager;
@interface Visor : NSObject {
    NSWindow* window; // the one visorized terminal window (may be nil)
    NSStatusItem* statusItem;
    IBOutlet NSWindow* prefsWindow;
    IBOutlet NSMenu* statusMenu;
    IBOutlet NSWindow* aboutWindow;
    NDHotKeyEvent* hotkey;
    NDHotKeyEvent* escapeKey;
    NSString* previouslyActiveApp;
    BOOL hidden;
    BOOL needPlacement;
    NSImage* activeIcon;
    NSImage* inactiveIcon;
    NSScreen* cachedScreen;
}
- (BOOL)status;
- (void)adoptTerminal:(NSWindow*)window;
- (IBAction)showPrefs:(id)sender;
- (IBAction)toggleVisor:(id)sender;
- (IBAction)setHotKey:(id)sender;
- (IBAction)chooseFile:(id)sender;
- (IBAction)showAboutBox:(id)sender;
- (void)hideWindow;
- (void)showWindow;
- (void)hide;
- (void)enableHotKey;
- (void)initEscapeKey;
- (void)maybeEnableEscapeKey:(BOOL)enable;
- (void)activateStatusMenu;
- (void)saveDefaults;
- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)item;
@end

@interface VisorScreenTransformer: NSValueTransformer {
}
@end
