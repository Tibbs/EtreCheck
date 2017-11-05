/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014-2017. All rights reserved.
 **********************************************************************/

#import "FirewireCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"
#import "NSArray+Etresoft.h"
#import "SubProcess.h"
#import "XMLBuilder.h"
#import "Model.h"
#import "Drive.h"
#import "Volume.h"

// Collect information about Firewire devices.
@implementation FirewireCollector

// Constructor.
- (id) init
  {
  self = [super initWithName: @"firewire"];
  
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
      @"SPFireWireDataType"
    ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  //subProcess.debugStandardOutput =
  //  [NSData dataWithContentsOfFile: @"/tmp/SPFireWireDataType.xml"];

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
        [self printFirewireDevice: device indent: @"    " found: & found];
        
      if(found)
        [self.result appendCR];
      }
    }
    
  [subProcess release];
  }

// Print a single Firewire device.
- (void) printFirewireDevice: (NSDictionary *) device
  indent: (NSString *) indent found: (bool *) found
  {
  [self.model startElement: @"node"];

  NSString * name = [device objectForKey: @"_name"];
  NSString * manufacturer = [device objectForKey: @"device_manufacturer"];
  NSString * size = [device objectForKey: @"size"];
  NSString * max_device_speed = [device objectForKey: @"max_device_speed"];
  NSString * connected_speed = [device objectForKey: @"connected_speed"];
  
  [self.model addElement: @"manufacturer" value: manufacturer];
  [self.model addElement: @"name" value: name];  
  [self.model addElement: @"size" value: size];

  if(!size)
    size = @"";
    
  if([max_device_speed hasSuffix: @"_speed"])
    max_device_speed =
      [max_device_speed substringToIndex: [max_device_speed length] - 6];
    
  if([connected_speed hasSuffix: @"_speed"])
    connected_speed =
      [connected_speed substringToIndex: [connected_speed length] - 6];

  [self.model addElement: @"maxdevicespeed" value: max_device_speed];
  [self.model addElement: @"connectedspeed" value: connected_speed];

  NSString * speed =
    (max_device_speed && connected_speed)
      ? [NSString
        stringWithFormat: @"%@ - %@ max", connected_speed, max_device_speed]
      : @"";
      
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
            @"%@%@ %@ %@ %@\n", indent, manufacturer, name, speed, size]];
            
    indent = [NSString stringWithFormat: @"%@    ", indent];
    }

  // There could be more devices.
  NSDictionary * devices = [device objectForKey: @"_items"];
  
  if(!devices)
    devices = [device objectForKey: @"units"];
    
  if(devices)
    for(NSDictionary * device in devices)
      {
      NSString * deviceIdentifier = [device objectForKey: @"bsd_name"];
      
      if(deviceIdentifier.length > 0)
        {
        Drive * drive = 
          [[[Model model] storageDevices] objectForKey: deviceIdentifier];
          
        drive.bus = @"FireWire";
        drive.busSpeed = connected_speed;
        
        NSMutableString * model = [NSMutableString new];
        
        [model appendString: manufacturer];
        
        if(![name hasPrefix: manufacturer])
          {
          [model appendString: @" "];
          [model appendString: name];
          }
          
        drive.model = model;
        
        NSArray * volumes = [device objectForKey: @"volumes"];
        
        if([volumes respondsToSelector: @selector(isEqualToArray:)])
          for(NSDictionary * volumeItem in volumes)
            {
            NSString * volumeDevice = 
              [volumeItem objectForKey: @"bsd_name"];
            
            if(volumeDevice.length > 0)
              {
              Volume * volume = 
                [[[Model model] storageDevices] objectForKey: volumeDevice];
              
              [volume addContainingDevice: deviceIdentifier];
              }
            }

        [model release];
        }
        
      [self printFirewireDevice: device indent: indent found: found];
      }

  [self.model endElement: @"node"];
  }

@end
