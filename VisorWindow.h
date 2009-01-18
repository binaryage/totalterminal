//
//  VisorWindow.h
//  Visor
//
//  Created by Nicholas Jitkoff on 6/1/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TTWindow : NSWindow
{
    struct _NSRect _fullFrame;
}

- (id)initWithContentRect:(struct _NSRect)fp8 styleMask:(unsigned int)fp24 backing:(unsigned int)fp28 defer:(BOOL)fp32;
- (void)sendEvent:(id)fp8;
- (void)selectFollowingWindow:(id)fp8 goingBackwards:(BOOL)fp12;
- (struct _NSRect)fullFrame;
- (void)setFullFrame:(struct _NSRect)fp8;
- (BOOL)validateMenuItem:(id)fp8;

@end