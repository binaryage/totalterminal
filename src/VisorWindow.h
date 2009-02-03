//
//  VisorWindow.h
//  Visor
//
//  Created by Nicholas Jitkoff on 6/1/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TTWindow : NSWindow {
}
- (id)initWithContentRect:(struct _NSRect)fp8 styleMask:(unsigned int)fp24 backing:(unsigned int)fp28 defer:(BOOL)fp32;
-(BOOL)canBecomeKeyWindow;
-(BOOL)canBecomeMainWindow;
@end