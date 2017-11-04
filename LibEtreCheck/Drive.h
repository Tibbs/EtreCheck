/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "StorageDevice.h"

// Object that represents a top-level drive.
@interface Drive : StorageDevice
  {
  // The drive model.
  NSString * myModel;
  
  // The drive revision.
  NSString * myRevision;
  
  // The drive serial number.
  NSString * mySerial;
  
  // The bus this drive is on.
  NSString * myBus;
  
  // The bus version.
  NSString * myBusVersion;
  
  // The bus speed.
  NSString * myBusSpeed;
  
  // Is this an SSD?
  BOOL mySolidState;
  
  // Is this an internal drive?
  BOOL myInternal;
  
  // The SMART status.
  NSString * mySMARTStatus;
  
  // If SSD, is TRIM enabled?
  BOOL myTRIM;
  
  // A drive has 0 or more volumes.
  NSMutableArray * myVolumes;
  }
  
// The drive model.
@property (retain, nullable) NSString * model;

// The drive revision.
@property (retain, nullable) NSString * revision;

// The drive serial number.
@property (retain, nullable) NSString * serial;

// The bus this drive is on.
@property (retain, nullable) NSString * bus;
  
// The bus version.
@property (retain, nullable) NSString * busVersion;

// The bus speed. 
@property (retain, nullable) NSString * busSpeed;

// Is this an SSD?
@property (assign) BOOL solidState;

// Is this an internal drive?
@property (assign) BOOL internal;

// The SMART status.
@property (retain, nullable) NSString * SMARTStatus;

// If SSD, is TRIM enabled?
@property (assign) BOOL TRIM;

// A drive has 0 or more volumes indexed by device id.
@property (retain, readonly, nonnull) NSMutableArray * volumes;
  
// Constructor with output from diskutil info -plist.
- (nullable instancetype) initWithDiskUtilInfo: 
  (nullable NSDictionary *) plist;

// Class inspection.
- (BOOL) isDrive;

@end
