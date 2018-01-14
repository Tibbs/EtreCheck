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
#import "NSDictionary+Etresoft.h"
#import "NSArray+Etresoft.h"
#import "NSString+Etresoft.h"

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
  NSString * key = @"SPFireWireDataType";
  
  NSArray * args =
    @[
      @"-xml",
      key
    ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  [subProcess loadDebugOutput: [self.model debugInputPath: key]];      
  [subProcess saveDebugOutput: [self.model debugOutputPath: key]];

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
          {
          for(NSDictionary * device in devices)
            if([NSDictionary isValid: device])
              [self 
                printFirewireDevice: device indent: @"    " found: & found];
            
          if(found)
            [self.result appendCR];
          }
        }
      }
    }
    
  [subProcess release];
  }

// Print a single Firewire device.
- (void) printFirewireDevice: (NSDictionary *) device
  indent: (NSString *) indent found: (bool *) found
  {
  NSString * name = [device objectForKey: @"_name"];
  NSString * identifier = [device objectForKey: @"bsd_name"];
  NSString * manufacturer = [device objectForKey: @"device_manufacturer"];
  NSString * size = [device objectForKey: @"size"];
  NSString * max_device_speed = [device objectForKey: @"max_device_speed"];
  NSString * connected_speed = [device objectForKey: @"connected_speed"];
  
  if(![NSString isValid: name])
    return;
    
  NSDictionary * storageDevices = [self.model storageDevices];
  
  if(![NSDictionary isValid: storageDevices])
    return;
    
  [self.xml startElement: @"node"];

  [self.xml addElement: @"manufacturer" value: manufacturer];
  [self.xml addElement: @"name" value: name];  
  [self.xml addElement: @"size" value: size];

  if(![NSString isValid: size])
    size = @"";
    
  if([max_device_speed hasSuffix: @"_speed"])
    max_device_speed =
      [max_device_speed substringToIndex: [max_device_speed length] - 6];
    
  if([connected_speed hasSuffix: @"_speed"])
    connected_speed =
      [connected_speed substringToIndex: [connected_speed length] - 6];

  [self.xml addElement: @"maxdevicespeed" value: max_device_speed];
  [self.xml addElement: @"connectedspeed" value: connected_speed];

  NSString * speed = @"";
  
  if([NSString isValid: max_device_speed])
    {
    if([NSString isValid: connected_speed])
      speed =
        [NSString
          stringWithFormat:
            @"%@ - %@ max", connected_speed, max_device_speed];
    else
      speed = [NSString stringWithFormat: @"%@ max", max_device_speed];
    }
    
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
  NSArray * nodes = [device objectForKey: @"_items"];
  
  if(![NSArray isValid: nodes])
    nodes = [device objectForKey: @"units"];
    
  if([NSArray isValid: nodes])
    for(NSDictionary * node in nodes)
      if([NSDictionary isValid: node])
        {
        NSString * driveDevice = [node objectForKey: @"bsd_name"];
        
        if([NSString isValid: driveDevice])
          {
          Drive * drive = 
            [[self.model storageDevices] objectForKey: driveDevice];
            
          if([Drive isValid: drive])
            {
            drive.bus = @"FireWire";
            drive.busSpeed = connected_speed;
            
            NSMutableString * model = [NSMutableString new];
            
            if([NSString isValid: model])
              {
              if(manufacturer.length > 0)
                {
                [model appendString: manufacturer];
                
                if(![name hasPrefix: manufacturer])
                  {
                  [model appendString: @" "];
                  [model appendString: name];
                  }
                }
            
              drive.model = model;
              }
              
            [model release];
            }
          }
          
        [self printFirewireDevice: node indent: indent found: found];
        }

  NSArray * volumes = [device objectForKey: @"volumes"];

  if([NSArray isValid: volumes])
    for(NSDictionary * volumeItem in volumes)
      {
      NSString * volumeDevice =
        [volumeItem objectForKey: @"bsd_name"];
      
      if([NSString isValid: volumeDevice])
        {
        Volume * volume =
          [storageDevices objectForKey: volumeDevice];
        
        if([Volume isValid: volume])
          [volume addContainingDevice: identifier];
        }
      }

  [self.xml endElement: @"node"];
  }

@end
