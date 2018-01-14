/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "StorageDevice.h"

@class Model;

#define kSolidStateMechanism @"solidstate"
#define kMechanicalMechanism @"mechanical"
#define kDiskImageMechanism @"diskimage"
#define kUnknownMechanism @"unknown"

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
  
  // What is the mechanism?
  NSString * myMechanism;
  
  // Is this an internal drive?
  BOOL myInternal;
  
  // The SMART status.
  NSString * mySMARTStatus;
  
  // If SSD, is TRIM enabled?
  BOOL myTRIM;
  
  // The data model.
  Model * myDataModel;
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

// What is the mechanism?
@property (strong, nullable) NSString * mechanism;

// Is this an internal drive?
@property (assign) BOOL internal;

// The SMART status.
@property (retain, nullable) NSString * SMARTStatus;

// If SSD, is TRIM enabled?
@property (assign) BOOL TRIM;

// The data model.
@property (retain, nullable) Model * dataModel;

// Constructor with output from diskutil info -plist.
- (nullable instancetype) initWithDiskUtilInfo: 
  (nullable NSDictionary *) plist;

// Class inspection.
- (BOOL) isDrive;

// Is this a valid object?
+ (BOOL) isValid: (nullable Drive *) drive;

@end
