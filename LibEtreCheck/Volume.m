/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "Volume.h"
#import "XMLBuilder.h"
#import "Utilities.h"
#import "LocalizedString.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "ByteCountFormatter.h"
#import "Drive.h"
#import "Model.h"
#import "NSString+Etresoft.h"
#import "NSDictionary+Etresoft.h"
#import "NSNumber+Etresoft.h"
#import "NSArray+Etresoft.h"

@implementation Volume

// The UUID.
@synthesize UUID = myUUID;

// The filesystem.
@synthesize filesystem = myFilesystem;

// The mount point.
@synthesize mountpoint = myMountpoint;

// Is the volume encrypted?
@synthesize encrypted = myEncrypted;

// Encryption status.
@synthesize encryptionStatus = myEncryptionStatus;

// Encryption progress.
@synthesize encryptionProgress = myEncryptionProgress;

// Free space.
@synthesize freeSpace = myFreeSpace;

// Is this a shared volume?
@synthesize shared = myShared;

// Is this volume read-only?
@synthesize readOnly = myReadOnly;

// A volume has one or more physical drives.
// Use device identifier only to avoid cicular references.
@dynamic containingDevices;

// The data model.
@synthesize model = myModel;

@synthesize printCount = myPrintCount;

// Get containing devices.
- (NSSet *) containingDevices
  {
  return myContainingDevices;
  }

// If I change the indent, I'll need to rebuild the output.
- (void) setIndent: (int) indent
  {
  if(myIndent != indent)
    {
    [self willChangeValueForKey: @"indent"];
    
    myIndent = indent;
    
    self.attributedStringValue = nil;
    
    [self didChangeValueForKey: @"indent"];
    }
  }
  
// Constructor with output from diskutil info -plist.
- (nullable instancetype) initWithDiskUtilInfo: 
  (nullable NSDictionary *) plist
  {
  if(![NSDictionary isValid: plist])
    return nil;
    
  self = [super initWithDiskUtilInfo: plist];
  
  if(self != nil)
    {
    myContainingDevices = [NSMutableSet new];
    
    NSString * UUID = [plist objectForKey: @"VolumeUUID"];
    NSString * filesystem = [plist objectForKey: @"FilesystemName"];
    NSString * mountpoint = [plist objectForKey: @"MountPoint"];
    
    if([NSString isValid: UUID])
      self.UUID = UUID;
    
    if([NSString isValid: filesystem])
      self.filesystem = filesystem;
    
    if([NSString isValid: mountpoint])
      self.mountpoint = mountpoint;

    NSString * volumeName = [plist objectForKey: @"VolumeName"];
    
    if([NSString isValid: volumeName])
      self.name = volumeName;
      
    NSNumber * freeSpace = [plist objectForKey: @"FreeSpace"];
    
    if([NSNumber isValid: freeSpace])
      self.freeSpace = [freeSpace unsignedIntegerValue];
    
    NSNumber * writeableVolume = [plist objectForKey: @"WritableVolume"];
    
    if([NSNumber isValid: writeableVolume])
      self.readOnly = ![writeableVolume boolValue];

    NSString * content = [plist objectForKey: @"Content"];
    
    if([NSString isValid: content])
      {
      if([content isEqualToString: @"EFI"])
        self.type = kEFIVolume;
      else if([content isEqualToString: @"Apple_CoreStorage"])
        self.type = kCoreStorageVolume;
      else if([content isEqualToString: @"Apple_Boot"])
        self.type = kRecoveryVolume;
      }
      
    NSNumber * RAIDSlice = [plist objectForKey: @"RAIDSlice"];
    
    if([NSNumber isValid: RAIDSlice] && RAIDSlice.boolValue)
      self.type = kRAIDMemberVolume;

    NSArray * RAIDSetMembers = [plist objectForKey: @"RAIDSetMembers"];
    
    if([NSArray isValid: RAIDSetMembers] && (RAIDSetMembers.count > 0))
      self.type = kRAIDSetVolume;
      
    NSArray * coreStoragePVs = [plist objectForKey: @"CoreStoragePVs"];
    
    if([NSArray isValid: coreStoragePVs] && (coreStoragePVs.count > 1))
      self.type = kFusionVolume;
    }
    
  return self;
  }

// Destructor.
- (void) dealloc
  {
  [myContainingDevices release];
  
  self.UUID = nil;
  self.filesystem = nil;
  self.encryptionStatus = nil;
  self.mountpoint = nil;
  self.model = nil;
  
  [super dealloc];
  }
  
// Class inspection.
- (BOOL) isVolume
  {
  return YES;
  }
    
// Add a physical device reference, de-referencing any virtual devices or
// volumes.
- (void) addContainingDevice: (nonnull NSString *) device
  {
  [myContainingDevices addObject: device];
  
  StorageDevice * storageDevice = 
    [[self.model storageDevices] objectForKey: device];
    
  if(storageDevice != nil)
    [storageDevice.volumes addObject: self.identifier];
  }
  
// Build the attributedString value.
- (void) buildAttributedStringValue: 
  (NSMutableAttributedString *) attributedString
  {
  NSString * volumeMountPoint = self.mountpoint;
  
  if(volumeMountPoint == nil)
    volumeMountPoint = ECLocalizedString(@"<not mounted>");
        
  NSString * volumeInfo = nil;
  
  NSString * fileSystemName = @"";
  
  if(self.filesystem.length > 0)
    fileSystemName = 
      [NSString 
        stringWithFormat: 
          @" - %@", 
          ECLocalizedStringFromTable(self.filesystem, @"System")];
    
  NSString * volumeType = @"";
  
  if(self.type.length > 0)
    volumeType = 
      [NSString stringWithFormat: @"[%@]", ECLocalizedString(self.type)];
      
  NSString * volumeSize = @"";
  NSString * volumeFree = @"";
  
  if(self.size > 0)
    volumeSize = [self byteCountString: self.size];
  
  NSString * status = @"";
    
  if(self.mountpoint.length > 0)
    {
    volumeFree = 
      [NSString 
        stringWithFormat: 
          ECLocalizedString(@"(%@ free)"), 
          [self byteCountString: self.freeSpace]];
          
    if(self.freeSpace < (1024 * 1024 * 1024 * 15UL))
      status = ECLocalizedString(@" (Low!)");
    }
    
  if(fileSystemName.length > 0)
    {
    volumeInfo =
      [NSString
        stringWithFormat:
          ECLocalizedString(@"%@ (%@%@) %@ %@: %@ %@%@\n"),
          self.cleanName,
          self.identifier,
          fileSystemName,
          volumeMountPoint,
          volumeType,
          [self byteCountString: self.size],
          volumeFree,
          status];
    }
  else
    volumeInfo =
      [NSString
        stringWithFormat:
          ECLocalizedString(@"(%@) %@ %@: %@\n"),
          self.identifier, volumeMountPoint, volumeType, volumeSize];
    
  if(self.errors.count > 0)
    [attributedString 
      appendString: volumeInfo 
      attributes: 
        @{
          NSForegroundColorAttributeName : [[Utilities shared] red],
          NSFontAttributeName : [[Utilities shared] boldFont]
        }];
  else if(self.mountpoint.length == 0)
    [attributedString 
      appendString: volumeInfo 
      attributes:    
        @{
          NSForegroundColorAttributeName : [[Utilities shared] gray]
        }];
  else
    [attributedString appendString: volumeInfo];

  // Don't forget the volumes.
  NSArray * volumeDevices = 
    [StorageDevice sortDeviceIdenifiers: [self.volumes allObjects]];

  for(NSString * device in volumeDevices)
    {
    Volume * volume = [[self.model storageDevices] objectForKey: device];
    
    if([Volume isValid: volume])
      {
      volume.indent = self.indent + 1;
      
      [attributedString 
        appendAttributedString: volume.attributedStringValue];
      }
    }
    
  self.printCount = self.printCount + 1;
  }
  
// Build the XML value.
- (void) buildXMLValue: (XMLBuilder *) xml
  {
  [xml startElement: @"volume"];
  
  [super buildXMLValue: xml];
  
  [xml addElement: @"filesystem" value: self.filesystem];
  [xml addElement: @"mountpoint" value: self.mountpoint];  
  [xml 
    addElement: @"free" 
    valueWithUnits: 
      [myByteCountFormatter stringFromByteCount: self.freeSpace]];
  [xml addElement: @"UUID" value: self.UUID];
  
  if(self.encrypted)
    {
    [xml startElement: @"encryption"];
    
    [xml addElement: @"status" value: self.encryptionStatus];
    [xml addElement: @"progress" intValue: self.encryptionProgress];
    
    [xml endElement: @"encryption"];
    }
    
  if(self.containingDevices.count > 0)
    {
    [xml startElement: @"containers"];
    
    for(NSString * device in self.containingDevices)
      [xml addElement: @"device" value: device];
      
    [xml endElement: @"containers"];
    }
  
  [xml endElement: @"volume"];
  }

// Is this a valid object?
+ (BOOL) isValid: (nullable Volume *) volume
  {
  return 
    (volume != nil) && [volume respondsToSelector: @selector(isVolume)];
  }
  
@end
