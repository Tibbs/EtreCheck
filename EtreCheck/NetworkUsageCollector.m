/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "NetworkUsageCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "ByteCountFormatter.h"
#import "SubProcess.h"
#import "Utilities.h"
#import "Model.h"

// Collect information about network usage.
@implementation NetworkUsageCollector

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    self.name = @"network";
    self.title = NSLocalizedStringFromTable(self.name, @"Collectors", NULL);
    }
    
  return self;
  }

// Perform the collection.
- (void) collect
  {
  int version = [[Model model] majorOSVersion];

  if(version >= kSierra)
    {
    [self
      updateStatus:
        NSLocalizedString(@"Sampling processes for network usage", NULL)];

    // Collect the average memory usage usage for all processes (5 times).
    NSArray * processes = [self collectNetwork];
    
    // Print the top processes.
    [self printTopProcesses: processes];
    }

  dispatch_semaphore_signal(self.complete);
  }

// Collect processes' network usage.
- (NSArray *) collectNetwork
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
  
  NSMutableArray * processes = [NSMutableArray array];
    
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  if([subProcess execute: @"/usr/bin/nettop" arguments: args])
    {
    NSArray * lines = [Utilities formatLines: subProcess.standardOutput];
    
    for(NSString * line in lines)
      {
      if([line hasPrefix: @"STAT"])
        continue;

      NSDictionary * process = [self parseNetTop: line];

      if(!process)
        continue;
        
      [processes addObject: process];
      }
    }
    
  [subProcess release];
  
  [self sortProcesses: processes];
    
  return processes;
  }

// Sort the processes.
- (void) sortProcesses: (NSMutableArray *) processes
  {
  [processes
    sortUsingComparator:
      ^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2)
      {
      NSDictionary * process1 = obj1;
      NSDictionary * process2 = obj2;
      
      NSNumber * bytesIn1 = [process1 objectForKey: @"bytesIn"];
      NSNumber * bytesOut1 = [process1 objectForKey: @"bytesOut"];
      
      NSNumber * bytesIn2 = [process2 objectForKey: @"bytesIn"];
      NSNumber * bytesOut2 = [process2 objectForKey: @"bytesOut"];
      
      unsigned long long total1 =
        [bytesIn1 unsignedLongLongValue] +
          [bytesOut1 unsignedLongLongValue];

      unsigned long long total2 =
        [bytesIn2 unsignedLongLongValue] +
          [bytesOut2 unsignedLongLongValue];
        
      if(total1 > total2)
        return NSOrderedAscending;
      else if(total1 < total2)
        return NSOrderedDescending;
        
      return NSOrderedSame;
      }];
  }

// Parse a single process.
- (NSDictionary *) parseNetTop: (NSString *) line
  {
  NSScanner * scanner = [NSScanner scannerWithString: line];
  
  NSString * time = NULL;
  
  BOOL success =
    [scanner
      scanUpToCharactersFromSet: [NSCharacterSet whitespaceCharacterSet]
      intoString: & time];
    
  if(!success)
    return nil;
    
  // Skip first line.
  if([time isEqualToString: @"time"])
    return nil;
    
  NSString * process = NULL;
  
  success =
    [scanner
      scanUpToCharactersFromSet: [NSCharacterSet whitespaceCharacterSet]
      intoString: & process];
    
  if(!success)
    return nil;
    
  NSRange PIDRange =
    [process rangeOfString: @"." options: NSBackwardsSearch];
  
  if(PIDRange.location != NSNotFound)
    process = [process substringToIndex: PIDRange.location];
    
  unsigned long long bytesIn;
  
  success = [scanner scanUnsignedLongLong: & bytesIn];

  if(!success)
    return nil;
    
  unsigned long long bytesOut;
  
  success = [scanner scanUnsignedLongLong: & bytesOut];
  
  if(!success)
    return nil;
    
  return
    [NSDictionary
      dictionaryWithObjectsAndKeys:
        process, @"process",
        [NSNumber numberWithUnsignedLongLong: bytesIn], @"bytesIn",
        [NSNumber numberWithUnsignedLongLong: bytesOut], @"bytesOut",
        nil];
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
          NSLocalizedString(@"Input     ", NULL),
          NSLocalizedString(@"Output    ", NULL),
          NSLocalizedString(@"Process name", NULL)]
    attributes:
      @{ NSFontAttributeName : [[Utilities shared] boldFont] }];

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
  double bytesIn = [[process objectForKey: @"bytesIn"] doubleValue];
  double bytesOut = [[process objectForKey: @"bytesOut"] doubleValue];

  NSString * bytesInString =
    [formatter stringFromByteCount: (unsigned long long)bytesIn];

  NSString * bytesOutString =
    [formatter stringFromByteCount: (unsigned long long)bytesOut];
  
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
          printBytesInString,
          printBytesOutString,
          [process objectForKey: @"process"]]];
  }

@end
