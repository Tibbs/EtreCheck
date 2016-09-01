/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "Collector.h"

@class ByteCountFormatter;

// Collect information about memory usage.
@interface MemoryUsageCollector : Collector
  {
  ByteCountFormatter * formatter;
  double pageouts;
  }

@end
