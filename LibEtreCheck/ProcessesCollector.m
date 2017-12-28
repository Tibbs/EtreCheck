/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "ProcessesCollector.h"
#import "Model.h"
#import "Utilities.h"
#import "SubProcess.h"
#import "LocalizedString.h"
#import "NSNumber+Etresoft.h"
#import "NSDictionary+Etresoft.h"
#import "NSMutableDictionary+Etresoft.h"
#import "ProcessSnapshot.h"
#import "ProcessGroup.h"
#import "ByteCountFormatter.h"
#import "NSMutableAttributedString+Etresoft.h"

// Collect information about processes.
@implementation ProcessesCollector

@synthesize byteCountFormatter = myByteCountFormatter;

// Constructor.
- (id) initWithName: (NSString *) name
  {
  self = [super initWithName: name];
  
  if(self != nil)
    {
    myByteCountFormatter = [ByteCountFormatter new];

    myByteCountFormatter.k1000 = 1024.0;
    }
    
  return self;
  }

// Destructor.
- (void) dealloc
  {
  [myByteCountFormatter release];
  
  [super dealloc];
  }

// Collect the average CPU usage of all processes.
- (void) sampleProcesses: (int) count
  {
  for(NSUInteger i = 0; i < count; ++i)
    {
    usleep(500000);
    
    [self collectProcesses];   
    }
  }

// Collect running processes.
- (void) collectProcesses
  {
  NSArray * args = @[ @"-raxww", @"-o", @"pid, %cpu, rss, command" ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  NSString * key = @"ps";
  
  [subProcess loadDebugOutput: [self.model debugInputPath: key]];      
  [subProcess saveDebugOutput: [self.model debugOutputPath: key]];

  if([subProcess execute: @"/bin/ps" arguments: args])
    {
    NSArray * lines = [Utilities formatLines: subProcess.standardOutput];
    
    for(NSString * line in lines)
      {
      ProcessSnapshot * process = 
        [[ProcessSnapshot alloc] initWithPsLine: line];
      
      if(process != nil)
        [self.model 
          updateProcesses: process updates: kCPUUsage | kMemoryUsage];
        
      [process release];
      }
      
    // Don't forget the kernel.
    ProcessSnapshot * process = [self getKernelTask];

    if(process != nil)
      [self.model 
        updateProcesses: process updates: kCPUUsage | kMemoryUsage];
    }
    
  [subProcess release];
  }

// Record process information.
- (ProcessSnapshot *) getKernelTask
  {
  ProcessSnapshot * kernelTask = nil;
  
  NSArray * args = 
    @[@"-l", @"2", @"-stats", @"pid,cpu,rsize,power,command"];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  subProcess.usePseudoTerminal = YES;

  NSString * key = @"ps_kernel_task";
  
  [subProcess loadDebugOutput: [self.model debugInputPath: key]];      
  [subProcess saveDebugOutput: [self.model debugOutputPath: key]];

  if([subProcess execute: @"/usr/bin/top" arguments: args])
    {
    NSArray * lines = [Utilities formatLines: subProcess.standardOutput];
    
    int count = 0;
    
    for(NSString * line in lines)
      {
      if(![line hasPrefix: @"0 "])
        continue;

      if(count++ == 1)
        {
        kernelTask = [[ProcessSnapshot alloc] initWithTopLine: line];
        kernelTask.apple = YES;
        }
      }
    }
    
  [subProcess release];
  
  return [kernelTask autorelease];
  }

// Sort process names by some values measurement.
- (NSArray *) sortedProcessesByType: (int) type
  {
  NSMutableArray * sorted = 
    [[self.model.processesByPath allValues] mutableCopy];
  
  [sorted
    sortUsingComparator:
      ^(id obj1, id obj2)
        {
        ProcessGroup * process1 = (ProcessGroup *)obj1;
        ProcessGroup * process2 = (ProcessGroup *)obj2;

        double value1 = [process1 valueForType: type];
        double value2 = [process2 valueForType: type];
            
        if(value1 < value2)
          return (NSComparisonResult)NSOrderedDescending;
          
        if (value1 > value2)
          return (NSComparisonResult)NSOrderedAscending;

        return (NSComparisonResult)NSOrderedSame;
        }];
  
  return [sorted autorelease];
  }

// Print top processes by memory.
- (void) printTopProcesses: (NSArray *) processes
  {
  [self.result appendAttributedString: [self buildTitle]];
  
  NSUInteger count = 0;
  
  for(ProcessGroup * process in processes)
    {
    if([self printTopProcessGroup: process])
      ++count;
          
    if(count >= 5)
      break;
    }

  [self.result appendCR];
  }

// Print a top process.
- (BOOL) printTopProcessGroup: (ProcessGroup *) process
  {
  return NO;
  }
  
@end
