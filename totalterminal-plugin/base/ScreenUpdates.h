@interface TimingHelper : NSObject {
  const char* fn_;
}
-(id)initWithFn:(const char*)fn;
-(void)fire;
@end

@interface Performer : NSObject { }
-(void)fire;
@end

extern void NSEnableScreenUpdatesx(const char* fn);
extern void NSDisableScreenUpdatesx(const char* fn);

#ifdef __cplusplus

class ScopedNSDisableScreenUpdates {
public:
  const char* fn_;
  ScopedNSDisableScreenUpdates(const char* fn = NULL) {
    fn_ = fn;
    NSDisableScreenUpdatesx(fn_);
  }

  ~ScopedNSDisableScreenUpdates() {
    NSEnableScreenUpdatesx(fn_);
  }
};

class ScopedNSDisableScreenUpdatesWithDelay {
public:
  NSTimeInterval delay_;
  const char* fn_;
  ScopedNSDisableScreenUpdatesWithDelay(NSTimeInterval delay, const char* fn = NULL) {
    fn_ = fn;
    delay_ = delay;
    NSDisableScreenUpdatesx(fn_);
  }

  ~ScopedNSDisableScreenUpdatesWithDelay() {
    TimingHelper* timingHelper = [[TimingHelper alloc] initWithFn:fn_];

    [timingHelper performSelector : @selector(fire) withObject : nil afterDelay : delay_ inModes :[NSArray arrayWithObjects : NSDefaultRunLoopMode, NSModalPanelRunLoopMode,
                                                                                                   NSEventTrackingRunLoopMode, nil]];
  }
};

#endif
