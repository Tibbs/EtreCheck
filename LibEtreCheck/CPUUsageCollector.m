/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014-2017. All rights reserved.
 **********************************************************************/

#import "CPUUsageCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "XMLBuilder.h"
#import "NSDictionary+Etresoft.h"
#import "NSNumber+Etresoft.h"
#import "NSString+Etresoft.h"
#import "RunningProcess.h"
#import "Model.h"

// Collect information about CPU usage.
@implementation CPUUsageCollector

// Constructor.
- (id) init
  {
  self = [super initWithName: @"cpu"];
  
  if(self)
    {
    }
    
  return self;
  }

// Perform the collection.
- (void) performCollect
  {
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
    
    for(NSString * pid in currentProcesses)
      {
      NSMutableDictionary * currentProcess =
        [currentProcesses objectForKey: pid];
      NSMutableDictionary * averageProcess =
        [averageProcesses objectForKey: pid];
        
      if([NSDictionary isValid: currentProcess])
        {
        if(![NSDictionary isValid: averageProcess])
          [averageProcesses setObject: currentProcess forKey: pid];
          
        else 
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
    NSNumber * cpuValue = [process objectForKey: @"cpu"];
    NSNumber * countValue = [process objectForKey: @"count"];
    NSString * name = [process objectForKey: @"command"];
    NSNumber * pid = [process objectForKey: @"pid"];
  
  if(![NSNumber isValid: pid])
    return;
    if(![NSNumber isValid: cpuValue] || ![NSNumber isValid: countValue])
      continue;
      
    if(![NSString isValid: name])
      continue;
      
    double cpu = [cpuValue doubleValue];

    int count = [countValue intValue];
    
    NSString * countString =
      (count > 1)
        ? [NSString stringWithFormat: @"(%d)", count]
        : @"";

    NSString * usageString =
      [NSString stringWithFormat: @"%6.0lf%%", cpu];
    
    NSString * printString =
      [usageString
        stringByPaddingToLength: 10 withString: @" " startingAtIndex: 0];

    [self.xml startElement: @"process"];
    
    [self.xml 
      addElement: @"usage" 
      value: [NSString stringWithFormat: @"%.0lf", cpu]
      attributes: 
        [NSDictionary 
          dictionaryWithObjectsAndKeys: 
            @"%", @"units", @"number", @"type", nil]];
        
    [self.xml addElement: @"name" value: name];
    [self.xml addElement: @"count" intValue: count];
    [self.xml addElement: @"PID" number: pid];
    
    [self.xml endElement: @"process"];
    
    NSString * output =
      [NSString
        stringWithFormat:
          @"    %@\t%@%@\n", printString, name, countString];
      
    if(cpu > 50.0)
      [self.result
        appendString: output
        attributes:
          [NSDictionary
            dictionaryWithObjectsAndKeys:
              [NSColor redColor], NSForegroundColorAttributeName, nil]];      
    else
      [self.result appendString: output];
          

    RunningProcess * runningProcess = 
      [self.model.runningProcesses objectForKey: pid];
      
    runningProcess.reported = YES;

    ++topCount;
          
    if(cpu == 0.0)
      topCount = 10;
    
    if(topCount >= 5)
      break;
    }
  }

@end
