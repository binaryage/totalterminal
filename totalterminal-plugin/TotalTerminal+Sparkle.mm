#import "TotalTerminal+Sparkle.h"
#import "Updater.h"

@implementation TotalTerminal (Sparkle)

-(void) refreshFeedURLInUpdater {
    TTUpdater* updater = [TTUpdater sharedUpdater];

    if (!updater) return;

    // with every new release to be published it is recommended to test if Sparkle really works
    // publishing a version with broken Sparkle updater would be a real pain
    //
    // the idea:
    // 1. prepare totalterminal-test.xml and upload it to http://updates.binaryage.com
    // 2. install new release on a test machine
    // 3. touch ~/.use-test-appcast
    // 4. check for updates and go through updater/installer
    //
    // totalterminal-test.xml should contain current binary but with bumped version number, so it triggers and emulates updating to future version
    //
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSString* useTestAppCastPath = [@"~/.use-test-appcast" stringByStandardizingPath];

    BOOL useTest = [fileManager fileExistsAtPath:useTestAppCastPath];
    if (useTest) {
        NSLog(@"Using http://updates.binaryage.com/totalterminal-test.xml as appcast because %@ is present.", useTestAppCastPath);
        [updater setFeedURL:[NSURL URLWithString:@"http://updates.binaryage.com/totalterminal-test.xml"]];
        return;
    }

    // normal screnario
    BOOL useBeta = [[NSUserDefaults standardUserDefaults] boolForKey:@"TotalTerminalUsePreReleases"];
    if (useBeta) {
        [updater setFeedURL:[NSURL URLWithString:@"http://updates.binaryage.com/totalterminal-beta.xml"]];
    } else {
        [updater setFeedURL:[NSURL URLWithString:@"http://updates.binaryage.com/totalterminal.xml"]];
    }
}

@end
