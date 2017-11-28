/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "StorageDevice.h"
#import "XMLBuilder.h"
#import "ByteCountFormatter.h"
#import "Utilities.h"

@implementation StorageDevice

// The /dev/* device identifier.
@synthesize identifier = myIdentifier;

// The volume name.
@synthesize name = myName;

// The clean name.
@synthesize cleanName = myCleanName;

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

// A drive has 0 or more volumes indexed by device id.
// Use device identifier only to avoid cicular references.
@synthesize volumes = myVolumes;

// Get volumes.
- (NSMutableSet *) volumes
  {
  if(myVolumes == nil)
    myVolumes = [NSMutableSet new];
    
  return myVolumes;
  }
  
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
  [myVolumes release];
  
  [super dealloc];
  }
  
// Build the XML value.
- (void) buildXMLValue: (XMLBuilder *) xml
  {
  // This class should never be directly instatiated, so omit the top
  // level element.
  [xml addElement: @"device" value: self.identifier];
  [xml addElement: @"name" value: self.name];
  [xml addElement: @"cleanname" value: self.cleanName];
  [xml 
    addElement: @"size" 
    valueWithUnits: [myByteCountFormatter stringFromByteCount: self.size]];
  [xml addElement: @"type" value: self.type];
    
  // Don't forget the volumes.
  NSArray * volumeDevices = 
    [StorageDevice sortDeviceIdenifiers: [self.volumes allObjects]];

  if(volumeDevices.count > 0)
    {
    [xml startElement: @"volumes"];
    
    for(NSString * device in volumeDevices)
      [xml addElement: @"device" value: device];
    
    [xml endElement: @"volumes"];
    }

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
  
// Sort an array of storage device identifiers.
+ (nonnull NSArray *) sortDeviceIdenifiers: (nonnull NSArray *) devices
  {
  // Carefully sort the devices.
  return
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
  }

@end
