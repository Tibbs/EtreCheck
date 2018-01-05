/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "Collector.h"

// Collect install information.
@interface InstallCollector : Collector
  {
  // Install items.
  NSMutableArray * myInstalls;
  }

// Install items.
@property (readonly) NSMutableArray * installs;

@end
