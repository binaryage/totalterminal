//
//  Visor.h
//  Visor
//
//  Created by Nicholas Jitkoff on 6/1/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NDHotKeyEvent.h"
@class TermController;
@class TermDefaults;
@class TTProfileManager;
@interface Visor : NSObject {
    NSWindow* window; // the one visorized terminal window (may be nil)
    NSWindow* background; // background window for quartz animations (will be nil if not enabled in settings!)
    NSStatusItem* statusItem;
    IBOutlet NSWindow* prefsWindow;
    IBOutlet NSMenu* statusMenu;
    IBOutlet NSWindow* aboutWindow;
    NDHotKeyEvent* hotkey;
    NDHotKeyEvent* escapeKey;
    NSString* previouslyActiveApp;
    BOOL hidden;
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
- (void)enableHotKey;
- (void)initEscapeKey;
- (void)maybeEnableEscapeKey:(BOOL)enable;
- (void)activateStatusMenu;
- (NSWindow*)background;
- (void) setBackground: (NSWindow*)newBackground;
- (void)saveDefaults;
@end
