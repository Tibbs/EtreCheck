//
//  VerticalScrollView.m
//  EtreCheck
//
//  Created by John Daniel on 2016-10-27.
//  Copyright © 2016 Etresoft. All rights reserved.
//

#import "VerticalScrollView.h"

@implementation VerticalScrollView

- (void) scrollWheel: (NSEvent *) theEvent
  {
  CGEventRef cgEvent = CGEventCreateCopy(theEvent.CGEvent);
  
  CGEventSetIntegerValueField(cgEvent, kCGScrollWheelEventDeltaAxis2, 0);

  NSEvent * newEvent = [NSEvent eventWithCGEvent: cgEvent];
  
  [super scrollWheel: newEvent];

  CFRelease(cgEvent);
  }

@end
