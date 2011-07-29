#include "CGSPrivate.h"
#include "ScreenUpdates.h"

static int screenCounter = 0;

void NSDisableScreenUpdatesx(const char* fn) {
    if (screenCounter == 0) {
        NSLOG3(@"*** CGSDisableUpdate -- %s", fn);
        CGSDisableUpdate(_CGSDefaultConnection());
    }
    screenCounter++;
}

void NSEnableScreenUpdatesx(const char* fn) {
    screenCounter--;
    if (screenCounter == 0) {
        NSLOG3(@"*** CGSReenableUpdate -- %s", fn);
        CGSReenableUpdate(_CGSDefaultConnection());
    }
}

@implementation TimingHelper

-(id) initWithFn:(const char*)fn {
    if ((self = [self init])) {
        fn_ = fn;
    }
    return self;
}

-(void) fire {
    NSEnableScreenUpdatesx(fn_);
    [self release];
}

@end
