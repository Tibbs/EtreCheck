/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "Collector.h"

@class ByteCountFormatter;

// Collect memory usage information.
@interface MemoryUsageCollector : Collector
  {
  ByteCountFormatter * formatter;
  double pageouts;
  }

@end
