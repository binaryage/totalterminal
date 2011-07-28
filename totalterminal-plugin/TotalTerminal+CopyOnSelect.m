// taken from http://github.com/genki/terminalcopyonselect

#import "TotalTerminal+CopyOnSelect.h"
#import "JRSwizzle.h"
#import "Macros.h"

@implementation NSView (TerminalCopyOnSelect)
-(void) Visor_mouseUp:(NSEvent*)theEvent {
    [self Visor_mouseUp:theEvent];
    bool copyOnSelect = [[NSUserDefaults standardUserDefaults] boolForKey:@"VisorCopyOnSelect"];
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
    [NSClassFromString (@"TTView") jr_swizzleMethod:@selector(mouseUp:) withMethod:@selector(Visor_mouseUp:) error:NULL];
    LOG(@"TerminalCopyOnSelect installed");
}

@end
