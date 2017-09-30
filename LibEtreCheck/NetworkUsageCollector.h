/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "ProcessesCollector.h"

// Collect information about network usage.
@interface NetworkUsageCollector : ProcessesCollector
  {
  NSDictionary * myProcessesByPID;
  }

@property (retain) NSDictionary * processesByPID;

@end
