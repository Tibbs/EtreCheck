/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014-2017. All rights reserved.
 **********************************************************************/

#import "VirtualMemoryCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "ByteCountFormatter.h"
#import "Model.h"
#import "Utilities.h"
#import "SubProcess.h"
#import "XMLBuilder.h"
#import "LocalizedString.h"
#import "NSNumber+Etresoft.h"
#import "NSString+Etresoft.h"

#define kAvailableRAM @"availableram"
#define kFreeRAM @"freeram"
#define kUsedRAM @"usedram"
#define kFileCache @"filecache"
#define kSwapUsed @"swapused"

#define kTotalRAM @"totalram"

// Collect virtual memory information.
@implementation VirtualMemoryCollector

// Constructor.
- (id) init
  {
  self = [super initWithName: @"vm"];
  
  if(self != nil)
    {
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
- (void) performCollect
  {
  NSDictionary * vminfo = [self collectVirtualMemoryInformation];
    
  [self.result appendAttributedString: [self buildTitle]];

  [self printVM: vminfo forKey: kAvailableRAM];
  [self printVM: vminfo forKey: kFreeRAM];
  [self printVM: vminfo forKey: kUsedRAM];
  [self printVM: vminfo forKey: kFileCache];
  [self printVM: vminfo forKey: kSwapUsed];

  [self.result appendCR];
  }

// Collect virtual memory information.
- (NSDictionary *) collectVirtualMemoryInformation
  {
  NSMutableDictionary * vminfo = [NSMutableDictionary dictionary];
  
  [self collectvm_stat: vminfo];
  [self collectsysctl: vminfo];
  
  NSNumber * totalRAMNumber = [vminfo objectForKey: kTotalRAM];
  NSNumber * freeRAMNumber = [vminfo objectForKey: kFreeRAM];
  NSNumber * fileCacheNumber = [vminfo objectForKey: kFileCache];
  
  double totalRAM = 0;
  double freeRAM = 0;
  double fileCache = 0;

  if([NSNumber isValid: totalRAMNumber])
    totalRAM = [totalRAMNumber doubleValue];
  
  if([NSNumber isValid: freeRAMNumber])
    freeRAM = [freeRAMNumber doubleValue];
  
  if([NSNumber isValid: fileCacheNumber])
    fileCache = [fileCacheNumber doubleValue];

  [vminfo
    setObject: [NSNumber numberWithDouble: totalRAM - freeRAM - fileCache]
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

// Print a VM value.
- (void) printVM: (NSDictionary *) vminfo forKey: (NSString *) key
  {
  NSNumber * number = [vminfo objectForKey: key];
  
  double value = 0;
  
  if([NSNumber isValid: number])
    value = [number doubleValue];
  
  NSString * memoryString =
    [formatter stringFromByteCount: (unsigned long long)value];
  
  NSString * printString =
    [memoryString
      stringByPaddingToLength: 10 withString: @" " startingAtIndex: 0];
  
  [self.xml addElement: key valueWithUnits: memoryString];
  
  [self.result
    appendString:
      [NSString
        stringWithFormat:
          @"    %@\t%@\n",
          printString,
          ECLocalizedString(key)]];
  }

// Print a VM value.
- (void) printVM: (NSDictionary *) vminfo
  forKey: (NSString *) key
  attributes: (NSDictionary *) attributes
  {
  NSNumber * number = [vminfo objectForKey: key];
  
  double value = 0;
  
  if([NSNumber isValid: number])
    value = [number doubleValue];
  
  NSString * memoryString =
    [formatter stringFromByteCount: (unsigned long long)value];
  
  NSString * printString =
    [memoryString
      stringByPaddingToLength: 10 withString: @" " startingAtIndex: 0];
  
  [self.result
    appendString:
      [NSString
        stringWithFormat:
          @"    %@\t%@\n",
          printString,
          ECLocalizedString(key)]
    attributes: attributes];
  }

// Format output from vm_stats into something useable.
- (NSDictionary *) formatVMStats: (NSDictionary *) vm_stats
  {
  NSString * statisticsValue =
    [vm_stats objectForKey: @"Mach Virtual Memory Statistics"];
    
  NSString * cachedValue = [vm_stats objectForKey: @"File-backed pages"];
  NSString * freeValue = [vm_stats objectForKey: @"Pages free"];
  NSString * purgeableValue = [vm_stats objectForKey: @"Pages purgeable"];

  double pageSize = 0;
  double cached = 0;
  double free = 0;
  double purgeable = 0;
  
  if([NSString isValid: statisticsValue])
    pageSize = [self parsePageSize: statisticsValue];
  
  if([NSString isValid: cachedValue])
    cached = [cachedValue doubleValue] * pageSize;
  
  if([NSString isValid: freeValue]) 
    free = [freeValue doubleValue] * pageSize;
  
  if([NSString isValid: purgeableValue])
    purgeable = [purgeableValue doubleValue] * pageSize;

  return
    @{
      kFileCache : [NSNumber numberWithDouble: cached + purgeable],
      kAvailableRAM :
        [NSNumber numberWithDouble: free + cached + purgeable],
      kFreeRAM : [NSNumber numberWithDouble: free]
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

@end
