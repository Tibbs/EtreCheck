/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "ProcessGroup.h"
#import "ProcessAttributes.h"

// Encapsulate a running process.
@implementation ProcessGroup

// Was this app reported on an EtreCheck report?
@synthesize reported = myReported;

// How many processes are included?
@dynamic count;
      
// The processes in this group.
@synthesize processes = myProcesses;

- (NSUInteger) count
  {
  return self.processes.count;
  }
  
// Constructor with process attributes.
- (instancetype) initWithProcessAttributes: 
  (ProcessAttributes *) processAttributes
  {
  self = [super init];
  
  if(self != nil)
    {
    self.path = processAttributes.path;
    self.name = processAttributes.name;
    self.cpuUsage = processAttributes.cpuUsage;
    self.memoryUsage = processAttributes.memoryUsage;
    self.energyUsage = processAttributes.energyUsage;
    self.networkInputUsage = processAttributes.networkInputUsage;
    self.networkOutputUsage = processAttributes.networkOutputUsage;
    self.apple = processAttributes.apple;
    
    myProcesses = [NSMutableSet new];
    
    [myProcesses addObject: processAttributes];
    
    return self;
    }
    
  return nil;
  }
  
// Destructor.
- (void) dealloc
  {
  [myProcesses release];
  
  [super dealloc];
  }
  
// Update with new process attributes.
- (void) update: (ProcessAttributes *) processAttributes types: (int) types
  {
  [myProcesses addObject: processAttributes];
  
  if(types & kCPUUsage)
    self.cpuUsage = 0.0;
    
  if(types & kMemoryUsage)
    self.memoryUsage = 0.0;
    
  if(types & kEnergyUsage)
    self.energyUsage = 0.0;
    
  // This is an accumulator.
  if(types & kNetworkUsage)
    {
    self.networkInputUsage = 0.0;
    self.networkOutputUsage = 0.0;
    }

  for(ProcessAttributes * process in self.processes)
    {
    if(types & kCPUUsage)
      self.cpuUsage += process.cpuUsage;
      
    if(types & kMemoryUsage)
      self.memoryUsage += process.memoryUsage;
      
    if(types & kEnergyUsage)
      self.energyUsage += process.energyUsage;
      
    // This is an accumulator.
    if(types & kNetworkUsage)
      {
      self.networkInputUsage += process.networkInputUsage;
      self.networkOutputUsage += process.networkOutputUsage;
      }
    }
  }

@end
