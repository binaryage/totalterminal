@class TTPane;

@interface TTTabController : NSObject<NSSplitViewDelegate> { }

@property (readonly) TTPane* activePane; // @synthesize activePane;

@end
