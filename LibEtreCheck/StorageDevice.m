/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "StorageDevice.h"
#import "XMLBuilder.h"
#import "ByteCountFormatter.h"

@implementation StorageDevice

// The /dev/* device identifier.
@synthesize identifier = myIdentifier;

// The volume name.
@synthesize name = myName;

// The raw size of the device.
@synthesize size = mySize;

// The type of storage device.
@synthesize type = myType;

// Drive errors.
@synthesize errors = myErrors;

// RAID set UUID.
@synthesize RAIDSetUUID = myRAIDSetUUDI;

// RAID set members.
@synthesize RAIDSetMembers = myRAIDSetMembers;

// Get errors.
- (NSMutableArray *) errors
  {
  if(myErrors == nil)
    myErrors = [NSMutableArray new];
    
  return myErrors;
  }

// Constructor with output from diskutil info -plist.
- (nullable instancetype) initWithDiskUtilInfo: 
  (nullable NSDictionary *) plist
  {
  NSString * device = [plist objectForKey: @"DeviceIdentifier"];
  
  if(device.length > 0)
    {
    self = [super init];
    
    if(self != nil)
      {
      myIdentifier = [device retain];
      myName = [[plist objectForKey: @"MediaName"] retain];
      mySize = [[plist objectForKey: @"TotalSize"] unsignedIntegerValue];
      
      myRAIDSetUUID = [[plist objectForKey: @"RAIDSetUUID"] retain];
      myRAIDSetMembers = [[plist objectForKey: @"RAIDSetMembers"] retain];
      
      myByteCountFormatter = [ByteCountFormatter new];
      }
    }
    
  return self;
  }
  
// Destructor.
- (void) dealloc
  {
  [myByteCountFormatter release];
  [myIdentifier release];
  [myName release];
  [myType release];
  
  [super dealloc];
  }
  
// Build the XML value.
- (void) buildXMLValue: (XMLBuilder *) xml
  {
  // This class should never be directly instatiated, so omit the top
  // level element.
  [xml addElement: @"identifier" value: self.identifier];
  [xml addElement: @"name" value: self.name];
  [xml addElement: @"size" unsignedIntegerValue: self.size];
  [xml addElement: @"type" value: self.type];

  // I can't use XMLBuilder addArray:values: because values here are just
  // NSString.
  if(self.errors.count > 0)
    {
    [xml startElement: @"errors"];
    
    for(NSString * error in self.errors)
      [xml addElement: @"error" value: error];
      
    [xml endElement: @"errors"];
    }
  }

// Format a number into a byte count string.
- (nonnull NSString *) byteCountString: (NSUInteger) value
  {
  NSString * string = [myByteCountFormatter stringFromByteCount: value];
  
  if(string != nil)
    return string;
    
  return @"";
  }
  
@end
