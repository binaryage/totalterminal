// taken from http://github.com/genki/terminalcopyonselect

#define PROJECT CopyOnSelect
#import "TotalTerminal+CopyOnSelect.h"

@implementation NSView (TotalTerminal)
-(void) SMETHOD (TTView, mouseUp):(NSEvent*)theEvent {
    [self SMETHOD (TTView, mouseUp):theEvent];
    bool copyOnSelect = [[NSUserDefaults standardUserDefaults] boolForKey:@"TotalTerminalCopyOnSelect"];
    if (!copyOnSelect) return;
    NSString* selectedText = [[(id) self performSelector:@selector(selectedText)] retain];
    if ([selectedText length] > 0) {
        [(id) self performSelector:@selector(copy:) withObject:nil];
    }
    [selectedText release];
}

@end

@implementation TotalTerminal (CopyOnSelect)
+(void) loadCopyOnSelect {
    SWIZZLE(TTView, mouseUp:);
    LOG(@"CopyOnSelect installed");
}

@end
