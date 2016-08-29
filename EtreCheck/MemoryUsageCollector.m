/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "MemoryUsageCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "ByteCountFormatter.h"
#import "Model.h"
#import "Utilities.h"
#import "SubProcess.h"

#define kTotalRAM @"totalram"
#define kSwapUsed @"swapused"
#define kFreeRAM @"freeram"
#define kUsedRAM @"usedram"
#define kFileCache @"filecache"

// Collect information about memory usage.
@implementation MemoryUsageCollector

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    self.name = @"memory";
    self.title = NSLocalizedStringFromTable(self.name, @"Collectors", NULL);

    formatter = [[ByteCountFormatter alloc] init];

    formatter.k1000 = 1024.0;
    }
    
  return self;
  }

// Destructor.
- (void) dealloc
  {
  [formatter release];
    
  [super dealloc];
  }

// Perform the collection.
- (void) collect
  {
  [self updateStatus: NSLocalizedString(@"Checking memory usage", NULL)];

  NSDictionary * vminfo = [self collectVirtualMemoryInformation];
    
  [self.result appendAttributedString: [self buildTitle]];

  [self printVM: vminfo forKey: kFreeRAM];
  [self printVM: vminfo forKey: kUsedRAM];
  [self printVM: vminfo forKey: kFileCache];

  // Collect the average memory usage usage for all processes (5 times).
  NSDictionary * avgMemory = [self collectAverageMemory];
  
  // Sort the result by average value.
  NSArray * processesMemory = [self sortProcesses: avgMemory by: @"mem"];
  
  // Print the top processes.
  [self printTopProcesses: processesMemory];
    
  [self.result appendCR];

  dispatch_semaphore_signal(self.complete);
  }

// Collect virtual memory information.
- (NSDictionary *) collectVirtualMemoryInformation
  {
  NSMutableDictionary * vminfo = [NSMutableDictionary dictionary];
  
  [self collectvm_stat: vminfo];
  [self collectsysctl: vminfo];
  
  double totalRAM = [[vminfo objectForKey: kTotalRAM] doubleValue];
  double freeRAM = [[vminfo objectForKey: kFreeRAM] doubleValue];

  [vminfo
    setObject: [NSNumber numberWithDouble: totalRAM - freeRAM]
    forKey: kUsedRAM];
  
  return vminfo;
  }

// Collect information from vm_stat.
- (void) collectvm_stat: (NSMutableDictionary *) vminfo
  {
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  if([subProcess execute: @"/usr/bin/vm_stat" arguments: nil])
    {
    NSArray * lines = [Utilities formatLines: subProcess.standardOutput];
    
    NSMutableDictionary * vm_stats = [NSMutableDictionary dictionary];
    
    for(NSString * line in lines)
      {
      NSArray * parts = [line componentsSeparatedByString: @":"];
      
      if([parts count] > 1)
        {
        NSString * key = [parts objectAtIndex: 0];

        NSString * value = [parts objectAtIndex: 1];
          
        [vm_stats setObject: value forKey: key];
        }
      }

    // Format the values into something I can use.
    [vminfo addEntriesFromDictionary: [self formatVMStats: vm_stats]];
    }
    
  [subProcess release];
  }

// Collect information from sysctl.
- (void) collectsysctl: (NSMutableDictionary *) vminfo
  {
  NSArray * args = @[@"-a"];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  if([subProcess execute: @"/usr/sbin/sysctl" arguments: args])
    {
    NSArray * lines = [Utilities formatLines: subProcess.standardOutput];
    
    for(NSString * line in lines)
      if([line hasPrefix: @"vm.swapusage:"])
        // Format the values into something I can use.
        [vminfo
          addEntriesFromDictionary: [self formatSysctlSwapUsage: line]];
      
      else if([line hasPrefix: @"hw.memsize:"])
        // Format the values into something I can use.
        [vminfo addEntriesFromDictionary: [self formatSysctlMemSize: line]];
    }
    
  [subProcess release];
  }

// Print the swap VM value.
- (void) printSwapVM: (NSDictionary *) vminfo
  {
  NSUInteger GB = 1024 * 1024 * 1024;

  if(pageouts > (GB * 1))
    [self
      printVM: vminfo
      forKey: kSwapUsed
      attributes:
        @{
          NSForegroundColorAttributeName : [[Utilities shared] red]
        }];
  else
    [self printVM: vminfo forKey: kSwapUsed];
  }

// Print a VM value.
- (void) printVM: (NSDictionary *) vminfo forKey: (NSString *) key
  {
  double value = [[vminfo objectForKey: key] doubleValue];
  
  [self.result
    appendString:
      [NSString
        stringWithFormat:
          @"    %@\t%@\n",
          [formatter stringFromByteCount: (unsigned long long)value],
          NSLocalizedString(key, NULL)]];
  }

// Print a VM value.
- (void) printVM: (NSDictionary *) vminfo
  forKey: (NSString *) key
  attributes: (NSDictionary *) attributes
  {
  double value = [[vminfo objectForKey: key] doubleValue];
  
  [self.result
    appendString:
      [NSString
        stringWithFormat:
          @"    %@\t%@\n",
          [formatter stringFromByteCount: (unsigned long long)value],
          NSLocalizedString(key, NULL)]
    attributes: attributes];
  }

// Format cached files.
- (NSString *) formatCachedFiles: (NSDictionary *) vminfo
  {
  double cached = [[vminfo objectForKey: kFileCache] doubleValue];
 
  NSMutableString * extra = [NSMutableString string];
  
  if(cached > 0)
    {
    [extra appendString: @"("];
    
    [extra
      appendFormat:
        NSLocalizedString(kFileCache, NULL),
        [formatter stringFromByteCount: (unsigned long long)cached]];
    
    [extra appendString: @")"];
    }
    
  return extra;
  }

// Format output from vm_stats into something useable.
- (NSDictionary *) formatVMStats: (NSDictionary *) vm_stats
  {
  NSString * statisticsValue =
    [vm_stats objectForKey: @"Mach Virtual Memory Statistics"];
  NSString * cachedValue = [vm_stats objectForKey: @"File-backed pages"];
  NSString * freeValue =
    [vm_stats objectForKey: @"Pages free"];
  NSString * speculativeValue =
    [vm_stats objectForKey: @"Pages speculative"];
  NSString * purgeableValue =
    [vm_stats objectForKey: @"Pages purgeable"];

  double pageSize = [self parsePageSize: statisticsValue];
  
  double cached = [cachedValue doubleValue] * pageSize;
  double free = [freeValue doubleValue] * pageSize;
  double speculative = [speculativeValue doubleValue] * pageSize;
  double purgeable = [purgeableValue doubleValue] * pageSize;
  
  return
    @{
      kFileCache : [NSNumber numberWithDouble: cached + purgeable],
      kFreeRAM : [NSNumber numberWithDouble: free + speculative]
    };
  }
  
// Parse a VM page size.
- (double) parsePageSize: (NSString *) statisticsValue
  {
  NSScanner * scanner = [NSScanner scannerWithString: statisticsValue];

  double size;

  if([scanner scanDouble: & size])
    return size;

  return 4096;
  }

// Format output from sysctl into something useable.
- (NSDictionary *) formatSysctlSwapUsage: (NSString *) line
  {
  NSScanner * scanner = [NSScanner scannerWithString: line];
  
  [scanner scanString: @"vm.swapusage: total =" intoString: NULL];

  [scanner
    scanUpToCharactersFromSet: [NSCharacterSet whitespaceCharacterSet]
    intoString: NULL];
  
  [scanner scanString: @"used =" intoString: NULL];

  double used = [Utilities scanTopMemory: scanner];
  
  return
    @{
      kSwapUsed : [NSNumber numberWithDouble: used],
    };
  }

// Format output from sysctl into something useable.
- (NSDictionary *) formatSysctlMemSize: (NSString *) line
  {
  NSScanner * scanner = [NSScanner scannerWithString: line];
  
  NSInteger total = 0;
  
  if([scanner scanString: @"hw.memsize:" intoString: NULL])
    [scanner scanInteger: & total];
    
  return
    @{
      kTotalRAM : [NSNumber numberWithDouble: (double)total]
    };
  }

// Collect the average CPU usage of all processes.
- (NSDictionary *) collectAverageMemory
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
        double totalMemory =
          [[averageProcess objectForKey: @"mem"] doubleValue] * i;
        
        double averageMemory =
          [[averageProcess objectForKey: @"mem"] doubleValue];
        
        averageMemory = (totalMemory + averageMemory) / (double)(i + 1);
        
        [averageProcess
          setObject: [NSNumber numberWithDouble: averageMemory]
          forKey: @"mem"];
        }
      }
    }
  
  return averageProcesses;
  }

// Print top processes by memory.
- (void) printTopProcesses: (NSArray *) processes
  {
  NSUInteger count = 0;
  
  for(NSDictionary * process in processes)
    {
    [self printTopProcess: process];
    
    ++count;
          
    if(count >= 5)
      break;
    }
  }

// Print a top process.
// Return YES if the process could be printed.
- (void) printTopProcess: (NSDictionary *) process
  {
  double mem = [[process objectForKey: @"mem"] doubleValue];

  int count = [[process objectForKey: @"count"] intValue];
  
  NSString * countString =
    (count > 1)
      ? [NSString stringWithFormat: @"(%d)", count]
      : @"";

  NSString * output =
    [NSString
      stringWithFormat:
        @"    %-9@    %@%@\n",
        [formatter stringFromByteCount: (unsigned long long)mem],
        [process objectForKey: @"command"],
        countString];
    
  if(mem > 1024 * 1024 * 1024 * 2.0)
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
