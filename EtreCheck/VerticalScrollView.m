/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2016-2017. All rights reserved.
 **********************************************************************/

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
