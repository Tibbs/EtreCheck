/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "CoreStorageCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Model.h"
#import "Utilities.h"
#import "NSArray+Etresoft.h"
#import "SubProcess.h"

// Some keys for an internal dictionary.
#define kDiskType @"volumetype"
#define kDiskStatus @"volumestatus"
#define kAttributes @"attributes"

// Collect information about disks.
@implementation CoreStorageCollector

@dynamic coreStorageVolumes;

// Provide easy access to coreStorageVolumes.
- (NSMutableDictionary *) coreStorageVolumes
  {
  return [[Model model] coreStorageVolumes];
  }

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    self.name = @"corestorageinformation";
    self.title = NSLocalizedStringFromTable(self.name, @"Collectors", NULL);
    }
    
  return self;
  }

// Perform the collection.
- (void) collect
  {
  NSArray * args =
    @[
      @"-xml",
      @"SPStorageDataType"
    ];
  
  // result = [NSData dataWithContentsOfFile: @"/tmp/etrecheck/SPStorageDataType.xml"];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  if([subProcess execute: @"/usr/sbin/system_profiler" arguments: args])
    {
    NSArray * plist =
      [NSArray readPropertyListData: subProcess.standardOutput];
  
    if(plist && [plist count])
      {
      NSArray * volumes =
        [[plist objectAtIndex: 0] objectForKey: @"_items"];
        
      for(NSDictionary * volume in volumes)
        [self collectCoreStorageVolume: volume];
      }
    }
    
  [subProcess release];
  }

// Collect a Core Storage volume.
- (void) collectCoreStorageVolume: (NSDictionary *) volume
  {
  NSArray * pvs = [volume objectForKey: @"com.apple.corestorage.pv"];
  
  for(NSDictionary * pv in pvs)
    {
    NSString * name = [pv objectForKey: @"_name"];
    
    [self.coreStorageVolumes setObject: volume forKey: name];
    }
  }

@end
