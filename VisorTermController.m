//
//  VisorTermController.m
//  Visor
//
//  Created by Nicholas Jitkoff on 6/11/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "VisorTermController.h"


@implementation VisorTermController
- (void)shell:(id)aShell childDidExitWithStatus:(int)status{
	[super shell:aShell childDidExitWithStatus:status];	
	[delegate shell:aShell childDidExitWithStatus:status];	
}

- (id) delegate { return [[delegate retain] autorelease]; }
- (void) setDelegate: (id) newDelegate
{
    if (delegate != newDelegate) {
        [delegate release];
        delegate = [newDelegate retain];
    }
}



//- (void)updateSize{
//	
//}
- (void)updateSizeForRows:(unsigned int)rows columns:(unsigned int)cols{
	[super updateSizeForRows:rows columns:cols];
	[delegate windowResized];
//	NSLog(@"updatefor %d",rows);
}



- (void) dealloc
{
	NSLog(@"dealloc tcontr");
    [self setDelegate: nil];
    [super dealloc];
}


@end
