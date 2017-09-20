/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "Collector.h"

// Collect installed applications.
@interface ApplicationsCollector : Collector
  {
  NSImage * genericApplication;
  }

// Get the application icons.
- (NSArray *) applicationIcons;

@end
