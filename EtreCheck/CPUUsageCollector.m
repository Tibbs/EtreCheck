/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "CPUUsageCollector.h"
#import "NSMutableAttributedString+Etresoft.h"

// Collect information about CPU usage.
@implementation CPUUsageCollector

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    self.name = @"cpu";
    self.title = NSLocalizedStringFromTable(self.name, @"Collectors", NULL);
    }
    
  return self;
  }

// Perform the collection.
- (void) collect
  {
  [self
    updateStatus: NSLocalizedString(@"Sampling processes for CPU", NULL)];

  // Collect the average CPU usage for all processes (5 times).
  NSDictionary * avgCPU = [self collectAverageCPU];
  
  // Sort the result by average value.
  NSArray * processesCPU = [self sortProcesses: avgCPU by: @"cpu"];
  
  // Print the top processes.
  [self printTopProcesses: processesCPU];
  
  [self.result appendCR];
    
  dispatch_semaphore_signal(self.complete);
  }

// Collect the average CPU usage of all processes.
- (NSDictionary *) collectAverageCPU
  {
  NSMutableDictionary * averageProcesses = [NSMutableDictionary dictionary];
  
  for(NSUInteger i = 0; i < 5; ++i)
    {
    usleep(500000);
    
    NSDictionary * currentProcesses = [self collectProcesses];
    
    for(NSString * pid in currentProcesses)
      {
      NSMutableDictionary * currentProcess =
        [currentProcesses objectForKey: pid];
      NSMutableDictionary * averageProcess =
        [averageProcesses objectForKey: pid];
        
      if(!averageProcess)
        [averageProcesses setObject: currentProcess forKey: pid];
        
      else if(currentProcess && averageProcess)
        {
        double totalCPU =
          [[averageProcess objectForKey: @"cpu"] doubleValue] * i;
        
        double averageCPU =
          [[currentProcess objectForKey: @"cpu"] doubleValue];
        
        averageCPU = (totalCPU + averageCPU) / (double)(i + 1);
        
        [averageProcess
          setObject: [NSNumber numberWithDouble: averageCPU]
          forKey: @"cpu"];
        }
      }
    }
  
  return averageProcesses;
  }

// Print top processes by CPU.
- (void) printTopProcesses: (NSArray *) processes
  {
  [self.result appendAttributedString: [self buildTitle]];
  
  NSUInteger topCount = 0;
  
  for(NSDictionary * process in processes)
    {
    double cpu = [[process objectForKey: @"cpu"] doubleValue];

    int count = [[process objectForKey: @"count"] intValue];
    
    NSString * countString =
      (count > 1)
        ? [NSString stringWithFormat: @"(%d)", count]
        : @"";

    NSString * usageString =
      [NSString stringWithFormat: @"%6.0lf%%", cpu];
    
    NSString * printString =
      [usageString
        stringByPaddingToLength: 10 withString: @" " startingAtIndex: 0];

    NSString * output =
      [NSString
        stringWithFormat:
          @"    %@\t%@%@\n",
          printString,
          [process objectForKey: @"command"],
          countString];
      
    if(cpu > 50.0)
      [self.result
        appendString: output
        attributes:
          [NSDictionary
            dictionaryWithObjectsAndKeys:
              [NSColor redColor], NSForegroundColorAttributeName, nil]];      
    else
      [self.result appendString: output];
          
    ++topCount;
          
    if(cpu == 0.0)
      topCount = 10;
    
    if(topCount >= 5)
      break;
    }
  }

@end
