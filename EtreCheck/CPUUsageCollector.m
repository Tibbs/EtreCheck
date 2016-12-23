/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "CPUUsageCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "XMLBuilder.h"

// Collect information about CPU usage.
@implementation CPUUsageCollector

// Constructor.
- (id) init
  {
  self = [super initWithName: @"cpu"];
  
  if(self)
    {
    return self;
    }
    
  return nil;
  }

// Perform the collection.
- (void) performCollection
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

    [self.XML startElement: @"process"];
    
    if(cpu > 50.0)
      {
      [self.XML addAttribute: @"severity" value: @"warning"];
      [self.XML
        addAttribute: @"severity_explanation" value: @"highcpuusage"];
      }
      
    [self.XML
      addElement: @"name"
      value: [process objectForKey: @"command"]];
    [self.XML
      addElement: @"cpu"
      number: [process objectForKey: @"cpu"]];
    [self.XML
      addElement: @"count"
      number: [process objectForKey: @"count"]];
    
    [self.XML endElement: @"process"];
    
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
