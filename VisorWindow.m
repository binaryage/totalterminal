//
//  VisorWindow.m
//  Visor
//
//  Created by Nicholas Jitkoff on 6/1/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "VisorWindow.h"
#import "Visor.h"

@implementation TTWindow (Visor)

- (id) initWithContentRect: (NSRect) contentRect
                 styleMask: (unsigned int) aStyle
                   backing: (NSBackingStoreType) bufferingType
                     defer: (BOOL) flag
{
    NSLog(@"Creating new terminal window");
    Visor* visor = [Visor sharedInstance];
    BOOL shouldBeVisorized = ![visor status];
    if (shouldBeVisorized) {
        aStyle =  NSBorderlessWindowMask;
        bufferingType = NSBackingStoreBuffered;
    }
    self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag];
    if (shouldBeVisorized) {
        [visor adoptTerminal:self];
    }
    return self;
}

-(BOOL)canBecomeKeyWindow{return YES;}
-(BOOL)canBecomeMainWindow{return YES;}

@end