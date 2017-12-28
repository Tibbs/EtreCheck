/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014-2017. All rights reserved.
 **********************************************************************/

#import "NetworkUsageCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "ByteCountFormatter.h"
#import "SubProcess.h"
#import "Utilities.h"
#import "Model.h"
#import "NumberFormatter.h"
#import "XMLBuilder.h"
#import "LocalizedString.h"
#import "EtreCheckConstants.h"
#import "OSVersion.h"
#import "NSNumber+Etresoft.h"
#import "NSDictionary+Etresoft.h"
#import "NSString+Etresoft.h"
#import "ProcessSnapshot.h"
#import "Process.h"
#import "ProcessGroup.h"

// Collect information about network usage.
@implementation NetworkUsageCollector

// Constructor.
- (id) init
  {
  self = [super initWithName: @"networkusage"];
  
  if(self != nil)
    {
    }
    
  return self;
  }

// Perform the collection.
- (void) performCollect
  {
  if([[OSVersion shared] major] >= kSierra)
    {
    // I only need a single sample for network usage.
    [self sampleProcesses: 1];
    
    // Print the top processes.
    [self printTopProcesses: [self sortedProcessesByType: kNetworkUsage]];
    }
  }

// Collect running processes.
- (void) collectProcesses
  {
  NSArray * args =
    @[
      @"-Px",
      @"-k",
      @"interface,state,rx_ooo,rx_dupe,re-tx,rtt_avg,rcvsize,tx_win,tc_class,tc_mgt,cc_algo,P,C,R,W",
      @"-l",
      @"1",
      @"-t",
      @"external"
    ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  NSString * key = @"nettop";
  
  [subProcess loadDebugOutput: [self.model debugInputPath: key]];      
  [subProcess saveDebugOutput: [self.model debugOutputPath: key]];

  if([subProcess execute: @"/usr/bin/nettop" arguments: args])
    {
    NSArray * lines = [Utilities formatLines: subProcess.standardOutput];
    
    for(NSString * line in lines)
      {
      ProcessSnapshot * process = 
        [[ProcessSnapshot alloc] initWithNettopLine: line];
      
      if(process != nil)
        [self.model updateProcesses: process updates: kNetworkUsage];
        
      [process release];
      }
    }
    
  [subProcess release];
  }

// Sort process names by some values measurement.
- (NSArray *) sortedProcessesByType: (int) type
  {
  NSMutableArray * sorted = 
    [[self.model.processesByPID allValues] mutableCopy];
  
  [sorted
    sortUsingComparator:
      ^(id obj1, id obj2)
        {
        Process * process1 = (Process *)obj1;
        Process * process2 = (Process *)obj2;

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
  
  [self.result
    appendString:
      [NSString
        stringWithFormat:
          @"    %@\t%@\t%@\n",
          ECLocalizedString(@"Input     "),
          ECLocalizedString(@"Output    "),
          ECLocalizedString(@"Process name")]
    attributes:
      @{ NSFontAttributeName : [[Utilities shared] boldFont] }];

  NSUInteger count = 0;
  
  for(Process * process in processes)
    {
    [self printTopProcess: process];
    
    ++count;
          
    if(count >= 5)
      break;
    }

  [self.result appendCR];
  }

// Print a top process.
- (BOOL) printTopProcess: (Process *) process
  {
  if([process.name isEqualToString: @"nettop"])
    return NO;
    
  if([process.name isEqualToString: @"EtreCheck"])
    return NO;
    
  NSString * bytesInString =
    [self.byteCountFormatter 
      stringFromByteCount: (unsigned long long)process.networkInputUsage];

  NSString * bytesOutString =
    [self.byteCountFormatter 
      stringFromByteCount: (unsigned long long)process.networkOutputUsage];
  
  NSString * printBytesInString =
    [bytesInString
      stringByPaddingToLength: 10 withString: @" " startingAtIndex: 0];

  NSString * printBytesOutString =
    [bytesOutString
      stringByPaddingToLength: 10 withString: @" " startingAtIndex: 0];
  
  [self.result
    appendString:
      [NSString
        stringWithFormat:
          @"    %@\t%@\t%@\n",
          process.name,
          printBytesInString,
          printBytesOutString]];

  ProcessGroup * processGroup = 
    [self.model.processesByPath objectForKey: process.path];
  
  processGroup.reported = YES;

  [self.xml startElement: @"process"];
  
  [self.xml addElement: @"name" value: process.name];
  [self.xml addElement: @"path" value: process.path];  
  [self.xml addElement: @"inputsize" valueWithUnits: bytesInString];
  [self.xml addElement: @"outputsize" valueWithUnits: bytesOutString];
  
  [self.xml endElement: @"process"];
  
  return YES;
  }

@end
