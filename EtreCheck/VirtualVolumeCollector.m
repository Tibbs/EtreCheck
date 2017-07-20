/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "VirtualVolumeCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Model.h"
#import "Utilities.h"
#import "NSArray+Etresoft.h"
#import "NSDictionary+Etresoft.h"
#import "SubProcess.h"
#import "ByteCountFormatter.h"

// Some keys for an internal dictionary.
#define kDiskType @"volumetype"
#define kDiskStatus @"volumestatus"
#define kAttributes @"attributes"

// Collect information about disks.
@implementation VirtualVolumeCollector

@synthesize virtualVolumes = myVirtualVolumes;

// Constructor.
- (id) init
  {
  self = [super initWithName: @"virtualvolume"];
  
  if(self != nil)
    {
    myVirtualVolumes = [NSMutableDictionary new];
    }
    
  return self;
  }

// Destructor.
- (void) dealloc
  {
  [myVirtualVolumes release];
  
  [super dealloc];
  }

// Perform the collection.
- (void) performCollect
  {
  [self collectDiskUtil];
  [self collectStorage];
  [self collectDiskUtilAPFS];

  [self printVirtualVolumes];
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
  
  //subProcess.debugStandardOutput =
  //  [NSData dataWithContentsOfFile: @"/tmp/diskutil.xml"];

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
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  //subProcess.debugStandardOutput =
  //  [NSData dataWithContentsOfFile: @"/tmp/SPStorageDataType.xml"];

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

// Collect disk util information.
- (void) collectDiskUtilAPFS
  {
  NSArray * args =
    @[
      @"apfs",
      @"list",
      @"-plist"
    ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  //subProcess.debugStandardOutput =
  //  [NSData dataWithContentsOfFile: @"/tmp/diskutil.xml"];

  if([subProcess execute: @"/usr/sbin/diskutil" arguments: args])
    {
    NSDictionary * plist =
      [NSDictionary readPropertyListData: subProcess.standardOutput];
  
    if((plist != nil) && ([plist count] > 0))
      {
      NSArray * containers = [plist objectForKey: @"Containers"];
        
      for(NSDictionary * container in containers)
        {
        NSString * physicalDevice =
          [container objectForKey: @"DesignatedPhysicalStore"];

        NSArray * volumes = [container objectForKey: @"Volumes"];
        
        if([volumes count] > 0)
          for(NSMutableDictionary * volume in volumes)
            {
            NSString * device = [volume objectForKey: @"DeviceIdentifier"];
            
            if([device length] > 0)
              {
              NSMutableDictionary * virtualVolume =
                [self.virtualVolumes objectForKey: device];
                
              if(virtualVolume != nil)
                {
                NSDictionary * physicalDrive =
                  [volume objectForKey: @"physical_drive"];
                
                if(physicalDrive == nil)
                  [virtualVolume
                    setObject:
                      [NSDictionary
                        dictionaryWithObjectsAndKeys:
                          physicalDevice, @"device_name", nil]
                    forKey: @"physical_drive"];
                }
              }
            }
        }
      }
    }
    
  [subProcess release];
  }

// Print virtual volumes.
- (void) printVirtualVolumes
  {
  NSArray * devices =
    [[self.virtualVolumes allKeys]
      sortedArrayUsingSelector: @selector(compare:)];
      
  BOOL printed = NO;
  
  for(NSString * device in devices)
    {
    NSDictionary * volume = [self.virtualVolumes objectForKey: device];
      
    if(volume != nil)
      {
      NSString * volumeDevice = [volume objectForKey: @"bsd_name"];
      
      if([[[Model model] physicalVolumes] containsObject: volumeDevice])
        continue;
        
      if(!printed)
        {
        [self.result appendAttributedString: [self buildTitle]];
          
        printed = YES;
        }
        
      [self printVirtualVolume: volume indent: @"    "];
      }
    }
    
  if(printed)
    [self.result appendString: @"\n"];
  }
  
// Print information about a virtual volume.
- (void) printVirtualVolume: (NSDictionary *) volume
  indent: (NSString *) indent
  {
  [self printVolume: volume indent: indent];
  
  indent = [indent stringByAppendingString: @"    "];
  
  NSDictionary * lv = [volume objectForKey: @"com.apple.corestorage.lv"];
  
  if(lv)
    [self printCoreStorageLvInformation: lv indent: indent];
    
  NSArray * pvs = [volume objectForKey: @"com.apple.corestorage.pv"];
  
  if(pvs)
    [self printCoreStoragePvInformation: pvs indent: indent];
    
  NSDictionary * physicalDrive = [volume objectForKey: @"physical_drive"];
  
  if([physicalDrive respondsToSelector: @selector(objectForKey:)])
    [self
      printPhysicalDriveInformation: physicalDrive
      volume: volume
      indent: indent];
  }

// Print Core Storage "lv" information about a volume.
- (void) printCoreStorageLvInformation: (NSDictionary *) lv
  indent: (NSString *) indent
  {
  NSString * state =
    [lv objectForKey: @"com.apple.corestorage.lv.conversionState"];
  NSString * encrypted =
    [lv objectForKey: @"com.apple.corestorage.lv.encrypted"];
  NSString * encryptionType =
    [lv objectForKey: @"com.apple.corestorage.lv.encryptionType"];
  NSString * locked =
    [lv objectForKey: @"com.apple.corestorage.lv.locked"];
    
  if(!encryptionType)
    encryptionType = @"";
    
  if([encrypted isEqualToString: @"yes"])
    {
    [self.result
      appendString:
        [NSString
          stringWithFormat:
            @"%@%@ %@ %@",
            indent,
            NSLocalizedString(@"Encrypted", NULL),
            encryptionType,
            [locked isEqualToString: @"yes"]
              ? NSLocalizedString(@"Locked", NULL)
              : NSLocalizedString(@"Unlocked", NULL)]];

    [self printCoreStorageState: state];
      
    [self.result appendCR];
    }
  }

// Print the Core Storage state.
- (void) printCoreStorageState: (NSString *) state
  {
  if(!state)
    return;
    
  if([state isEqualToString: @"Failed"])
    {
    [self.result appendString: @" "];
    
    [self.result
      appendString: state
      attributes:
        @{
          NSForegroundColorAttributeName : [[Utilities shared] red],
          NSFontAttributeName : [[Utilities shared] boldFont]
        }];
    }
  else if(![state isEqualToString: @"Complete"])
    {
    [self.result appendString: @" "];
    
    [self.result
      appendString: state
      attributes:
        @{
          NSForegroundColorAttributeName : [[Utilities shared] blue],
          NSFontAttributeName : [[Utilities shared] boldFont]
        }];
    }
  }
  
// Print Core Storage "pv" information about a volume.
- (void) printCoreStoragePvInformation: (NSArray *) pvs
  indent: (NSString *) indent
  {
  for(NSDictionary * pv in pvs)
    {
    NSString * name = [pv objectForKey: @"_name"];
    NSString * status =
      [pv objectForKey: @"com.apple.corestorage.pv.status"];

    NSNumber * pvSize =
      [pv objectForKey: @"com.apple.corestorage.pv.size"];
    
    NSString * size = @"";
    
    if(pvSize)
      {
      ByteCountFormatter * formatter = [ByteCountFormatter new];
      
      size =
        [formatter stringFromByteCount: [pvSize unsignedLongLongValue]];
        
      [formatter release];
      }

    NSString * errors = [self errorsFor: name];
    
    status = [status stringByAppendingString: errors];
    
    if([errors length])
      [self.result
        appendString:
          [NSString
            stringWithFormat:
              @"%@%@ %@ %@ %@",
              indent,
              NSLocalizedString(@"Physical disk:", NULL),
              name,
              size,
              status]
        attributes:
          @{
            NSForegroundColorAttributeName : [[Utilities shared] red],
            NSFontAttributeName : [[Utilities shared] boldFont]
          }];
    else
      [self.result
        appendString:
          [NSString
            stringWithFormat:
              @"%@%@ %@ %@ %@",
              indent,
              NSLocalizedString(@"Physical disk:", NULL),
              name,
              size,
              status]];

    [self.result appendCR];
    }
  }

// Print APFS physicalDrive information about a volume.
- (void) printPhysicalDriveInformation: (NSDictionary *) physicalDrive
  volume: (NSDictionary *) volume indent: (NSString *) indent
  {
  NSString * name = [physicalDrive objectForKey: @"device_name"];
  NSString * volumeSize = [self volumeSize: volume];
  NSString * volumeFree = [self volumeFreeSpace: volume];
  
  [self.result
    appendString:
      [NSString
        stringWithFormat:
          @"%@%@ %@ %@ %@",
          indent,
          NSLocalizedString(@"Physical disk:", NULL),
          name,
          volumeSize,
          volumeFree]];
          
  [self.result appendCR];
  }

@end
