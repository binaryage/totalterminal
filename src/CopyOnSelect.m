// taken from http://github.com/genki/terminalcopyonselect

#import <objc/runtime.h>
#import "CopyOnSelect.h"

@implementation TTView (TerminalCopyOnSelect)
- (void) myMouseUp:(NSEvent *)theEvent
{
    [self myMouseUp:theEvent];
    bool copyOnSelect = [[NSUserDefaults standardUserDefaults] boolForKey:@"VisorCopyOnSelect"];
    if (!copyOnSelect) return;
    NSString *selectedText = [[(id)self performSelector:@selector(selectedText)] retain];
    if([selectedText length] > 0){
        [(id)self performSelector:@selector(copy:) withObject:nil];
    }
    [selectedText release];
}
@end

@implementation TerminalCopyOnSelect
+(void) load
{
    Class class = objc_getClass("TTView");
    Method mouseUp = class_getInstanceMethod(class, @selector(mouseUp:));
    Method myMouseUp = class_getInstanceMethod(class, @selector(myMouseUp:));
    method_exchangeImplementations(mouseUp, myMouseUp);
    
    NSLog(@"TerminalCopyOnSelect installed");
}
@end