// Created by Anmol Khirbat on 1/18/10.

#define PROJECT PasteOnRightClick
#import "TotalTerminal+PasteOnRightClick.h"

@implementation NSView (TotalTerminal)
-(void) SMETHOD (TTView, rightMouseDown):(NSEvent*)theEvent {
    bool pasteOnRightclick = [[NSUserDefaults standardUserDefaults] boolForKey:@"TotalTerminalPasteOnRightClick"];

    if (pasteOnRightclick)
        [(id) self performSelector:@selector(paste:) withObject:nil];
    else [self SMETHOD (TTView, rightMouseDown):theEvent];
}

@end

@implementation TotalTerminal (PasteOnRightClick)

+(void) loadPasteOnRightClick {
    SWIZZLE(TTView, rightMouseDown:);
    LOG(@"PasteOnRightClick installed");
}

@end
