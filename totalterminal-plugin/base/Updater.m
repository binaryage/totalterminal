#import "Updater.h"

@implementation TTUpdater

+(id) sharedUpdater {
    return [self updaterForBundle:[NSBundle bundleForClass:[self class]]];
}

-(id) init {
    return [self initForBundle:[NSBundle bundleForClass:[self class]]];
}

@end
