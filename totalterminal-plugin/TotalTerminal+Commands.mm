#include "TotalTerminal+Commands.h"
#include "Updater.h"

@implementation TotalTerminal (Commands)
-(IBAction) showTransparencyHelpPanel:(id)sender {
    AUTO_LOGGERF(@"sender=%@", sender);
    [NSApp beginSheet:transparencyHelpPanel modalForWindow:[[NSClassFromString (@"TTAppPrefsController")
                                                             sharedPreferencesController] window] modalDelegate:self didEndSelector:NULL contextInfo:nil];
}

-(IBAction) closeTransparencyHelpPanel:(id)sender {
    AUTO_LOGGERF(@"sender=%@", sender);
    [transparencyHelpPanel orderOut:nil];
    [NSApp endSheet:transparencyHelpPanel];
}

-(IBAction) uninstallMe:(id)sender {
    AUTO_LOGGERF(@"sender=%@", sender);
    NSAlert* alert = [[[NSAlert alloc] init] autorelease];
    
    [alert setIcon:alternativeDockIcon];
    [alert addButtonWithTitle:(@"Uninstall")];
    [alert addButtonWithTitle:(@"Cancel")];
    [alert setMessageText:(@"Really want to uninstall TotalTerminal?")];
    [alert setInformativeText:(@"This will launch an uninstall script which will remove TotalTerminal from this computer and restore your original Terminal behavior.")];
    [alert setAlertStyle:NSWarningAlertStyle];
    NSInteger returnCode = [alert runModal];
    if (returnCode == NSAlertFirstButtonReturn) {
        NSString* uninstallerPath =
        [[[[NSBundle bundleForClass:[self class]] resourcePath] stringByAppendingPathComponent:@"TotalTerminal Uninstaller.app"] stringByStandardizingPath];
        [[NSWorkspace sharedWorkspace] launchApplication:uninstallerPath];
    }
}


-(IBAction) updateMe:(id)sender {
    AUTO_LOGGERF(@"sender=%@", sender);
    TTUpdater* updater = [TTUpdater sharedUpdater];
    
    if (!updater) return;
    
    [self refreshFeedURLInUpdater];
    [updater resetUpdateCycle];
    [updater checkForUpdates:sender];
}

-(void) togglePinVisor:(id)sender {
    AUTO_LOGGERF(@"sender=%@", sender);
    if (!window_) return;
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    BOOL val = [ud boolForKey:@"TotalTerminalVisorPinned"];
    [ud setBool:(val ? NO:YES) forKey:@"TotalTerminalVisorPinned"];
}

-(IBAction) toggleVisor:(id)sender {
    AUTO_LOGGERF(@"sender=%@ isHidden=%d", sender, isHidden);
    if (!window_) {
        isHidden = YES;
        [self openVisor];
    }
    if (isHidden) {
        [self showVisor:false];
    } else {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"TotalTerminalVisorPinned"]) {
            // @dr_win @binaryage when will the #TF #Visor get the ability to be brought to front when pinned, rather than hiding and coming back?
            if (![self isCurrentylyActive]) {
                [NSApp activateIgnoringOtherApps:YES];
            }
            // imagine visor window + one classic terminal window, when classic window has key status, we want out visor window to steal key status first time the toggle is executed
            bool isKey = [window_ isKeyWindow];
            if (isKey) {
                [self hideVisor:false];
            } else {
                [window_ makeKeyWindow]; 
            }
        } else {
            [self hideVisor:false];
        }
    
    }
}

-(IBAction) showPrefs:(id)sender {
    AUTO_LOGGERF(@"sender=%@", sender);
    [NSApp activateIgnoringOtherApps:YES];
    id terminalApp = [NSClassFromString (@"TTApplication")sharedApplication];
    [terminalApp showPreferencesWindow:nil];
    id prefsController = [NSClassFromString (@"TTAppPrefsController")sharedPreferencesController];
    [prefsController SMETHOD(TTAppPrefsController, selectVisorPane)];
}

-(IBAction) visitHomepage:(id)sender {
    AUTO_LOGGERF(@"sender=%@", sender);
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://totalterminal.binaryage.com"]];
}

-(IBAction) chooseBackgroundComposition:(id)sender {
    AUTO_LOGGERF(@"sender=%@", sender);
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    
    [panel setTitle:@"Select a Quartz Composer (qtz) file"];
    if ([panel runModalForTypes:[NSArray arrayWithObject:@"qtz"]]) {
        NSString* path = [panel filename];
        path = [path stringByAbbreviatingWithTildeInPath];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"TotalTerminalVisorUseBackgroundAnimation"];
        [[NSUserDefaults standardUserDefaults] setObject:path forKey:@"TotalTerminalVisorBackgroundAnimationFile"];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"TotalTerminalVisorUseBackgroundAnimation"];
    }
}

-(IBAction) exitMe:(id)sender {
    AUTO_LOGGERF(@"sender=%@", sender);
    [NSApp terminate:self];
}

-(IBAction) crashMe:(id)sender {
    AUTO_LOGGERF(@"sender=%@", sender);
    *((char*)0) = 0;
}

@end