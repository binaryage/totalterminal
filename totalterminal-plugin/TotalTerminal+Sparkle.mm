#include "TotalTerminal+Sparkle.h"
#include "Updater.h"

@implementation TotalTerminal (Sparkle)
-(void) refreshFeedURLInUpdater {
    TTUpdater* updater = [TTUpdater sharedUpdater];

    if (!updater) return;

    BOOL useBeta = [[NSUserDefaults standardUserDefaults] boolForKey:@"TotalTerminalUsePreReleases"];
    if (useBeta) {
        [updater setFeedURL:[NSURL URLWithString:@"http://updates.binaryage.com/totalterminal-beta.xml"]];
    } else {
        [updater setFeedURL:[NSURL URLWithString:@"http://updates.binaryage.com/totalterminal.xml"]];
    }
}

@end
