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
#import "ProcessGroup.h"
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
  // Take 5 samples for CPU usage.
  [self sampleProcesses: 5];
  
  // Print the top processes.
  [self printTopProcesses: [self sortedProcessesByType: kCPUUsage]];
  }

// Print a top process.
- (BOOL) printTopProcessGroup: (ProcessGroup *) process
  {
  if([process.name isEqualToString: @"ps"])
    return NO;

  if([process.name isEqualToString: @"top"])
    return NO;
    
  if([process.name isEqualToString: @"EtreCheck"])
    return NO;
    
  NSString * countString =
    (process.count > 1)
      ? [NSString stringWithFormat: @"(%lu)", (unsigned long)process.count]
      : @"";

  NSString * usageString =
    [NSString stringWithFormat: @"%6.0lf%%", process.cpuUsage];
  
  NSString * printString =
    [usageString
      stringByPaddingToLength: 10 withString: @" " startingAtIndex: 0];
    
  NSString * output =
    [NSString
      stringWithFormat:
        @"    %@\t%@%@\n", printString, process.name, countString];

  if(process.cpuUsage > 50.0)
    [self.result
      appendString: output
      attributes:
        [NSDictionary
          dictionaryWithObjectsAndKeys:
            [NSColor redColor], NSForegroundColorAttributeName, nil]];      
  else
    [self.result appendString: output];

  process.reported = YES;

  [self.xml startElement: @"process"];
  
  [self.xml addElement: @"name" value: process.name];  
  [self.xml addElement: @"count" unsignedIntegerValue: process.count];
  [self.xml addElement: @"path" value: process.path];  
  [self.xml 
    addElement: @"usage" 
    value: [NSString stringWithFormat: @"%.0lf", round(process.cpuUsage)]
    attributes: 
      [NSDictionary 
        dictionaryWithObjectsAndKeys: 
          @"%", @"units", @"number", @"type", nil]];
  
  [self.xml endElement: @"process"];
  
  return YES;
  }

@end
