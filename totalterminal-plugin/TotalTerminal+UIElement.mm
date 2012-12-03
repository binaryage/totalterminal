//
// TotalTerminal+UIElement.mm
// TotalTerminal
//
// Created by Brian K Garrett on 11/30/12.
// Copyright (c) 2012 BinaryAge. All rights reserved.
//

#import "TotalTerminal+UIElement.h"

@implementation TotalTerminal (UIElement)

-(BOOL) isUIElement {
  return ([[NSRunningApplication currentApplication] activationPolicy] == NSApplicationActivationPolicyAccessory) ? YES : NO;
}

-(void) updateUIElement {
  BOOL hideDockIcon = [[NSUserDefaults standardUserDefaults] boolForKey:@"TotalTerminalHideDockIcon"];
  NSApplicationActivationPolicy policy = [[NSRunningApplication currentApplication] activationPolicy];
  ProcessSerialNumber psn = {
    0, kCurrentProcess
  };

  if (policy == NSApplicationActivationPolicyRegular) {
    if (hideDockIcon) {
      TransformProcessType(&psn, kProcessTransformToUIElementApplication);
    }
  } else if (policy == NSApplicationActivationPolicyAccessory) {
    if (!hideDockIcon) {
      TransformProcessType(&psn, kProcessTransformToForegroundApplication);
    }
  } else {
    // Terminal is running as NSApplicationActivationPolicyProhibited
    // and is a background daemon for some reason
    return;
  }
}

@end
