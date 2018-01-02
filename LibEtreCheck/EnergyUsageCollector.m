/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014-2017. All rights reserved.
 **********************************************************************/

#import "EnergyUsageCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "SubProcess.h"
#import "Utilities.h"
#import "Model.h"
#import "XMLBuilder.h"
#import "LocalizedString.h"
#import "EtreCheckConstants.h"
#import "OSVersion.h"
#import "NSDictionary+Etresoft.h"
#import "NSNumber+Etresoft.h"
#import "NSString+Etresoft.h"
#import "ProcessSnapshot.h"
#import "ProcessGroup.h"

// Collect information about energy usage.
@implementation EnergyUsageCollector

// Constructor.
- (id) init
  {
  self = [super initWithName: @"energy"];
  
  if(self != nil)
    {
    }
    
  return self;
  }

// Perform the collection.
- (void) performCollect
  {
  if([[OSVersion shared] major] >= kMavericks)
    {
    // Take 5 samples for energy usage.
    [self sampleProcesses: 5];
    
    // Print the top processes.
    [self printTopProcesses: [self sortedProcessesByType: kEnergyUsage]];
    }
  }

// Collect running processes.
- (void) collectProcesses
  {
  NSArray * args = 
    @[@"-l", @"2", @"-stats", @"pid,cpu,rsize,power,command"];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  subProcess.usePseudoTerminal = YES;

  NSString * key = @"top_power";
  
  [subProcess loadDebugOutput: [self.model debugInputPath: key]];      
  [subProcess saveDebugOutput: [self.model debugOutputPath: key]];

  if([subProcess execute: @"/usr/bin/top" arguments: args])
    {
    NSArray * lines = [Utilities formatLines: subProcess.standardOutput];
    
    for(NSString * line in lines)
      {
      ProcessSnapshot * process = 
        [[ProcessSnapshot alloc] initWithTopLine: line];
      
      if(process != nil)
        [self.model 
          updateProcesses: process 
          updates: kCPUUsage | kMemoryUsage | kEnergyUsage];
        
      [process release];
      }
    }
    
  [subProcess release];
  }

// Print a top process.
- (BOOL) printTopProcessGroup: (ProcessGroup *) process
  {
  if([process.name isEqualToString: @"top"])
    return NO;
    
  if([process.name isEqualToString: @"EtreCheck"])
    return NO;
    
  NSString * energyString = 
    [[NSString alloc] initWithFormat: @"%6.2f", process.energyUsage];

  NSString * printString =
    [energyString
      stringByPaddingToLength: 10 withString: @" " startingAtIndex: 0];

  if(process.energyUsage > 100.0)
    [self.result
      appendString:
        [NSString
          stringWithFormat:
            @"    %@\t%@\n",
            printString,
            process.name]
        attributes:
          [NSDictionary
            dictionaryWithObjectsAndKeys:
              [NSColor redColor], NSForegroundColorAttributeName, nil]];
  else
    [self.result
      appendString:
        [NSString
          stringWithFormat:
            @"    %@\t%@\n",
            printString,
            process.name]];
         
  [energyString release];
  
  process.reported = YES;

  [self.xml startElement: @"process"];
  
  [self.xml addElement: @"name" value: process.name];
  [self.xml addElement: @"count" unsignedIntegerValue: process.count];
  [self.xml addElement: @"path" value: process.path];  
  [self.xml 
    addElement: @"energy" intValue: (int)round(process.energyUsage)];    
  
  [self.xml endElement: @"process"];
  
  return YES;
  }

@end
