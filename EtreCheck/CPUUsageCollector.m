/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "CPUUsageCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import <stdlib.h>
#import "Model.h"

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
  [self updateStatus: NSLocalizedString(@"Collecting CPU usage", NULL)];

  [self.result appendAttributedString: [self buildTitle]];
  
  [self printLoad];
  
  if(![[Model model] sandboxed])
    {
    [self.result appendString: @"\n"];
    
    // Collect the average CPU usage for all processes (5 times).
    NSDictionary * avgCPU = [self collectAverageCPU];
    
    // Sort the result by average value.
    NSArray * processesCPU = [self sortProcesses: avgCPU by: @"cpu"];
    
    // Print the top processes.
    [self printTopProcesses: processesCPU];
    }
    
  [self.result appendCR];
    
  dispatch_semaphore_signal(self.complete);
  }

// Print system load.
- (void) printLoad
  {
  double loads[3];
  
  int result = getloadavg(loads, 3);
  
  NSArray * labels =
    [NSArray
      arrayWithObjects:
        NSLocalizedString(@"Current system load", NULL),
        NSLocalizedString(@"System load for past 5 minutes", NULL),
        NSLocalizedString(@"System load for past 15 minutes", NULL),
        nil];
    
  if(result != -1)
    for(int index = 0; index < 3; ++index)
      {
      double load = loads[index] / (double)[[Model model] coreCount] * 100;
      
      NSString * output =
        [NSString
          stringWithFormat:
            @"    %4.0lf%%\t%@\n",
            load,
            [labels objectAtIndex: index]];
        
      if(load > 80.0)
        [self.result
          appendString: output
          attributes:
            [NSDictionary
              dictionaryWithObjectsAndKeys:
                [NSColor redColor], NSForegroundColorAttributeName, nil]];      
      else
        [self.result appendString: output];
            
      }
  }

// Collect the average CPU usage of all processes.
- (NSDictionary *) collectAverageCPU
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
        double totalCPU =
          [[averageProcess objectForKey: @"cpu"] doubleValue] * i;
        
        double averageCPU =
          [[averageProcess objectForKey: @"cpu"] doubleValue];
        
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
  NSUInteger topCount = 0;
  
  for(NSDictionary * process in processes)
    {
    double cpu = [[process objectForKey: @"cpu"] doubleValue];

    int count = [[process objectForKey: @"count"] intValue];
    
    NSString * countString =
      (count > 1)
        ? [NSString stringWithFormat: @"(%d)", count]
        : @"";

    NSString * output =
      [NSString
        stringWithFormat:
          @"    %6.0lf%%    %@%@\n",
          cpu,
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
