/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "ProcessesCollector.h"

// Collect information about energy usage.
@interface EnergyUsageCollector : ProcessesCollector
  {
  NSDictionary * myProcessesByPID;
  }

@property (retain) NSDictionary * processesByPID;

@end
