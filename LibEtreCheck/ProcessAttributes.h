/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

// An enum for accumulating process values.
typedef enum ProcessValueType
  {
  kCPUUsage           = 0x01,
  kMemoryUsage        = 0x02,
  kEnergyUsage        = 0x04,
  kNetworkInputUsage  = 0x08,
  kNetworkOutputUsage = 0x10,
  kNetworkUsage       = 0x18
  }
ProcessValueType;

// Encapsulate attributes about a process.
@interface ProcessAttributes : NSObject
  {
  // The path to the process.
  NSString * myPath;
  
  // The process name.
  NSString * myName;
  
  // Is this an Apple app?
  BOOL myApple;
  
  // CPU usage.
  double myCpuUsage;
  
  // Memory usage.
  double myMemoryUsage;
  
  // Energy usage.
  double myEnergyUsage;

  // Network input usage.
  double myNetworkInputUsage;
  
  // Network output usage.
  double myNetworkOutputUsage;
  }
  
// The resolved path.
@property (strong) NSString * path;

// The process name.
@property (strong) NSString * name;

// Is this an Apple app?
@property (assign) BOOL apple;

// CPU usage.
@property (assign) double cpuUsage;

// Memory usage.
@property (assign) double memoryUsage;

// Energy usage.
@property (assign) double energyUsage;

// Network input usage.
@property (assign) double networkInputUsage;

// Network output usage.
@property (assign) double networkOutputUsage;

// Get a value for a type.
- (double) valueForType: (int) type;

@end
