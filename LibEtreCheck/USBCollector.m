/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014-2017. All rights reserved.
 **********************************************************************/

#import "USBCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"
#import "NSArray+Etresoft.h"
#import "NSDictionary+Etresoft.h"
#import "NSString+Etresoft.h"
#import "SubProcess.h"
#import "XMLBuilder.h"
#import "Drive.h"
#import "Model.h"
#import "Volume.h"
#import "LocalizedString.h"

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
  
    if([NSArray isValid: plist])
      {
      NSDictionary * results = [plist objectAtIndex: 0];
      
      if([NSDictionary isValid: results])
        {
        bool found = NO;
        
        NSArray * devices = [results objectForKey: @"_items"];
          
        if([NSArray isValid: devices])
          for(NSDictionary * device in devices)
            [self printUSBDevice: device indent: @"    " found: & found];

        if(found)
          [self.result appendCR];
        }
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
  [self.xml startElement: @"node"];
  
  NSString * name = [device objectForKey: @"_name"];
  NSString * manufacturer = [device objectForKey: @"manufacturer"];
  NSString * size = [device objectForKey: @"size"];

  if(![NSString isValid: manufacturer])
    manufacturer = [device objectForKey: @"f_manufacturer"];

  if([NSString isValid: manufacturer])
    manufacturer = [self cleanPath: manufacturer];
  
  name = [self cleanPath: name];
  
  if(![NSString isValid: name])
    return;
    
  [self.xml addElement: @"manufacturer" value: manufacturer];
  [self.xml addElement: @"name" value: name];  
  [self.xml addElement: @"size" value: size];
  
  if(![NSString isValid: size])
    size = @"";
    
  if([NSString isValid: manufacturer])
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
  
  // There could be more devices.
  [self printMoreDevices: device indent: indent found: found];
  
  [self.xml endElement: @"node"];
  }
  
// Print more devices.
- (void) printMoreDevices: (NSDictionary *) device
  indent: (NSString *) indent found: (bool *) found
  {
  NSArray * devices = [device objectForKey: @"_items"];
  
  if(![NSArray isValid: devices])
    devices = [device objectForKey: @"units"];
    
  if([NSArray isValid: devices])
    {
    for(NSDictionary * device in devices)
      if([NSDictionary isValid: device])
        [self printUSBDevice: device indent: indent found: found];
    }
    
  else
  
    // Print a USB drive.
    [self printUSBDrive: device indent: indent];
  }

// Print a USB drive.
- (void) printUSBDrive: (NSDictionary *) device
  indent: (NSString *) indent
  {
  NSArray * media = [device objectForKey: @"Media"];
  
  if([NSArray isValid: media] && (media.count > 0))
    {
    NSString * name = [device objectForKey: @"_name"];
    NSString * manufacturer = [device objectForKey: @"manufacturer"];
    NSString * serial = [device objectForKey: @"serial_num"];
    NSString * speed = [device objectForKey: @"device_speed"];
      
    NSMutableString * model = [NSMutableString new];
    
    if([NSString isValid: manufacturer])
      [model appendString: manufacturer];
    
    if([NSString isValid: name])
      {
      if(model.length > 0)
        [model appendString: @" "];
        
      [model appendString: name];  
      }
      
    [self.xml startElement: @"drives"];
    
    for(NSDictionary * item in media)
      {
      NSString * device = [item objectForKey: @"bsd_name"];

      if(![NSString isValid: device])
        continue;
        
      [self.xml addElement: @"device" value: device];
      
      Drive * drive = [[self.model storageDevices] objectForKey: device];
      
      if([Drive isValid: drive])
        {
        drive.name = name;
        
        drive.bus = @"USB";
        drive.model = model;
        drive.serial = serial;  
        drive.busSpeed = ECLocalizedStringFromTable(speed, @"System");    

        NSArray * volumes = [item objectForKey: @"volumes"];
        
        if([NSArray isValid: volumes])
          for(NSDictionary * volumeItem in volumes)
            {
            NSString * volumeDevice = 
              [volumeItem objectForKey: @"bsd_name"];
            
            if([NSString isValid: volumeDevice])
              {
              Volume * volume = 
                [[self.model storageDevices] objectForKey: volumeDevice];
              
              if([Volume isValid: volume])
                [volume addContainingDevice: device];
              }
            }
        }
      }
    
    [model release];
    
    [self.xml endElement: @"drives"];
    }
  }

@end
