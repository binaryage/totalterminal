#import "TotalTerminal.h"

@interface VisorScreenTransformer : NSValueTransformer { \
}
@end

@interface TotalTerminal (Visor)

+(void)loadVisor;

-(BOOL)status;
-(NSWindow*)window;
-(void)setWindow:(NSWindow*)inWindow;
-(BOOL)isVisorWindow:(id)win;
-(void)openVisor;
-(void)showVisor:(BOOL)fast;
-(void)hideVisor:(BOOL)fast;
-(void)adoptTerminal:(id)win;
-(void)resetVisorWindowSize;

-(void)startEventMonitoring;
-(BOOL)isHidden;
-(void)updateHotKeyRegistration;
-(void)resetWindowPlacement;
-(void)updateVisorWindowSpacesSettings;
-(void)updateFullScreenHotKeyRegistration;
-(void)updateEscapeHotKeyRegistration;
-(void)updateVisorWindowLevel;

-(NSWindow*)background;
-(void)initializeBackground;
-(float)getVisorProfileBackgroundAlpha;
-(void)updateAnimationAlpha;

-(void)modifiersChangedWhileActive:(NSEvent*)event;
-(void)keysChangedWhileActive:(NSEvent*)event;
-(void)modifiersChangedWhileInactive:(NSEvent*)event;

@end
