/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014-2017. All rights reserved.
 **********************************************************************/

#import "DiskCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Model.h"
#import "Utilities.h"
#import "ByteCountFormatter.h"
#import "NSArray+Etresoft.h"
#import "SubProcess.h"
#import "XMLBuilder.h"
#import "LocalizedString.h"
#import "Drive.h"
#import "Volume.h"
#import "NSDictionary+Etresoft.h"
#import "NumberFormatter.h"
#import "StorageDevice.h"
#import "NSString+Etresoft.h"

#define kSerialATA @"serialata"
#define kNVMe @"nvme"

// Object that represents a top-level drive.

@interface Drive ()

// Build the attributedString value.
- (void) buildAttributedStringValue: 
  (NSMutableAttributedString *) attributedString;

@end

// Collect information about disks.
@implementation DiskCollector

// Constructor.
- (id) init
  {
  self = [super initWithName: @"disk"];
  
  if(self != nil)
    {
    }
    
  return self;
  }

// Perform the collection.
- (void) performCollect
  {
  // First collect devices.
  [self collectDevices];
    
  // Get more infromation for internal (and Thunderbolt) SerialATA drives.
  [self collect: kSerialATA];
    
  // Get more information for internal (and Thunderbolt) NVMExpress drives.
  [self collect: kNVMe];
  
  // Get Core Storage information.
  [self collectCoreStorage];
  
  // Get APFS information.
  [self collectAPFS];
  
  // Collect RAIDs.
  [self collectRAIDs];
  }
  
#pragma mark - Collect devices

// Collect all disk devices.
- (BOOL) collectDevices
  {
  NSArray * args =
    @[
      @"/dev",
      @"-name",
      @"disk*"
    ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  BOOL dataFound = NO;
  
  if([subProcess execute: @"/usr/bin/find" arguments: args])
    {
    NSArray * devices = [Utilities formatLines: subProcess.standardOutput];
    
    // Carefully sort the devices.
    NSArray * sortedDevices = 
      [devices 
        sortedArrayUsingComparator:
          ^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) 
            {
            NSString * device1 = 
              [[obj1 lastPathComponent] substringFromIndex: 4];
              
            NSString * device2 = 
              [[obj2 lastPathComponent] substringFromIndex: 4];
            
            NSArray * parts1 = [device1 componentsSeparatedByString: @"s"];
            NSArray * parts2 = [device2 componentsSeparatedByString: @"s"];
            
            NSString * disk1 = [parts1 firstObject];
            NSString * disk2 = [parts2 firstObject];
            
            if([disk1 isEqualToString: disk2])
              {
              if((parts1.count > 1) && (parts2.count > 1))
                {
                NSString * partition1 = [parts1 objectAtIndex: 1];
                NSString * partition2 = [parts2 objectAtIndex: 1];
                
                return [partition1 compare: partition2];
                }
              }
              
            return [disk1 compare: disk2];
            }];
    
    // Collect each device.
    for(NSString * device in sortedDevices)
      if([self collectDevice: device])
        dataFound = YES;
    }
    
  [subProcess release];
  
  return dataFound;
  }
  
// Collect a single device.
- (BOOL) collectDevice: (NSString *) device
  {
  NSArray * args =
    @[
      @"info",
      @"-plist",
      device
    ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  BOOL dataFound = NO;
  
  if([subProcess execute: @"/usr/sbin/diskutil" arguments: args])
    {
    NSDictionary * plist =
      [NSDictionary readPropertyListData: subProcess.standardOutput];
  
    if(plist.count > 0)
      {
      // Separate items by virtual or physical. Anything virtual will be
      // considered a volume.
      NSString * type = [plist objectForKey: @"VirtualOrPhysical"];
      
      if([type isEqualToString: @"Physical"])
        {
        if([self collectPhysicalDrive: plist])
          dataFound = YES;
        }
      else if([self collectVolume: plist])
        dataFound = YES;
      }
    }
    
  [subProcess release];
  
  return dataFound;
  }

// Collect a physical drive.
- (BOOL) collectPhysicalDrive: (NSDictionary *) plist
  {
  Drive * drive = [[Drive alloc] initWithDiskUtilInfo: plist];
  
  BOOL dataFound = NO;
  
  if(drive != nil)
    {
    [[[Model model] storageDevices] 
      setObject: drive forKey: drive.identifier];
    
    dataFound = YES;
    }
  
  [drive release];
  
  return dataFound;
  }

// Collect a volume.
- (BOOL) collectVolume: (NSDictionary *) plist
  {
  Volume * volume = [[Volume alloc] initWithDiskUtilInfo: plist];
  
  BOOL dataFound = NO;
  
  if(volume != nil)
    {
    [[[Model model] storageDevices] 
      setObject: volume forKey: volume.identifier];
      
    dataFound = YES;
    }
    
  [volume release];
  
  return dataFound;
  }
  
#pragma mark - Collect more information for physical drives

// Collect all devices attached to a given controller.
- (void) collect: (NSString *) type
  {
  NSArray * args =
    @[
      @"-xml",
      [self key: @"system_profiler" type: type]
    ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  //subProcess.debugStandardOutput =
  //  [NSData
  //    dataWithContentsOfFile: @"/tmp/SPSerialATADataType.xml"];
    
  if([subProcess execute: @"/usr/sbin/system_profiler" arguments: args])
    {
     NSArray * plist =
       [NSArray readPropertyListData: subProcess.standardOutput];
  
    if(plist && [plist count])
      {
      NSDictionary * controllers =
        [[plist objectAtIndex: 0] objectForKey: @"_items"];
        
      // Collect all controllers.
      for(NSDictionary * controller in controllers)
        [self collectController: controller type: type];
      }
    }

  [subProcess release];
  }

// Collect drives attached to a single controller.
- (void) collectController: (NSDictionary *) controller
  type: (NSString *) type
  {
  NSDictionary * items = [controller objectForKey: @"_items"];

  // Get the bus, port description, and speed for this controller.
  NSString * bus = 
    [controller objectForKey: [self key: @"vendor" type: type]];

  NSString * description =
    [controller objectForKey: [self key: @"portdescription" type: type]];

  NSString * speed = 
    [controller 
      objectForKey: [self key: @"negotiatedlinkspeed" type: type]];
      
  if(speed.length == 0)
    speed = [controller objectForKey: [self key: @"portspeed" type: type]];

  // This is just text.
  if(speed.length == 0)
    {
    NSString * linkspeed = 
      [controller 
        objectForKey: [self key: @"linkspeed" type: type]];

    NSString * linkwidth = 
      [controller 
        objectForKey: [self key: @"linkwidth" type: type]];
        
    speed = [NSString stringWithFormat: @"%@ %@", linkspeed, linkwidth];
    }
  
  for(NSDictionary * item in items)
    {
    NSString * device = [item objectForKey: @"bsd_name"];

    Drive * drive = [[[Model model] storageDevices] objectForKey: device];
    
    if([drive respondsToSelector: @selector(isDrive)])
      {
      // If this is an exernal drive, override the bus information.
      if(!drive.internal)
        drive.bus = bus;
    
      // Add controller information that might be missing.
      drive.busVersion = description;
      drive.busSpeed = speed;
      drive.type = type;
      
      drive.name = [item objectForKey: @"_name"];
      
      drive.model = [[item objectForKey: @"device_model"] trim];
      drive.revision = [[item objectForKey: @"device_revision"] trim];
      drive.serial = [[item objectForKey: @"device_serial"] trim];
      
      NSString * TRIM = 
        [item objectForKey: [self key: @"trim_support" type: type]];
        
      drive.TRIM = [TRIM isEqualToString: @"Yes"];
      
      NSArray * volumes = [item objectForKey: @"volumes"];
      
      for(NSDictionary * volumeItem in volumes)
        {
        NSString * volumeDevice = [volumeItem objectForKey: @"bsd_name"];
        
        if(volumeDevice.length > 0)
          {
          Volume * volume = 
            [[[Model model] storageDevices] objectForKey: volumeDevice];
            
          if([volume respondsToSelector: @selector(isVolume)])
            [volume addContainingDevice: device];
          }
        }
      }
    }
  }
    
#pragma mark - Collect Core Storage information

// Collect core storage information.
- (void) collectCoreStorage
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
  
    if(plist.count > 0)
      {
      NSArray * items =
        [[plist objectAtIndex: 0] objectForKey: @"_items"];
        
      for(NSDictionary * item in items)
        [self collectCoreStorageVolume: item];
      }
    }
    
  [subProcess release];
  
  // Now get a diskutil cs list to check for encryption progress.
  [self collectCoreStorageList];
  }
  
// Collect core storage information for a single volume.
- (void) collectCoreStorageVolume: (NSDictionary *) item
  {
  NSString * device = [item objectForKey: @"bsd_name"];

  Volume * volume = [[[Model model] storageDevices] objectForKey: device];
  
  if([volume respondsToSelector: @selector(isVolume)])
    {
    // Determine if the volume is encrypted and, if so, what type of
    // encryption is used.
    NSDictionary * logicalVolume = 
      [item objectForKey: @"com.apple.corestorage.lv"];
    
    NSString * encrypted = 
      [logicalVolume objectForKey: @"com.apple.corestorage.lv.encrypted"];
        
    volume.encrypted = [encrypted isEqualToString: @"yes"];
    
    if(volume.encrypted)
      volume.encryptionStatus = @"encrypted";
    
    // Now look for any physical volumes.
    NSArray * physicalVolumes = 
      [item objectForKey: @"com.apple.corestorage.pv"];
      
    for(NSDictionary * item in physicalVolumes)
      {
      NSString * physicalDevice = [item objectForKey: @"_name"];
      
      if(physicalDevice.length > 0)
        [volume addContainingDevice: physicalDevice];
      }
    }
  }
  
// Get a diskutil cs list to check for encryption progress.
- (void) collectCoreStorageList
  {
  NSArray * args =
    @[
      @"cs",
      @"list"
    ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  if([subProcess execute: @"/usr/sbin/diskutil" arguments: args])
    [self parseCoreStorageList: subProcess.standardOutput];
    
  [subProcess release];
  }
  
// Parse output from a diskutil cs list command.
- (void) parseCoreStorageList: (NSData *) output
  {
  NSArray * lines = [Utilities formatLines: output];
  
  NSString * device = nil;
  NSString * status = nil;
  
  for(NSString * line in lines)
    {
    NSString * trimmedLine = 
      [line 
        stringByTrimmingCharactersInSet: 
          [NSCharacterSet whitespaceAndNewlineCharacterSet]];
          
    // Save the current conversion status.
    if([trimmedLine hasPrefix: @"Conversion Status:"])
      {
      NSString * value = [trimmedLine substringFromIndex: 18];
      
      value = 
        [value 
          stringByTrimmingCharactersInSet: 
            [NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
      if([value isEqualToString: @"Converting (backward)"])
        status = @"decrypting";
      else if([value isEqualToString: @"Converting (forward)"])
        status = @"encrypting";
      else
        status = nil;
      }
      
    // Save the current device.
    else if([trimmedLine hasPrefix: @"Disk:"])
      {
      NSString * value = [trimmedLine substringFromIndex: 5];
      
      device = 
        [value 
          stringByTrimmingCharactersInSet: 
            [NSCharacterSet whitespaceAndNewlineCharacterSet]];
      }
      
    // If I have a conversion progress, assign it to the current device
    // and include the current status.
    else if([trimmedLine hasPrefix: @"Conversion Progress:"])
      {
      NSString * value = [trimmedLine substringFromIndex: 20];
      
      value = 
        [value 
          stringByTrimmingCharactersInSet: 
            [NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
      if([value hasSuffix: @"%"])
        value = [value substringToIndex: value.length - 1];
        
      int progress =
        [[[NumberFormatter sharedNumberFormatter] 
          convertFromString: value] intValue];
          
      if((progress > 0) && (device.length > 0) && (status.length > 0))
        {
        Volume * volume = 
          [[[Model model] storageDevices] objectForKey: device];
          
        volume.encryptionStatus = status;
        volume.encryptionProgress = progress;
        }
      }
    }
  }
  
#pragma mark - Collect APFS information

// Collect APFS information.
- (void) collectAPFS
  {
  NSArray * args =
    @[
      @"apfs",
      @"list",
      @"-plist"
    ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  if([subProcess execute: @"/usr/sbin/diskutil" arguments: args])
    {
    NSDictionary * plist =
      [NSDictionary readPropertyListData: subProcess.standardOutput];
  
    if(plist.count > 0)
      {
      NSArray * containers = [plist objectForKey: @"Containers"];
        
      for(NSDictionary * container in containers)
        {
        NSString * containerReference = 
          [container objectForKey: @"ContainerReference"];
        
        if(containerReference.length > 0)
          {
          StorageDevice * storageDevice = 
            [[[Model model] storageDevices] 
              objectForKey: containerReference];
          
          // This must be a container.
          storageDevice.type = kAPFSContainerVolume;
          }
          
        NSArray * volumes = [container objectForKey: @"Volumes"];
        
        NSArray * physicalStores = 
          [container objectForKey: @"PhysicalStores"];
        
        for(NSDictionary * item in volumes)
          {
          NSString * device = [item objectForKey: @"DeviceIdentifier"];
          
          Volume * volume = 
            [[[Model model] storageDevices] objectForKey: device];
          
          // Get the encryption direction and progress.
          volume.encrypted = [[item objectForKey: @"Encryption"] boolValue];
          volume.encryptionStatus = 
            [[item objectForKey: @"CryptoMigrationDirection"] 
              lowercaseString];
            
          volume.encryptionProgress = 
            [[item objectForKey: @"CryptoMigrationProgressPercent"] 
              intValue];
          
          if(volume.encrypted && (volume.encryptionStatus == nil))
            volume.encryptionStatus = @"encrypted";
            
          // See if there is an APFS role.
          NSArray * roles = [item objectForKey: @"Roles"];
          
          if(roles.count == 1)
            {
            NSString * role = [roles firstObject];
            
            if([role isEqualToString: @"Preboot"])
              volume.type = kPrebootVolume;
            else if([role isEqualToString: @"Recovery"])
              volume.type = kRecoveryVolume;
            else if([role isEqualToString: @"VM"])
              volume.type = kVMVolume;
            }
            
          // Now add phyiscal devices.
          for(NSDictionary * physicalStore in physicalStores)
            {
            NSString * physicalDevice = 
              [physicalStore objectForKey: @"DeviceIdentifier"];
              
            if(physicalDevice.length > 0)
              [volume addContainingDevice: physicalDevice];
            }
            
          // If I don't already have a type, and I have multiple physical 
          // volumes, this must be a Fusion disk.
          if((volume.type == nil) && (physicalStores.count > 1))
            volume.type = kFusionVolume;
          }
        }
      }
    }
    
  [subProcess release];
  }
  
#pragma mark - Collect RAID information

// Collect RAID information.
- (void) collectRAIDs
  {
  NSMutableSet * RAIDSets = [NSMutableSet new];
  NSMutableDictionary * RAIDDevices = [NSMutableDictionary new];
  
  for(NSString * device in [[Model model] storageDevices])
    {
    StorageDevice * storageDevice = 
      [[[Model model] storageDevices] objectForKey: device];
    
    if(storageDevice != nil)
      {
      if(storageDevice.RAIDSetUUID.length > 0)
        [RAIDDevices 
          setObject: storageDevice forKey: storageDevice.RAIDSetUUID];
      
      if(storageDevice.RAIDSetMembers.count > 0)
        [RAIDSets addObject: storageDevice];
      }
    }
    
  for(Volume * volume in RAIDSets)
    if([volume respondsToSelector: @selector(isVolume)])
      for(NSString * UUID in volume.RAIDSetMembers)
        {
        StorageDevice * storageDevice = [RAIDDevices objectForKey: UUID];
        
        if(storageDevice != nil)
          [volume addContainingDevice: storageDevice.identifier];
        }
  }

#pragma mark - Utility methods

// Convenience method to get a protocol key.
- (NSString *) key: (NSString *) key type: (NSString *) type 
  {
  if([key isEqualToString: @"system_profiler"])
    {
    if([type isEqualToString: kSerialATA])
      return @"SPSerialATADataType";
      
    return @"SPNVMeDataType";
    }
    
  if([type isEqualToString: kSerialATA])
    return [@"spsata_" stringByAppendingString: key];
    
  return [@"spnvme_" stringByAppendingString: key];
  }
  
@end
