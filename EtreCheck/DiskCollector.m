/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "DiskCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Model.h"
#import "Utilities.h"
#import "ByteCountFormatter.h"
#import "NSArray+Etresoft.h"
#import "TTTLocalizedPluralString.h"
#import "SubProcess.h"
#import "XMLBuilder.h"

// Some keys for an internal dictionary.
#define kDiskStatsType @"volumetype"
#define kDiskStatsStatus @"volumestatus"
#define kDiskStatsAttributes @"attributes"

// Collect information about disks.
@implementation DiskCollector

@dynamic volumes;
@dynamic coreStorageVolumes;

// Provide easy access to volumes.
- (NSMutableDictionary *) volumes
  {
  return [[Model model] volumes];
  }

// Provide easy access to coreStorageVolumes.
- (NSMutableDictionary *) coreStorageVolumes
  {
  return [[Model model] coreStorageVolumes];
  }

// Constructor.
- (id) init
  {
  self = [super initWithName: @"disk"];
  
  if(self)
    {
    return self;
    }
    
  return nil;
  }

// Perform the collection.
- (void) performCollection
  {
  [self
    updateStatus: NSLocalizedString(@"Checking disk information", NULL)];

  BOOL dataFound = [self collectSerialATA];
  
  if([self collectNVMExpress: dataFound])
    dataFound = YES;
  
  if([self collectDiskFree: dataFound])
    dataFound = YES;
    
  if(!dataFound)
    [self.result appendCR];
    
  dispatch_semaphore_signal(self.complete);
  }

// Perform the collection for old Serial ATA controllers.
- (BOOL) collectSerialATA
  {
  NSArray * args =
    @[
      @"-xml",
      @"SPSerialATADataType"
    ];
  
  //result =
  //  [NSData
  //    dataWithContentsOfFile: @"/tmp/etrecheck/SPSerialATADataType.xml"];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  [subProcess autorelease];
  
  if([subProcess execute: @"/usr/sbin/system_profiler" arguments: args])
    {
    NSArray * plist =
       [NSArray readPropertyListData: subProcess.standardOutput];
  
    if(plist && [plist count])
      {
      [self.result appendAttributedString: [self buildTitle]];
      
      NSDictionary * controllers =
        [[plist objectAtIndex: 0] objectForKey: @"_items"];
        
      for(NSDictionary * controller in controllers)
        [self printSerialATAController: controller];
        
      return YES;
      }
    }

  return NO;
  }

// Perform the collection for new NVM controllers.
- (BOOL) collectNVMExpress: (BOOL) dataFound
  {
  // result =
  //  [NSData dataWithContentsOfFile: @"/tmp/etrecheck/SPNVMeDataType.xml"];
  
  NSArray * args =
    @[
      @"-xml",
      @"SPNVMeDataType"
    ];
  
  // result =
  //  [NSData dataWithContentsOfFile: @"/tmp/etrecheck/SPNVMeDataType.xml"];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  [subProcess autorelease];
  
  if([subProcess execute: @"/usr/sbin/system_profiler" arguments: args])
    {
    NSArray * plist =
      [NSArray readPropertyListData: subProcess.standardOutput];
  
    if(plist && [plist count])
      {
      if(!dataFound)
        [self.result appendAttributedString: [self buildTitle]];
      
      NSDictionary * controllers =
        [[plist objectAtIndex: 0] objectForKey: @"_items"];
        
      for(NSDictionary * controller in controllers)
        [self printNVMExpressController: controller];
        
      return YES;
      }
    }

  return NO;
  }

// Collect free disk space.
- (BOOL) collectDiskFree: (BOOL) dataFound
  {
  [self.XML startElement: kDiskVolumes];

  dataFound = NO;
  
  NSArray * args =
    @[
      @"-kl",
    ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  [subProcess autorelease];
  
  if([subProcess execute: @"/bin/df" arguments: args])
    {
    NSArray * lines = [Utilities formatLines: subProcess.standardOutput];
    
    for(int index = 1; index < [lines count]; ++index)
      {
      NSString * line = [lines objectAtIndex: index];
      
      if([line hasPrefix: @"/"])
        {
        [self printDiskFreeLine: line];
        
        dataFound = YES;
        }
      }
    }

  [self.XML endElement: kDiskVolumes];

  return dataFound;
  }

// Print disks attached to a single Serial ATA controller.
- (void) printSerialATAController: (NSDictionary *) controller
  {
  [self.XML startElement: kController];

  [self.XML addAttribute: kControllerType value: @"SerialATA"];
  
  NSDictionary * disks = [controller objectForKey: @"_items"];
  
  for(NSDictionary * disk in disks)
    {
    [self.XML startElement: kDisk];
    
    NSString * diskName = [disk objectForKey: @"_name"];
    NSString * diskDevice = [disk objectForKey: @"bsd_name"];
    NSString * diskSize = [disk objectForKey: @"size"];
    NSString * UUID = [disk objectForKey: @"volume_uuid"];
    NSString * medium = [disk objectForKey: @"spsata_medium_type"];
    NSString * trim = [disk objectForKey: @"spsata_trim_support"];
    
    [self.XML addElement: kDiskName value: diskName];
    [self.XML addElement: kDiskDevice value: diskDevice];
    [self.XML addElement: kDiskSize value: diskSize];
    [self.XML addElement: kVolumeUUID value: UUID];
    [self.XML addElement: kDiskType value: medium];
    
    if([medium isEqualToString: @"Solid State"] && [trim length])
      [self.XML addElement: kDiskTRIMEnabled value: trim];
    
    NSString * trimString =
      [NSString
        stringWithFormat: @" - TRIM: %@", NSLocalizedString(trim, NULL)];
    
    NSString * info =
      [NSString
        stringWithFormat:
          @"(%@%@)",
          medium
            ? medium
            : @"",
          ([medium isEqualToString: @"Solid State"] && [trim length])
            ? trimString
            : @""];
      
    if(!diskDevice)
      diskDevice = @"";
      
    if(!diskSize)
      diskSize = @"";
    else
      diskSize = [NSString stringWithFormat: @": (%@)", diskSize];

    if(UUID)
      [self.volumes setObject: disk forKey: UUID];

    [self.result
      appendString:
        [NSString
          stringWithFormat:
            @"    %@ %@ %@ %@\n",
            diskName ? diskName : @"-", diskDevice, diskSize, info]];
    
    [self collectSMARTStatus: disk indent: @"    "];
    
    [self printDiskVolumes: disk];
    
    [self.result appendCR];
    
    [self.XML endElement: kDisk];
    }
    
  [self.XML endElement: kController];
  }

// Print disks attached to a single NVMExpress controller.
- (void) printNVMExpressController: (NSDictionary *) controller
  {
  [self.XML startElement: kController];

  [self.XML addAttribute: kControllerType value: @"NVMExpress"];

  NSDictionary * disks = [controller objectForKey: @"_items"];
  
  for(NSDictionary * disk in disks)
    {
    [self.XML startElement: kDisk];

    NSString * diskName = [disk objectForKey: @"_name"];
    NSString * diskDevice = [disk objectForKey: @"bsd_name"];
    NSString * diskSize = [disk objectForKey: @"size"];
    NSString * UUID = [disk objectForKey: @"volume_uuid"];
    NSString * medium = @"Solid State";
    NSString * trim = [disk objectForKey: @"spnvme_trim_support"];
    
    [self.XML addElement: kDiskName value: diskName];
    [self.XML addElement: kDiskDevice value: diskDevice];
    [self.XML addElement: kDiskSize value: diskSize];
    [self.XML addElement: kVolumeUUID value: UUID];
    [self.XML addElement: kDiskType value: medium];
    
    if([medium isEqualToString: @"Solid State"] && [trim length])
      [self.XML addElement: kDiskTRIMEnabled value: trim];

    NSString * trimString =
      [NSString
        stringWithFormat: @" - TRIM: %@", NSLocalizedString(trim, NULL)];
    
    NSString * info =
      [NSString
        stringWithFormat:
          @"(%@%@)",
          medium
            ? medium
            : @"",
          ([medium isEqualToString: @"Solid State"] && [trim length])
            ? trimString
            : @""];
      
    if(!diskDevice)
      diskDevice = @"";
      
    if(!diskSize)
      diskSize = @"";
    else
      diskSize = [NSString stringWithFormat: @": (%@)", diskSize];

    if(UUID)
      [self.volumes setObject: disk forKey: UUID];

    [self.result
      appendString:
        [NSString
          stringWithFormat:
            @"    %@ %@ %@ %@\n",
            diskName ? diskName : @"-", diskDevice, diskSize, info]];
    
    [self collectSMARTStatus: disk indent: @"    "];
    
    [self printDiskVolumes: disk];
      
    [self.XML endElement: kDisk];

    [self.result appendCR];
    }
    
  [self.XML endElement: kController];
  }

// Print the volumes on a disk.
- (void) printDiskVolumes: (NSDictionary *) disk
  {
  [self.XML startElement: kDiskVolumes];
  
  NSArray * volumes = [disk objectForKey: @"volumes"];
  NSMutableSet * coreStorageVolumeNames = [NSMutableSet set];

  if(volumes && [volumes count])
    {
    for(NSDictionary * volume in volumes)
      {
      NSString * iocontent = [volume objectForKey: @"iocontent"];
      
      if([iocontent isEqualToString: @"Apple_CoreStorage"])
        {
        NSString * name = [volume objectForKey: @"_name"];
        
        [coreStorageVolumeNames addObject: name];
        }
        
      else
        {
        [self.XML startElement: kDiskVolume];

        [self printVolume: volume indent: @"        "];

        [self.XML endElement: kDiskVolume];
        }
      }
      
    for(NSDictionary * name in coreStorageVolumeNames)
      {
      NSDictionary * coreStorageVolume =
        [self.coreStorageVolumes objectForKey: name];
        
      if(coreStorageVolume)
        [self
          printCoreStorageVolume: coreStorageVolume indent: @"        "];
      }
    }

  [self.XML endElement: kDiskVolumes];
  }

// Get the SMART status for this disk.
- (void) collectSMARTStatus: (NSDictionary *) disk
  indent: (NSString *) indent
  {
  NSString * smart_status = [disk objectForKey: @"smart_status"];

  if(!smart_status)
    return;
    
  bool smart_not_supported =
    [smart_status isEqualToString: @"Not Supported"];
  
  bool smart_verified =
    [smart_status isEqualToString: @"Verified"];

  [self.XML addElement: kDiskSMARTStatus value: smart_status];

  if(!smart_not_supported && !smart_verified)
    {
    [self.XML addAttribute: kSeverity value: kCritical];
    
    [self.XML addAttribute: kSeverityExplanation value: @"SMART failure"];
    }

  if(!smart_not_supported && !smart_verified)
    [self.result
      appendString:
        [NSString
          stringWithFormat:
            NSLocalizedString(@"%@S.M.A.R.T. Status: %@\n", NULL),
            indent, smart_status]
      attributes:
        [NSDictionary
          dictionaryWithObjectsAndKeys:
            [NSColor redColor], NSForegroundColorAttributeName, nil]];
  }

// Print information about a Core Storage volume.
- (void) printCoreStorageVolume: (NSDictionary *) volume
  indent: (NSString *) indent
  {
  [self.XML startElement: kDiskVolume];
  
  [self printVolume: volume indent: indent];
  
  indent = [indent stringByAppendingString: @"    "];
  
  NSDictionary * lv = [volume objectForKey: @"com.apple.corestorage.lv"];
  
  if(lv)
    [self printCoreStorageLvInformation: lv indent: indent];
    
  NSArray * pvs = [volume objectForKey: @"com.apple.corestorage.pv"];
  
  if(pvs)
    [self printCoreStoragePvInformation: pvs indent: indent];
    
  [self.XML endElement: kDiskVolume];
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
    
  [self.XML addAttribute: kVolumeEncrypted value: encrypted];
  
  if([encrypted isEqualToString: @"yes"])
    {
    [self.XML addAttribute: kVolumeEncryptionType value: encryptionType];
    [self.XML addAttribute: kVolumeEncryptionLocked value: locked];
    
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
    
  [self.XML addElement: kVolumeEncryptionStatus value: state];
  
  if([state isEqualToString: @"Failed"])
    {
    [self.XML addAttribute: kSeverity value: kSerious];
    
    [self.XML
      addAttribute: kSeverityExplanation value: @"encryption failed"];
    
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
    
    [self.XML startElement: kVolumeCoreStorage];
    
    [self.XML addElement: kVolumeCoreStorageName value: name];
    [self.XML addElement: kVolumeCoreStorageSize value: size];
    [self.XML addElement: kVolumeCoreStorageStatus value: status];
    
    [self.XML endElement: kVolumeCoreStorage];

    if([errors length])
      {
      [self.XML addAttribute: kSeverity value: kCritical];
      [self.XML addAttribute: kSeverityExplanation value: @"disk failure"];
      [self.XML addElement: kVolumeErrors value: errors];
  
      [self.result
        appendString:
          [NSString
            stringWithFormat:
              @"%@Core Storage: %@ %@ %@", indent, name, size, status]
        attributes:
          @{
            NSForegroundColorAttributeName : [[Utilities shared] red],
            NSFontAttributeName : [[Utilities shared] boldFont]
          }];
      }
    else
      [self.result
        appendString:
          [NSString
            stringWithFormat:
              @"%@Core Storage: %@ %@ %@", indent, name, size, status]];

    [self.result appendCR];
    }
  }

// Print information about a volume.
- (void) printVolume: (NSDictionary *) volume indent: (NSString *) indent
  {
  NSString * volumeName = [volume objectForKey: @"_name"];
  NSString * volumeMountPoint = [volume objectForKey: @"mount_point"];
  NSString * volumeDevice = [volume objectForKey: @"bsd_name"];
  NSString * volumeSize = [self volumeSize: volume];
  NSString * volumeFree = [self volumeFreeSpace: volume];
  NSString * UUID = [volume objectForKey: @"volume_uuid"];

  if(!volumeMountPoint)
    volumeMountPoint = NSLocalizedString(@"<not mounted>", NULL);
    
  [self.XML addElement: kVolumeName value: volumeName];
  [self.XML addElement: kVolumeMountPoint value: volumeMountPoint];
  [self.XML addElement: kVolumeDevice value: volumeDevice];
  
  if(UUID)
    {
    [self.XML addElement: kVolumeUUID value: UUID];
    [self.volumes setObject: volume forKey: UUID];
    }
    
  NSDictionary * stats =
    [self
      volumeStatsFor: volumeName
      at: volumeMountPoint
      available:
        [[volume objectForKey: @"free_space_in_bytes"]
          unsignedLongLongValue]];

  NSDictionary * attributes = [stats objectForKey: kDiskStatsAttributes];
  
  NSString * errors = [self errorsFor: volumeDevice];
  
  if([errors length])
    {
    [self.XML addAttribute: kSeverity value: kCritical];
    [self.XML addAttribute: kSeverityExplanation value: @"disk failure"];
    [self.XML addElement: kVolumeErrors value: errors];

    attributes =
      @{
        NSForegroundColorAttributeName : [[Utilities shared] red],
        NSFontAttributeName : [[Utilities shared] boldFont]
      };
    }
    
  NSString * status =
    [[stats objectForKey: kDiskStatsStatus]
      stringByAppendingString: errors];

  NSString * volumeInfo =
    [NSString
      stringWithFormat:
        NSLocalizedString(@"%@%@ (%@) %@ %@: %@ %@%@\n", NULL),
        indent,
        volumeName ? [Utilities sanitizeFilename: volumeName] : @"-",
        volumeDevice,
        volumeMountPoint,
        [stats objectForKey: kDiskStatsType],
        volumeSize,
        volumeFree,
        status];
    
  if(attributes)
    [self.result appendString: volumeInfo attributes: attributes];
  else
    [self.result appendString: volumeInfo];
  }

// Print a line from df output.
- (void) printDiskFreeLine: (NSString *) line
  {
  NSScanner * scanner = [NSScanner scannerWithString: line];
  
  NSString * device;
  
  [scanner
    scanUpToCharactersFromSet: [NSCharacterSet whitespaceCharacterSet]
    intoString: & device];
    
  unsigned long long blocks;
  
  [scanner scanUnsignedLongLong: & blocks];
  
  unsigned long long used;
  
  [scanner scanUnsignedLongLong: & used];
  
  [scanner scanInteger: NULL];
  [scanner
    scanUpToCharactersFromSet: [NSCharacterSet whitespaceCharacterSet]
    intoString: NULL];
  [scanner scanInteger: NULL];
  [scanner scanInteger: NULL];
  [scanner
    scanUpToCharactersFromSet: [NSCharacterSet whitespaceCharacterSet]
    intoString: NULL];
  
  unsigned long long free = blocks - used;
  
  NSString * mountPoint;
  
  [scanner
    scanUpToCharactersFromSet: [NSCharacterSet whitespaceCharacterSet]
    intoString: & mountPoint];
  
  NSString * name =
    [[NSFileManager defaultManager] displayNameAtPath: mountPoint];
    
  if(name == nil)
    name = @"";
    
  ByteCountFormatter * formatter = [ByteCountFormatter new];
  
  NSDictionary * volume =
    [NSDictionary
      dictionaryWithObjectsAndKeys:
        name, @"_name",
        mountPoint, @"mount_point",
        device, @"bsd_name",
        [formatter stringFromByteCount: blocks * 1024], @"size",
        [formatter stringFromByteCount: free * 1024], @"free_space",
        [NSNumber numberWithUnsignedLongLong: free * 1024],
          @"free_space_in_bytes",
        nil];
    
  [formatter release];
  
  [self.XML startElement: kDiskVolume];
  
  [self printVolume: volume indent: @"        "];
  
  [self.XML endElement: kDiskVolume];
  
  [self.result appendCR];
  }

// Get the size of a volume.
- (NSString *) volumeSize: (NSDictionary *) volume
  {
  NSString * size = nil;
  
  NSNumber * sizeInBytes =
    [volume objectForKey: @"size_in_bytes"];
  
  if(sizeInBytes)
    {
    [self.XML addElement: kVolumeSize number: sizeInBytes];

    ByteCountFormatter * formatter = [ByteCountFormatter new];
    
    size =
      [formatter
        stringFromByteCount: [sizeInBytes unsignedLongLongValue]];
      
    [formatter release];
    }

  if(!size)
    size = [volume objectForKey: @"size"];

  if(!size)
    size = NSLocalizedString(@"Size unknown", NULL);
    
  return size;
  }

// Get the free space on the volume.
- (NSString *) volumeFreeSpace: (NSDictionary *) volume
  {
  NSString * volumeFree = nil;
  
  NSNumber * freeSpaceInBytes =
    [volume objectForKey: @"free_space_in_bytes"];
  
  if(freeSpaceInBytes)
    {
    [self.XML addElement: kVolumeFreeSpace number: freeSpaceInBytes];

    ByteCountFormatter * formatter = [ByteCountFormatter new];
    
    volumeFree =
      [formatter
        stringFromByteCount: [freeSpaceInBytes unsignedLongLongValue]];
      
    [formatter release];
    }

  if(!volumeFree)
    volumeFree = [volume objectForKey: @"free_space"];

  if(!volumeFree)
    volumeFree = @"";
  else
    volumeFree =
      [NSString
        stringWithFormat:
          NSLocalizedString(@"(%@ free)", NULL), volumeFree];
    
  return volumeFree;
  }

// Get more information about a volume.
- (NSDictionary *) volumeStatsFor: (NSString *) name
  at: (NSString *) mountPoint available: (unsigned long long) free
  {
  NSString * type = NSLocalizedString(@"", NULL);
  NSString * status = NSLocalizedString(@"", NULL);
  NSDictionary * attributes = @{};
  
  if([mountPoint isEqualToString: @"/"])
    {
    [self.XML addElement: kVolumeType value: @"startup"];
    
    type = NSLocalizedString(@" [Startup]", NULL);
    
    unsigned long long GB = 1024 * 1024 * 1024;

    if(free < (GB * 15))
      {
      [self.XML addAttribute: kSeverity value: kSerious];
      
      [self.XML
        addAttribute: kSeverityExplanation value: @"low disk space"];
      
      status = NSLocalizedString(@" (Low!)", NULL);
      }
    }
    
  else if([name isEqualToString: @"Recovery HD"])
    {
    [self.XML addElement: kVolumeType value: @"recovery"];

    type = NSLocalizedString(@" [Recovery]", NULL);

    attributes =
      @{
        NSForegroundColorAttributeName : [[Utilities shared] gray]
      };
    }
    
  if([status length] && ![attributes count])
    attributes =
      @{
        NSForegroundColorAttributeName : [[Utilities shared] red],
        NSFontAttributeName : [[Utilities shared] boldFont]
      };

  return
    @{
      kDiskStatsType : type,
      kDiskStatsStatus : status,
      kDiskStatsAttributes : attributes
    };
  }

// Get more information about a device.
- (NSString *) errorsFor: (NSString *) name
  {
  NSNumber * errors =
    [[[Model model] diskErrors] objectForKey: name];
    
  int errorCount = [errors intValue];
  
  if(errorCount)
    return
      [NSString
        stringWithFormat:
          NSLocalizedString(@" - %@ Drive failure!", NULL),
          TTTLocalizedPluralString(errorCount, @"error", NULL)];

  return NSLocalizedString(@"", NULL);
  }

@end
