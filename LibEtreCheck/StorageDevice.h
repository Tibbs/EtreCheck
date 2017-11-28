/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "PrintableItem.h"
#import "ByteCountFormatter.h"

@interface StorageDevice : PrintableItem
  {
  // The /dev/* device identifier.
  NSString * myIdentifier;
  
  // The volume name.
  NSString * myName;
  
  // The clean name.
  NSString * myCleanName;
  
  // The raw size of the device.
  NSUInteger mySize;
  
  // The type of storage device.
  NSString * myType;
  
  // Errors.
  NSMutableArray * myErrors;
  
  // RAID set UUID.
  NSString * myRAIDSetUUID;
  
  // RAID set members.
  NSArray * myRAIDSetMembers;
  
  // A byte count formatter.
  ByteCountFormatter * myByteCountFormatter;  
  
  // A volume has 0 or more volumes.
  NSMutableSet * myVolumes;
  }

// The /dev/* device identifier.
@property (retain, readonly, nonnull) NSString * identifier;

// The device name.
@property (retain, nullable) NSString * name;

// The clean name.
@property (retain, nonnull) NSString * cleanName;

// The raw size of the device.
@property (assign) NSUInteger size;

// The type of storage device.
@property (retain, nullable) NSString * type;

// Errors.
@property (retain, readonly, nonnull) NSMutableArray * errors;

// RAID set UUID.
@property (retain, nullable) NSString * RAIDSetUUID;

// RAID set members.
@property (retain, nullable) NSArray * RAIDSetMembers;

// A device has 0 or more volumes indexed by device id.
// Use device identifier only to avoid cicular references.
@property (retain, readonly, nonnull) NSMutableSet * volumes;

// Constructor with output from diskutil info -plist.
- (nullable instancetype) initWithDiskUtilInfo: 
  (nullable NSDictionary *) plist;

// Format a number into a byte count string.
- (nonnull NSString *) byteCountString: (NSUInteger) value;

// Sort an array of storage device identifiers.
+ (nonnull NSArray *) sortDeviceIdenifiers: (nonnull NSArray *) devices;
  
@end
