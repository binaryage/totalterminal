@interface TTApplication : NSApplication<NSApplicationDelegate, NSMenuDelegate, NSUserInterfaceItemSearching> { }

-(id)newWindowControllerWithProfile:(id)arg1 NS_RETURNS_NOT_RETAINED;
-(id)newWindowControllerWithProfile:(id) arg1 customFont:(id) arg2 command:(id) arg3 runAsShell:(BOOL) arg4 restorable:(BOOL) arg5 workingDirectory:(id)arg6 NS_RETURNS_NOT_RETAINED;
// 10.8+ interface
-(id)makeWindowControllerWithProfile:(id)arg1;
-(id)makeWindowControllerWithProfile:(id) arg1 customFont:(id) arg2 command:(id) arg3 runAsShell:(BOOL) arg4 restorable:(BOOL) arg5 workingDirectory:(id)arg6;

-(void)showPreferencesWindow:(id)arg1;

@end
