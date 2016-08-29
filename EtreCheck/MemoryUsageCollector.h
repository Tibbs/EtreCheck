/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "ProcessesCollector.h"

@class ByteCountFormatter;

// Collect information about memory usage.
@interface MemoryUsageCollector : ProcessesCollector
  {
  ByteCountFormatter * formatter;
  double pageouts;
  }

@end
