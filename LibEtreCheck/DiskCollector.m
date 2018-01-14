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
#import "NSNumber+Etresoft.h"

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

  // There should always be data found.
  [self.result appendAttributedString: [self buildTitle]];

  [self printDrives];
  [self exportDrives];
  
  if([[self.model storageDevices] count] == 0)
    [self.result
      appendString:
        ECLocalizedString(@"    Drive information not found!\n")
      attributes:
        @{
          NSFontAttributeName : [[Utilities shared] boldFont],
          NSForegroundColorAttributeName : [[Utilities shared] red]
        }];

  [self.result appendCR];
  }
    
#pragma mark - Collect more information for physical drives

// Collect all devices attached to a given controller.
- (void) collect: (NSString *) type
  {
  NSString * key = [self key: @"system_profiler" type: type];
  
  NSArray * args =
    @[
      @"-xml",
      key
    ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  [subProcess loadDebugOutput: [self.model debugInputPath: key]];      
  [subProcess saveDebugOutput: [self.model debugOutputPath: key]];
    
  if([subProcess execute: @"/usr/sbin/system_profiler" arguments: args])
    {
    NSArray * plist =
       [NSArray readPropertyListData: subProcess.standardOutput];
  
    if([NSArray isValid: plist] && (plist.count > 0))
      {
      NSDictionary * results = [plist objectAtIndex: 0];
      
      if([NSDictionary isValid: results])
        {
        NSArray * controllers = [results objectForKey: @"_items"];
        
        if([NSArray isValid: controllers])
          // Collect all controllers.
          for(NSDictionary * controller in controllers)
            if([NSDictionary isValid: controller])
              [self collectController: controller type: type];
        }
      }
    }

  [subProcess release];
  }

// Collect drives attached to a single controller.
- (void) collectController: (NSDictionary *) controller
  type: (NSString *) type
  {
  NSArray * items = [controller objectForKey: @"_items"];

  if(![NSArray isValid: items])
    return;
    
  // Get the bus, port description, and speed for this controller.
  NSString * bus = 
    [controller objectForKey: [self key: @"vendor" type: type]];

  NSString * description =
    [controller objectForKey: [self key: @"portdescription" type: type]];

  NSString * speed = 
    [controller 
      objectForKey: [self key: @"negotiatedlinkspeed" type: type]];
      
  if(![NSString isValid: speed])
    speed = [controller objectForKey: [self key: @"portspeed" type: type]];

  // This is just text.
  if(![NSString isValid: speed])
    {
    NSString * linkspeed = 
      [controller objectForKey: [self key: @"linkspeed" type: type]];

    NSString * linkwidth = 
      [controller objectForKey: [self key: @"linkwidth" type: type]];
        
    if([NSString isValid: linkspeed] && [NSString isValid: linkwidth])
      speed = [NSString stringWithFormat: @"%@ %@", linkspeed, linkwidth];
    }
  
  for(NSDictionary * item in items)
    {
    if(![NSDictionary isValid: item])
      continue;
      
    // These speed items are at the controller level for SerialATA and at
    // the device level for NVMe.
    NSString * deviceSpeed = speed;
    
    // This is just text.
    if(![NSString isValid: deviceSpeed])
      {
      NSString * linkspeed = 
        [item objectForKey: [self key: @"linkspeed" type: type]];

      NSString * linkwidth = 
        [item objectForKey: [self key: @"linkwidth" type: type]];
          
      deviceSpeed = 
        [NSString stringWithFormat: @"%@ %@", linkspeed, linkwidth];
      }

    NSString * device = [item objectForKey: @"bsd_name"];

    if(![NSString isValid: device])
      continue;

    Drive * drive = [[self.model storageDevices] objectForKey: device];
    
    if([Drive isValid: drive])
      {
      // If this is an exernal drive, override the bus information.
      if(!drive.internal)
        drive.bus = bus;
    
      // Add controller information that might be missing.
      drive.busVersion = description;
      drive.busSpeed = deviceSpeed;
      drive.type = type;
      
      NSString * name = [item objectForKey: @"_name"];
      
      if(![NSString isValid: name])
        continue;
        
      NSString * model = [item objectForKey: @"device_model"];
      NSString * revision = [item objectForKey: @"device_revision"];
      NSString * serial = [item objectForKey: @"device_serial"];

      if(![NSString isValid: model])
        continue;
        
      if(![NSString isValid: revision])
        continue;

      if(![NSString isValid: serial])
        continue;

      drive.name = name;
      
      drive.model = model.trim;
      drive.revision = revision.trim;
      drive.serial = serial.trim;
      
      NSString * TRIM = 
        [item objectForKey: [self key: @"trim_support" type: type]];
        
      if([NSString isValid: TRIM])
        drive.TRIM = [TRIM isEqualToString: @"Yes"];
      
      NSArray * volumes = [item objectForKey: @"volumes"];
      
      if([NSArray isValid: volumes])
        for(NSDictionary * volumeItem in volumes)
          if([NSDictionary isValid: volumeItem])
            {
            NSString * volumeDevice = 
              [volumeItem objectForKey: @"bsd_name"];
            
            if([NSString isValid: volumeDevice])
              {
              Volume * volume = 
                [[self.model storageDevices] objectForKey: volumeDevice];
                
              if([Volume isValid: volume])
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
  NSString * key = @"SPStorageDataType";
  
  NSArray * args =
    @[
      @"-xml",
      key
    ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  [subProcess loadDebugOutput: [self.model debugInputPath: key]];      
  [subProcess saveDebugOutput: [self.model debugOutputPath: key]];

  if([subProcess execute: @"/usr/sbin/system_profiler" arguments: args])
    {
    NSArray * plist =
      [NSArray readPropertyListData: subProcess.standardOutput];
  
    if([NSArray isValid: plist] && (plist.count > 0))
      {
      NSDictionary * result = [plist objectAtIndex: 0];
      
      if([NSDictionary isValid: result])
        {
        NSArray * items = [result objectForKey: @"_items"];
        
        if([NSArray isValid: items])
          for(NSDictionary * item in items)
            if([NSDictionary isValid: item])
              [self collectCoreStorageVolume: item];
        }
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

  if(![NSString isValid: device])
    return;
    
  Volume * volume = [[self.model storageDevices] objectForKey: device];
  
  if([Volume isValid: volume])
    {
    // Determine if the volume is encrypted and, if so, what type of
    // encryption is used.
    NSDictionary * logicalVolume = 
      [item objectForKey: @"com.apple.corestorage.lv"];
    
    if([NSDictionary isValid: logicalVolume])
      {
      NSString * encrypted = 
        [logicalVolume objectForKey: @"com.apple.corestorage.lv.encrypted"];
          
      if([NSString isValid: encrypted])
        volume.encrypted = [encrypted isEqualToString: @"yes"];
      
      if(volume.encrypted)
        volume.encryptionStatus = @"encrypted";
      
      // Now look for any physical volumes.
      NSArray * physicalVolumes = 
        [item objectForKey: @"com.apple.corestorage.pv"];
        
      if([NSArray isValid: physicalVolumes])
        for(NSDictionary * item in physicalVolumes)
          {
          NSString * physicalDevice = [item objectForKey: @"_name"];
          
          if([NSString isValid: physicalDevice])
            [volume addContainingDevice: physicalDevice];
          }
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
  
  NSString * key = @"diskutil_cs_list";
  
  [subProcess loadDebugOutput: [self.model debugInputPath: key]];      
  [subProcess saveDebugOutput: [self.model debugOutputPath: key]];

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
          [[self.model storageDevices] objectForKey: device];
          
        if([Volume isValid: volume])
          {
          volume.encryptionStatus = status;
          volume.encryptionProgress = progress;
          }
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
  
  NSString * key = @"diskutil_apfs_list";
  
  [subProcess loadDebugOutput: [self.model debugInputPath: key]];      
  [subProcess saveDebugOutput: [self.model debugOutputPath: key]];

  if([subProcess execute: @"/usr/sbin/diskutil" arguments: args])
    {
    NSDictionary * plist =
      [NSDictionary readPropertyListData: subProcess.standardOutput];
  
    if(plist.count > 0)
      {
      NSArray * containers = [plist objectForKey: @"Containers"];
        
      if([NSArray isValid: containers])
        for(NSDictionary * container in containers)
          {
          if(![NSDictionary isValid: container])
            continue;
            
          NSString * containerReference = 
            [container objectForKey: @"ContainerReference"];
          
          if([NSString isValid: containerReference])
            {
            StorageDevice * storageDevice = 
              [[self.model storageDevices] 
                objectForKey: containerReference];
            
            // This must be a container.
            storageDevice.type = kAPFSContainerVolume;
            }
            
          NSArray * volumes = [container objectForKey: @"Volumes"];
          
          if([NSArray isValid: volumes])
            {
            NSArray * physicalStores = 
              [container objectForKey: @"PhysicalStores"];
            
            if([NSArray isValid: physicalStores])
              for(NSDictionary * item in volumes)
                {
                if(![NSDictionary isValid: item])
                  continue;
                  
                NSString * device = 
                  [item objectForKey: @"DeviceIdentifier"];
                
                if(![NSString isValid: device])
                  continue;
                  
                Volume * volume = 
                  [[self.model storageDevices] objectForKey: device];
                
                if([Volume isValid: volume])
                  {
                  // Get the encryption direction and progress.
                  NSNumber * encryptionValue = 
                    [item objectForKey: @"Encryption"];
                  
                  if([NSNumber isValid: encryptionValue])
                    volume.encrypted = [encryptionValue boolValue];
                  
                  NSString * encryptionStatus =
                    [item objectForKey: @"CryptoMigrationDirection"];
                    
                  if([NSString isValid: encryptionStatus])
                    volume.encryptionStatus = 
                      [encryptionStatus lowercaseString];
                    
                  NSNumber * encryptionProgress = 
                    [item 
                      objectForKey: @"CryptoMigrationProgressPercent"];
                    
                  if([NSNumber isValid: encryptionProgress])
                    volume.encryptionProgress = 
                      [encryptionProgress intValue];
                  
                  if(volume.encrypted && (volume.encryptionStatus == nil))
                    volume.encryptionStatus = @"encrypted";
                    
                  // See if there is an APFS role.
                  NSArray * roles = [item objectForKey: @"Roles"];
                  
                  if([NSArray isValid: roles])
                    if(roles.count >= 1)
                      {
                      NSString * role = [roles firstObject];
                      
                      if([NSString isValid: role])
                        {
                        if([role isEqualToString: @"Preboot"])
                          volume.type = kPrebootVolume;
                        else if([role isEqualToString: @"Recovery"])
                          volume.type = kRecoveryVolume;
                        else if([role isEqualToString: @"VM"])
                          volume.type = kVMVolume;
                        }
                      }
                    
                  // Now add phyiscal devices.
                  for(NSDictionary * physicalStore in physicalStores)
                    {
                    NSString * physicalDevice = 
                      [physicalStore objectForKey: @"DeviceIdentifier"];
                      
                    if([NSString isValid: physicalDevice])
                      [volume addContainingDevice: physicalDevice];
                    }
                    
                  // If I don't already have a type, and I have 
                  // multiple physical volumes, this must be a Fusion 
                  // drive.
                  if((volume.type == nil) && (physicalStores.count > 1))
                    volume.type = kFusionVolume;
                  }
                }
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
  
  NSDictionary * devices = [self.model storageDevices];
  
  if([NSDictionary isValid: devices])
    for(NSString * device in devices)
      {
      StorageDevice * storageDevice = 
        [devices objectForKey: device];
      
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
    if([Volume isValid: volume])
      for(NSString * UUID in volume.RAIDSetMembers)
        {
        StorageDevice * storageDevice = [RAIDDevices objectForKey: UUID];
        
        if(storageDevice != nil)
          [volume addContainingDevice: storageDevice.identifier];
        }
        
  [RAIDDevices release];
  [RAIDSets release];
  }

#pragma mark - Output

// Print all drives found.
- (void) printDrives
  {
  NSDictionary * devices = [self.model storageDevices];
  
  if([NSDictionary isValid: devices])
    {
    // Get a sorted list of devices.
    NSArray * storageDevices = 
      [[devices allKeys] 
        sortedArrayUsingComparator:
          ^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) 
            {
            NSString * device1 = obj1;
            NSString * device2 = obj2;
            
            return [device1 compare: device2 options: NSNumericSearch];
            }];
    
    // Now export all drives matching this type.
    for(NSString * device in storageDevices)
      {
      Drive * drive = [devices objectForKey: device];
      
      if([Drive isValid: drive])
        {
        drive.indent = 1;
        
        [self.result appendAttributedString: drive.attributedStringValue];
        }
      }
    }
  }
  
// Export all drives found to XML.
- (void) exportDrives
  {
  NSDictionary * devices = [self.model storageDevices];
  
  if([NSDictionary isValid: devices])
    {
    // Get a sorted list of devices.
    NSArray * storageDevices = 
      [[devices allKeys] 
        sortedArrayUsingComparator:
          ^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) 
            {
            NSString * device1 = obj1;
            NSString * device2 = obj2;
            
            return [device1 compare: device2 options: NSNumericSearch];
            }];
    
    // Now export all drives matching this type.
    for(NSString * device in storageDevices)
      {
      Drive * drive = [devices objectForKey: device];
      
      if([Drive isValid: drive])
        [drive buildXMLValue: self.xml];
      }
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
