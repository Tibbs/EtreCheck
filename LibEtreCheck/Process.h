/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "ProcessAttributes.h"

// Encapsulate a running process.
@interface Process : ProcessAttributes
  {
  // The command being run.
  NSString * myCommand;

  // The process ID.
  int myPID;

  // CPU usage sample count.
  int myCpuUsageSampleCount;
  
  // Energy usage sample count.
  int myEnergyUsageSampleCount;
  }
  
// The command being run.
@property (strong) NSString * command;

// The process ID.
@property (assign) int PID;

// CPU usage sample count.
@property (assign) int cpuUsageSampleCount;

// Energy usage sample count.
@property (assign) int energyUsageSampleCount;

// Update with new process attributes.
- (void) update: (ProcessAttributes *) processAttributes types: (int) types;

@end
