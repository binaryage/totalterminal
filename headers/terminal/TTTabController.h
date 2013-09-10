@class TTPane;

@interface TTTabController : NSObject<NSSplitViewDelegate> { }

@property (readonly) TTPane* activePane; // @synthesize activePane;

-(id)windowController;
-(void)closePane:(id)arg1;
-(void)splitPane:(id)arg1;

@end
