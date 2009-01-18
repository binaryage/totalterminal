//
//  VisorWindow.m
//  Visor
//
//  Created by Nicholas Jitkoff on 6/1/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "VisorWindow.h"

BOOL firstTime = YES;

@implementation TTWindow (VisorController)

- (id) initWithContentRect: (NSRect) contentRect
                 styleMask: (unsigned int) aStyle
                   backing: (NSBackingStoreType) bufferingType
                     defer: (BOOL) flag
{
    if (firstTime) {
        firstTime = NO;
        aStyle =  NSBorderlessWindowMask|NSNonactivatingPanelMask;
        bufferingType = NSBackingStoreBuffered;
        flag = NO;
    }
    self = [super initWithContentRect: contentRect styleMask: aStyle backing: bufferingType defer: flag];
    return self;
}

-(BOOL)canBecomeKeyWindow{return YES;}
-(BOOL)canBecomeMainWindow{return YES;}

@end