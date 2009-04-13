@interface TTWindow: NSWindow {
}
- (id)initWithContentRect:(struct _NSRect)fp8 styleMask:(unsigned int)fp24 backing:(unsigned int)fp28 defer:(BOOL)fp32;
-(BOOL)canBecomeKeyWindow;
-(BOOL)canBecomeMainWindow;
@end