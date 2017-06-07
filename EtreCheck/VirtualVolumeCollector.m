/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014-2017. All rights reserved.
 **********************************************************************/

#import "VirtualVolumeCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Model.h"
#import "Utilities.h"
#import "NSArray+Etresoft.h"
#import "NSDictionary+Etresoft.h"
#import "SubProcess.h"

// Some keys for an internal dictionary.
#define kDiskType @"volumetype"
#define kDiskStatus @"volumestatus"
#define kAttributes @"attributes"

// Collect information about disks.
@implementation VirtualVolumeCollector

@dynamic virtualVolumes;

// Provide easy access to virtual volumes.
- (NSMutableDictionary *) virtualVolumes
  {
  return [[Model model] virtualVolumes];
  }

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    self.name = @"virtualvolumeinformation";
    self.title = NSLocalizedStringFromTable(self.name, @"Collectors", NULL);
    }
    
  return self;
  }

// Perform the collection.
- (void) collect
  {
  [self collectDiskUtil];
  [self collectStorage];
  }

// Collect disk util information.
- (void) collectDiskUtil
  {
  NSArray * args =
    @[
      @"list",
      @"-plist"
    ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  if([subProcess execute: @"/usr/sbin/diskutil" arguments: args])
    {
    NSDictionary * plist =
      [NSDictionary readPropertyListData: subProcess.standardOutput];
  
    if(plist && [plist count])
      {
      NSArray * volumeSets = [plist objectForKey: @"AllDisksAndPartitions"];
        
      for(NSDictionary * volumeSet in volumeSets)
        {
        NSArray * volumes = [volumeSet objectForKey: @"APFSVolumes"];
        
        if([volumes count] > 0)
          for(NSDictionary * volume in volumes)
            {
            NSString * device = [volume objectForKey: @"DeviceIdentifier"];
            NSString * volumeName = [volume objectForKey: @"VolumeName"];
            NSString * mountPoint = [volume objectForKey: @"MountPoint"];
            NSNumber * size = [volume objectForKey: @"Size"];
            
            if([device length] > 0)
              {
              NSMutableDictionary * virtualVolume =
                [NSMutableDictionary new];
                
              [virtualVolume setObject: device forKey: @"bsd_name"];
              
              if([volumeName length] > 0)
                {
                [virtualVolume setObject: volumeName forKey: @"_name"];
                
                NSString * iocontent =
                  [@"Apple_" stringByAppendingString: volumeName];
                  
                [virtualVolume setObject: iocontent forKey: @"iocontent"];
                }
                
              if([mountPoint length] > 0)
                [virtualVolume
                  setObject: mountPoint forKey: @"mount_point"];
                
              if(size != nil)
                [virtualVolume setObject: size forKey: @"size_in_bytes"];
                
              [self.virtualVolumes setObject: virtualVolume forKey: device];
              
              [virtualVolume release];
              }
            }
        }
      }
    }
    
  [subProcess release];
  }

// Collect storage information.
- (void) collectStorage
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
        {
        NSString * device = [volume objectForKey: @"bsd_name"];
        
        if([device length] > 0)
          [self.virtualVolumes setObject: volume forKey: device];
        }
      }
    }
    
  [subProcess release];
  }

@end
