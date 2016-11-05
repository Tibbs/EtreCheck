/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "Collector.h"

// Collect information about processes.
@interface ProcessesCollector : Collector

// Collect running processes.
- (NSMutableDictionary *) collectProcesses;

// Sort process names by some values measurement.
- (NSArray *) sortProcesses: (NSDictionary *) processes
  by: (NSString *) key;

@end
