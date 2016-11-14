/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "Collector.h"

@class ByteCountFormatter;

// Collect virtual memory information.
@interface VirtualMemoryCollector : Collector
  {
  ByteCountFormatter * formatter;
  double pageouts;
  }

@end
