/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014-2017. All rights reserved.
 **********************************************************************/

#import "USBCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"
#import "NSArray+Etresoft.h"
#import "SubProcess.h"

// Collect information about USB devices.
@implementation USBCollector

// Constructor.
- (id) init
  {
  self = [super initWithName: @"usb"];
  
  if(self != nil)
    {
    }
    
  return self;
  }

// Perform the collection.
- (void) performCollect
  {
  NSArray * args =
    @[
      @"-xml",
      @"SPUSBDataType"
    ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  //subProcess.debugStandardOutput =
  //  [NSData dataWithContentsOfFile: @"/tmp/SPUSBDataType.xml"];

  if([subProcess execute: @"/usr/sbin/system_profiler" arguments: args])
    {
    NSArray * plist =
      [NSArray readPropertyListData: subProcess.standardOutput];
  
    if(plist && [plist count])
      {
      bool found = NO;
      
      NSDictionary * devices =
        [[plist objectAtIndex: 0] objectForKey: @"_items"];
        
      for(NSDictionary * device in devices)
        [self printUSBDevice: device indent: @"    " found: & found];

      if(found)
        [self.result appendCR];
      }
    }
  else
    [self.result appendCR];
    
  [subProcess release];
  }

// Print a single USB device.
- (void) printUSBDevice: (NSDictionary *) device
  indent: (NSString *) indent found: (bool *) found
  {
  NSString * name = [device objectForKey: @"_name"];
  NSString * manufacturer = [device objectForKey: @"manufacturer"];
  NSString * size = [device objectForKey: @"size"];

  if(!manufacturer)
    manufacturer = [device objectForKey: @"f_manufacturer"];

  manufacturer = [Utilities cleanPath: manufacturer];
  name = [Utilities cleanPath: name];
  
  if(!size)
    size = @"";
    
  if(manufacturer)
    {
    if(!*found)
      {
      [self.result appendAttributedString: [self buildTitle]];
      
      *found = YES;
      }

    [self.result
      appendString:
        [NSString
          stringWithFormat:
            @"%@%@ %@ %@\n", indent, manufacturer, name, size]];
            
    indent = [NSString stringWithFormat: @"%@    ", indent];
    }
  
  [self collectSMARTStatus: device indent: indent];
  
  // There could be more devices.
  [self printMoreDevices: device indent: indent found: found];
  }
  
// Print more devices.
- (void) printMoreDevices: (NSDictionary *) device
  indent: (NSString *) indent found: (bool *) found
  {
  NSDictionary * devices = [device objectForKey: @"_items"];
  
  if(!devices)
    devices = [device objectForKey: @"units"];
    
  if(devices)
    for(NSDictionary * device in devices)
      [self printUSBDevice: device indent: indent found: found];
  
  else
  
    // Print all volumes on the device.
    [self printUSBController: device indent: indent];
  }

// Print disks attached to a single Serial ATA controller.
- (BOOL) printUSBController: (NSDictionary *) controller
  indent: (NSString *) indent
  {
  BOOL dataFound = NO;
  
  NSDictionary * disks = [controller objectForKey: @"Media"];
  
  for(NSDictionary * disk in disks)
    {
    NSString * diskName = [disk objectForKey: @"_name"];
    NSString * diskDevice = [disk objectForKey: @"bsd_name"];
    NSString * diskSize = [disk objectForKey: @"size"];
    NSString * UUID = [disk objectForKey: @"volume_uuid"];
    
    if(!diskDevice)
      diskDevice = @"";
      
    if(!diskSize)
      diskSize = @"";
    else
      diskSize =
        [NSString
          stringWithFormat: @": (%@)", [Utilities translateSize: diskSize]];

    if(UUID)
      [self.volumes setObject: disk forKey: UUID];

    [self.result
      appendString:
        [NSString
          stringWithFormat:
            @"%@%@ %@%@\n",
            indent, diskName ? diskName : @"-", diskDevice, diskSize]];
    
    [self
      printDiskVolumes: disk
      indent: [indent stringByAppendingString: @"    "]];
    
    dataFound = YES;
    }
    
  return dataFound;
  }

// Print the volumes on a disk.
- (void) printDiskVolumes: (NSDictionary *) disk indent: (NSString *) indent
  {
  NSArray * volumes = [disk objectForKey: @"volumes"];
  
  if(volumes && [volumes count])
    for(NSDictionary * volume in volumes)
      [self printVolume: volume indent: indent];
  }

@end
