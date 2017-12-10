/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014-2017. All rights reserved.
 **********************************************************************/

#import "MemoryUsageCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "ByteCountFormatter.h"
#import "Model.h"
#import "XMLBuilder.h"
#import "LocalizedString.h"
#import "NSMutableDictionary+Etresoft.h"
#import "NSNumber+Etresoft.h"
#import "NSString+Etresoft.h"

// Collect information about memory usage.
@implementation MemoryUsageCollector

// Constructor.
- (id) init
  {
  self = [super initWithName: @"memory"];
  
  if(self != nil)
    {
    }
    
  return self;
  }

// Perform the collection.
- (void) performCollect
  {
  // Collect the average memory usage usage for all processes (5 times).
  NSDictionary * avgMemory = [self collectAverageMemory];
  
  // Sort the result by average value.
  NSArray * processesMemory = [self sortProcesses: avgMemory by: @"mem"];
  
  // Print the top processes.
  [self printTopProcesses: processesMemory];
  }

// Collect the average CPU usage of all processes.
- (NSDictionary *) collectAverageMemory
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
        
      if([NSMutableDictionary isValid: currentProcess])
        {
        if(![NSMutableDictionary isValid: averageProcess])
          [averageProcesses setObject: currentProcess forKey: pid];
          
        else 
          {
          NSNumber * averageMem = [averageProcess objectForKey: @"mem"];
          NSNumber * currentMem = [currentProcess objectForKey: @"mem"];
          
          if([NSNumber isValid: averageMem])
            if([NSNumber isValid: currentMem])
              {
              double totalMemory = [averageMem doubleValue] * i;
              
              double averageMemory = [currentMem doubleValue];
              
              averageMemory = 
                (totalMemory + averageMemory) / (double)(i + 1);
              
              NSNumber * memory = 
                [[NSNumber alloc] initWithDouble: averageMemory];
              
              [averageProcess setObject: memory forKey: @"mem"];
              
              [memory release];
              }
          }
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
  NSNumber * processMem = [process objectForKey: @"mem"];
  
  if(![NSNumber isValid: processMem])
    return;
    
  double value = [processMem doubleValue];

  NSNumber * processCount = [process objectForKey: @"count"];
  
  if(![NSNumber isValid: processCount])
    return;
    
  int count = [processCount intValue];
  
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
  
  if(![NSString isValid: name])
    name = ECLocalizedString(@"Unknown");
    
  [self.xml startElement: @"process"];
  
  [self.xml addElement: @"size" valueWithUnits: memoryString];
  [self.xml addElement: @"name" value: name];
  [self.xml addElement: @"count" intValue: count];
  
  [self.xml endElement: @"process"];

  NSString * output =
    [NSString
      stringWithFormat: @"    %@\t%@%@\n", printString, name, countString];
    
  BOOL excessiveRAM = NO;
  
  double gb = 1024 * 1024 * 1024;
  
  if([name isEqualToString: @"kernel_task"])
    excessiveRAM = value > ([self.model physicalRAM]  * gb * .2);
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
