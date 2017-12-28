/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "Collector.h"

@class Process;
@class ProcessGroup;
@class ByteCountFormatter;

// Collect information about processes.
@interface ProcessesCollector : Collector
  {
  ByteCountFormatter * myByteCountFormatter;
  }

@property (readonly) ByteCountFormatter * byteCountFormatter;

// Collect the average CPU usage of all processes.
- (void) sampleProcesses: (int) count;

// Collect running processes.
- (void) collectProcesses;

// Sort process names by some values measurement.
- (NSArray *) sortedProcessesByType: (int) type;

// Print top processes by memory.
- (void) printTopProcesses: (NSArray *) processes;

// Print a top process.
- (BOOL) printTopProcessGroup: (ProcessGroup *) process;

@end
