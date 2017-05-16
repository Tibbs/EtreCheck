/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "MemoryUsageCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "ByteCountFormatter.h"
#import "Model.h"

// Collect information about memory usage.
@implementation MemoryUsageCollector

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    self.name = @"memory";
    self.title = NSLocalizedStringFromTable(self.name, @"Collectors", NULL);
    }
    
  return self;
  }

// Perform the collection.
- (void) collect
  {
  [self
    updateStatus:
      NSLocalizedString(@"Sampling processes for memory", NULL)];

  // Collect the average memory usage usage for all processes (5 times).
  NSDictionary * avgMemory = [self collectAverageMemory];
  
  // Sort the result by average value.
  NSArray * processesMemory = [self sortProcesses: avgMemory by: @"mem"];
  
  // Print the top processes.
  [self printTopProcesses: processesMemory];
    
  dispatch_semaphore_signal(self.complete);
  }

// Collect the average CPU usage of all processes.
- (NSDictionary *) collectAverageMemory
  {
  NSMutableDictionary * averageProcesses = [NSMutableDictionary dictionary];
  
  for(NSUInteger i = 0; i < 5; ++i)
    {
    usleep(500000);
    
    NSDictionary * currentProcesses = [self collectProcesses];
    
    for(NSString * command in currentProcesses)
      {
      NSMutableDictionary * currentProcess =
        [currentProcesses objectForKey: command];
      NSMutableDictionary * averageProcess =
        [averageProcesses objectForKey: command];
        
      if(!averageProcess)
        [averageProcesses setObject: currentProcess forKey: command];
        
      else if(currentProcess && averageProcess)
        {
        double totalMemory =
          [[averageProcess objectForKey: @"mem"] doubleValue] * i;
        
        double averageMemory =
          [[currentProcess objectForKey: @"mem"] doubleValue];
        
        averageMemory = (totalMemory + averageMemory) / (double)(i + 1);
        
        [averageProcess
          setObject: [NSNumber numberWithDouble: averageMemory]
          forKey: @"mem"];
        }
      }
    }
  
  return averageProcesses;
  }

// Print top processes by memory.
- (void) printTopProcesses: (NSArray *) processes
  {
  [self.result appendAttributedString: [self buildTitle]];
  
  NSUInteger count = 0;
  
  ByteCountFormatter * formatter = [[ByteCountFormatter alloc] init];

  formatter.k1000 = 1024.0;
  
  for(NSDictionary * process in processes)
    {
    [self printTopProcess: process formatter: formatter];
    
    ++count;
          
    if(count >= 5)
      break;
    }

  [self.result appendCR];
  
  [formatter release];
  }

// Print a top process.
- (void) printTopProcess: (NSDictionary *) process
  formatter: (ByteCountFormatter *) formatter
  {
  double value = [[process objectForKey: @"mem"] doubleValue];

  int count = [[process objectForKey: @"count"] intValue];
  
  NSString * countString =
    (count > 1)
      ? [NSString stringWithFormat: @"(%d)", count]
      : @"";

  NSString * memoryString =
    [formatter stringFromByteCount: (unsigned long long)value];
  
  NSString * printString =
    [memoryString
      stringByPaddingToLength: 10 withString: @" " startingAtIndex: 0];

  NSString * name = [process objectForKey: @"command"];
  
  if([name length] == 0)
    name = NSLocalizedString(@"Unknown", NULL);
    
  NSString * output =
    [NSString
      stringWithFormat: @"    %@\t%@%@\n", printString, name, countString];
    
  BOOL excessiveRAM = NO;
  
  double gb = 1024 * 1024 * 1024;
  
  if([name isEqualToString: @"kernel_task"])
    excessiveRAM = value > ([[Model model] physicalRAM]  * gb * .2);
  else
    excessiveRAM = value > (gb * 2.0);
    
  if(excessiveRAM)
    [self.result
      appendString: output
      attributes:
        [NSDictionary
          dictionaryWithObjectsAndKeys:
            [NSColor redColor], NSForegroundColorAttributeName, nil]];      
  else
    [self.result appendString: output];
  }

@end
