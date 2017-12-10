/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "Drive.h"
#import "XMLBuilder.h"
#import "Volume.h"
#import "ByteCountFormatter.h"
#import "LocalizedString.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Model.h"
#import "NSString+Etresoft.h"
#import "NSNumber+Etresoft.h"
#import "NSDictionary+Etresoft.h"

// Object that represents a top-level drive.
@implementation Drive

// The drive model.
@synthesize model = myModel;

// The drive revision.
@synthesize revision = myRevision;

// The drive serial number.
@synthesize serial = mySerial;

// The bus this drive is on.
@synthesize bus = myBus;
  
// The bus version.
@synthesize busVersion = myBusVersion;

// The bus speed.
@synthesize busSpeed = myBusSpeed;

// Is this an SSD?
@synthesize solidState = mySolidState;

// Is this an internal drive?
@synthesize internal = myInternal;

// The drive's SMART status.
@synthesize SMARTStatus = mySMARTStatus;

// If SSD, is TRIM enabled?
@synthesize TRIM = myTRIM;

// The data model.
@synthesize dataModel = myDataModel;

// Constructor with output from diskutil info -plist.
- (nullable instancetype) initWithDiskUtilInfo: 
  (nullable NSDictionary *) plist
  {
  self = [super initWithDiskUtilInfo: plist];
  
  if(self != nil)
    {
    NSString * model = [plist objectForKey: @"MediaName"];
    NSString * bus = [plist objectForKey: @"BusProtocol"];
    NSNumber * solidState = [plist objectForKey: @"SolidState"];
    NSNumber * internal = [plist objectForKey: @"Internal"];
    NSString * SMARTStatus = [plist objectForKey: @"SMARTStatus"];

    if([NSString isValid: model])
      self.model = model;
    
    if([NSString isValid: bus])
      self.bus = bus;
    
    if([NSNumber isValid: solidState])
      self.solidState = [solidState boolValue];
    
    if([NSNumber isValid: internal])
      self.internal = [internal boolValue];
      
    if([NSString isValid: SMARTStatus])
      self.SMARTStatus = SMARTStatus;
    }
    
  return self;
  }
  
// Destructor.
- (void) dealloc
  {
  self.model = nil;
  self.revision = nil;
  self.serial = nil;
  self.bus = nil;
  self.busVersion = nil;
  self.busSpeed = nil;
  self.SMARTStatus = nil;
  [myErrors release];
  self.dataModel = nil;
  
  [super dealloc];
  }

// Class inspection.
- (BOOL) isDrive
  {
  return TRUE;
  }
  
// Build the attributedString value.
- (void) buildAttributedStringValue: 
  (NSMutableAttributedString *) attributedString
  {
  NSString * driveName =
    self.name.length > 0
      ? self.name
      : @"";
      
  NSString * TRIMString =
    [NSString
      stringWithFormat: 
        @" - TRIM: %@", 
        self.TRIM 
          ? ECLocalizedString(@"Yes") 
          : ECLocalizedString(@"NO")];

  NSString * info =
    [NSString
      stringWithFormat:
        @"(%@%@)",
        self.solidState
          ? ECLocalizedString(@"Solid State")
          : ECLocalizedString(@"Mechanical"),
        (self.solidState && self.TRIM)
          ? TRIMString
          : @""];

  [attributedString
    appendString:
      [NSString
        stringWithFormat:
          @"%@ %@ %@ %@\n",
          driveName, 
          self.identifier, 
          [self byteCountString: self.size], 
          info]];
          
  if(self.SMARTStatus.length > 0)
    if(![self.SMARTStatus isEqualToString: @"Verified"])
      [attributedString
        appendString:
          [NSString
            stringWithFormat:
              ECLocalizedString(@"S.M.A.R.T. Status: %@\n"),
              ECLocalizedString(self.SMARTStatus)]
        attributes:
          [NSDictionary
            dictionaryWithObjectsAndKeys:
              [NSColor redColor], NSForegroundColorAttributeName, nil]];
              
  NSMutableString * indent = [NSMutableString new];
  
  for(int i = 0; i < self.indent; ++i)
    [indent appendString: @"    "];
    
  [attributedString
    appendString:
      [NSString
        stringWithFormat:
          @"%@%@ %@ %@ %@\n",
          indent,
          self.internal
            ? ECLocalizedString(@"Internal")
            : ECLocalizedString(@"External"), 
          self.bus, 
          self.busSpeed,
          ECLocalizedString(self.type)]];

  [indent release];
  
  NSDictionary * devices = [self.dataModel storageDevices];
  
  if([NSDictionary isValid: devices])
    {
    // Don't forget the volumes.
    NSArray * volumeDevices = 
      [StorageDevice sortDeviceIdenifiers: [self.volumes allObjects]];

    for(NSString * device in volumeDevices)
      {
      Volume * volume = [devices objectForKey: device];
      
      if([Volume isValid: volume])
        {
        volume.indent = self.indent + 1;
        
        [attributedString 
          appendAttributedString: volume.attributedStringValue];
        }
      }
    }
  }
  
// Build the XML value.
- (void) buildXMLValue: (XMLBuilder *) xml
  {
  [xml startElement: @"drive"];
  
  [super buildXMLValue: xml];
  
  [xml addElement: @"model" value: self.model];
  [xml addElement: @"revision" value: self.revision];
  [xml addElement: @"serial" value: self.serial];
  [xml addElement: @"bus" value: self.bus];
  [xml addElement: @"internal" boolValue: self.internal];
  [xml addElement: @"busspeed" value: self.busSpeed];
  [xml addElement: @"solidstate" boolValue: self.solidState];
  [xml addElement: @"smartstatus" value: self.SMARTStatus];
  
  if(self.solidState)
    [xml addElement: @"TRIM" boolValue: self.TRIM];
    
  [xml endElement: @"drive"];
  }

// Is this a valid object?
+ (BOOL) isValid: (nullable Drive *) drive
  {
  return (drive != nil) && [drive respondsToSelector: @selector(isDrive)];
  }

@end
