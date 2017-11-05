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

// Get containing devices.
- (NSSet *) containingDevices
  {
  return myContainingDevices;
  }

// Constructor with output from diskutil info -plist.
- (nullable instancetype) initWithDiskUtilInfo: 
  (nullable NSDictionary *) plist
  {
  self = [super initWithDiskUtilInfo: plist];
  
  if(self != nil)
    {
    myContainingDevices = [NSMutableSet new];
    
    self.UUID = [[plist objectForKey: @"VolumeUUID"] retain];
    self.filesystem = [[plist objectForKey: @"FilesystemName"] retain];
    self.mountpoint = [[plist objectForKey: @"MountPoint"] retain];
    
    NSNumber * freeSpace = [plist objectForKey: @"FreeSpace"];
    
    if([freeSpace respondsToSelector: @selector(unsignedIntegerValue)])
      self.freeSpace = [freeSpace unsignedIntegerValue];
    
    self.readOnly = ![[plist objectForKey: @"WritableVolume"] boolValue];

    NSString * content = [plist objectForKey: @"Content"];
    
    if([content isEqualToString: @"EFI"])
      self.type = kEFIVolume;
    else if([content isEqualToString: @"Apple_CoreStorage"])
      self.type = kCoreStorageVolume;
    else if([content isEqualToString: @"Apple_Boot"])
      self.type = kRecoveryVolume;
      
    if([[plist objectForKey: @"RAIDSlice"] boolValue])
      self.type = kRAIDMemberVolume;

    if([[plist objectForKey: @"RAIDSetMembers"] count] > 0)
      self.type = kRAIDSetVolume;
      
    if([[plist objectForKey: @"CoreStoragePVs"] count] > 1)
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
  }
  
// Build the attributedString value.
- (void) buildAttributedStringValue: 
  (NSMutableAttributedString *) attributedString
  {
  NSString * cleanName = 
    [self.name length] > 0 ? [Utilities cleanPath: self.name] : @"";
    
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
    
  NSString * volumeSize = [self byteCountString: self.size];
  NSString * volumeFree = [self byteCountString: self.freeSpace];
  
  if(fileSystemName.length > 0)
    {
    NSString * status = @"";
    
    if(self.freeSpace < (1024 * 1024 * 1024 * 15L))
      status = ECLocalizedString(@" (Low!)");

    volumeInfo =
      [NSString
        stringWithFormat:
          ECLocalizedString(@"%@ (%@%@) %@ %@: %@ %@%@\n"),
          cleanName,
          self.identifier,
          fileSystemName,
          volumeMountPoint,
          self.type,
          [self byteCountString: self.size],
          volumeFree.length > 0
            ? [NSString
                stringWithFormat:
                ECLocalizedString(@"(%@ free)"), volumeFree] 
            : @"",
          status];
    }
  else
    volumeInfo =
      [NSString
        stringWithFormat:
          ECLocalizedString(@"(%@) %@ %@: %@\n"),
          self.identifier, volumeMountPoint, self.type, volumeSize];
    
  if(self.errors.count > 0)
    [attributedString 
      appendString: volumeInfo 
      attributes: 
        @{
          NSForegroundColorAttributeName : [[Utilities shared] red],
          NSFontAttributeName : [[Utilities shared] boldFont]
        }];
  if(self.mountpoint.length == 0)
    [attributedString 
      appendString: volumeInfo 
      attributes:    
        @{
          NSForegroundColorAttributeName : [[Utilities shared] gray]
        }];
  else
    [attributedString appendString: volumeInfo];

  if(self.containingDevices.count > 0)
    for(NSString * device in self.containingDevices)
      {
      Drive * drive = [[[Model model] storageDevices] objectForKey: device];
      
      if([drive respondsToSelector: @selector(isDrive)])
        {
        NSString * driveName =
          self.name.length > 0
            ? self.name
            : @"";
            
        [attributedString
          appendString:
            [NSString
              stringWithFormat:
                @"    %@ %@%@\n",
                driveName, 
                drive.identifier, 
                [self byteCountString: drive.size]]];
        }
      }
  }
  
// Build the XML value.
- (void) buildXMLValue: (XMLBuilder *) xml
  {
  [xml startElement: @"volume"];
  
  [super buildXMLValue: xml];
  
  [xml addElement: @"name" value: self.name];
  [xml addElement: @"filesystem" value: self.filesystem];
  [xml addElement: @"mountpoint" value: self.mountpoint];  
  [xml 
    addElement: @"free" 
    valueWithUnits: 
      [myByteCountFormatter stringFromByteCount: self.freeSpace]];
  [xml addElement: @"UUID" value: self.UUID];
  
  if(self.containingDevices.count > 0)
    {
    [xml startElement: @"containers"];
    
    for(NSString * device in self.containingDevices)
      [xml addElement: @"device" value: device];
      
    [xml endElement: @"containers"];
    }
  
  [xml endElement: @"volume"];
  }

@end
