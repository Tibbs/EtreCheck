/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "ProcessAttributes.h"

// Encapsulate a running process.
@implementation ProcessAttributes

// The path to the process.
@synthesize path = myPath;

// The name of the process.
@synthesize name = myName;

// Is this an Apple app?
@synthesize apple = myApple;

// CPU usage.
@synthesize cpuUsage = myCpuUsage;

// Memory usage.
@synthesize memoryUsage = myMemoryUsage;

// Energy usage.
@synthesize energyUsage = myEnergyUsage;

// Network input usage.
@synthesize networkInputUsage = myNetworkInputUsage;

// Network output usage.
@synthesize networkOutputUsage = myNetworkOutputUsage;

// Destructor.
- (void) dealloc
  {
  [myPath release];
  [myName release];
  
  [super dealloc];
  }
        
// Get a value for a type.
- (double) valueForType: (int) type
  {
  switch(type)
    {
    case kCPUUsage:
      return self.cpuUsage;
      
    case kMemoryUsage:
      return self.memoryUsage;
      
    case kEnergyUsage:
      return self.energyUsage;
      
    case kNetworkInputUsage:
      return self.networkInputUsage;

    case kNetworkOutputUsage:
      return self.networkOutputUsage;

    case kNetworkUsage:
      return self.networkInputUsage + self.networkOutputUsage;
      
    default:
      break;
    }
    
  return 0.0;
  }

@end
