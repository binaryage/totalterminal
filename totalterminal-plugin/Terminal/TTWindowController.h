@class TTTabController;

@interface TTWindowController : NSWindowController { }

-(void)displayWindowCloseSheet:(int)arg1;
-(void)applyProfileToAllShellsInWindow:(id)arg1;
-(TTTabController*)selectedTabController;

@end
