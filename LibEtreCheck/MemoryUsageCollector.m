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
#import "ProcessGroup.h"

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
  // I only need a single sample for memory usage.
  [self sampleProcesses: 1];
  
  // Print the top processes.
  [self printTopProcesses: [self sortedProcessesByType: kMemoryUsage]];
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

  NSString * memoryString =
    [self.byteCountFormatter 
      stringFromByteCount: (unsigned long long)process.memoryUsage];
  
  NSString * printString =
    [memoryString
      stringByPaddingToLength: 10 withString: @" " startingAtIndex: 0];

  NSString * output =
    [NSString
      stringWithFormat: 
        @"    %@\t%@%@\n", printString, process.name, countString];
    
  BOOL excessiveRAM = NO;
  
  double gb = 1024 * 1024 * 1024;
  
  if([process.name isEqualToString: @"kernel_task"])
    excessiveRAM = 
      process.memoryUsage > ([self.model physicalRAM]  * gb * .2);
  else
    excessiveRAM = process.memoryUsage > (gb * 2.0);
    
  if(excessiveRAM)
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
  [self.xml addElement: @"size" valueWithUnits: memoryString];
  
  [self.xml endElement: @"process"];
  
  return YES;
  }

@end
