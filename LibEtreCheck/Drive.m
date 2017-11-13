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

// Constructor with output from diskutil info -plist.
- (nullable instancetype) initWithDiskUtilInfo: 
  (nullable NSDictionary *) plist
  {
  self = [super initWithDiskUtilInfo: plist];
  
  if(self != nil)
    {
    self.model = [plist objectForKey: @"MediaName"];
    self.bus = [plist objectForKey: @"BusProtocol"];
    self.solidState = [[plist objectForKey: @"SolidState"] boolValue];
    self.internal = [[plist objectForKey: @"Internal"] boolValue];
    self.SMARTStatus = [plist objectForKey: @"SMARTStatus"];
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
          @"%@ %@%@ %@\n",
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
              
  // Don't forget the volumes.
  NSArray * volumeDevices = 
    [StorageDevice sortDeviceIdenifiers: [self.volumes allObjects]];

  for(NSString * device in volumeDevices)
    {
    Volume * volume = [[[Model model] storageDevices] objectForKey: device];
    
    if([volume respondsToSelector: @selector(isVolume)])
      {
      [attributedString appendString: @"    "];
      [attributedString 
        appendAttributedString: volume.attributedStringValue];
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

@end
