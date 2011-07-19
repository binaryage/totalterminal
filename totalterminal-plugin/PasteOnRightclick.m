//  Created by Anmol Khirbat on 1/18/10.

#import "PasteOnRightclick.h"
#import "JRSwizzle.h"
#import "Macros.h"

@implementation NSView (PasteOnRightclick)
- (void) Visor_rightMouseDown:(NSEvent *)theEvent
{
	bool pasteOnRightclick = [[NSUserDefaults standardUserDefaults] boolForKey:@"VisorPasteOnRightclick"];
	
	if (pasteOnRightclick)
		[(id)self performSelector:@selector(paste:) withObject:nil];
	else
		[self Visor_rightMouseDown:theEvent];
}
@end

@implementation PasteOnRightclick
+ (void) load {
    [NSClassFromString(@"TTView") jr_swizzleMethod:@selector(rightMouseDown:) 
										withMethod:@selector(Visor_rightMouseDown:) error:NULL];
    LOG(@"PasteOnRightclick installed");
}
@end