/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "Collector.h"

// Collect system software information.
@interface SystemSoftwareCollector : Collector
  {
  // System load 15 minutes ago.
  NSString * myLoad15;

  // System load 5 minutes ago.
  NSString * myLoad5;

  // System load 1 minute ago.
  NSString * myLoad1;
  }
  
// System load 15 minutes ago.
@property (readonly) NSString * load15;

// System load 5 minutes ago.
@property (readonly) NSString * load5;

// System load 1 minute ago.
@property (readonly) NSString * load1;

@end
