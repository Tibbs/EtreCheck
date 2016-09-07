/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "FirewireCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"
#import "NSArray+Etresoft.h"
#import "SubProcess.h"

// Collect information about Firewire devices.
@implementation FirewireCollector

// Constructor.
- (id) init
  {
  self = [super initWithName: @"firewire"];
  
  if(self)
    {
    return self;
    }
    
  return nil;
  }

// Perform the collection.
- (void) collect
  {
  [self
    updateStatus:
      NSLocalizedString(@"Checking Firewire information", NULL)];

  NSArray * args =
    @[
      @"-xml",
      @"SPFireWireDataType"
    ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
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
    
  dispatch_semaphore_signal(self.complete);
  }

// Print a single Firewire device.
- (void) printFirewireDevice: (NSDictionary *) device
  indent: (NSString *) indent found: (bool *) found
  {
  NSString * name = [device objectForKey: @"_name"];
  NSString * manufacturer = [device objectForKey: @"device_manufacturer"];
  NSString * size = [device objectForKey: @"size"];
  NSString * max_device_speed = [device objectForKey: @"max_device_speed"];
  NSString * connected_speed = [device objectForKey: @"connected_speed"];
  
  if(!size)
    size = @"";
    
  if([max_device_speed hasSuffix: @"_speed"])
    max_device_speed =
      [max_device_speed substringToIndex: [max_device_speed length] - 6];
    
  if([connected_speed hasSuffix: @"_speed"])
    connected_speed =
      [connected_speed substringToIndex: [connected_speed length] - 6];

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
      [self printFirewireDevice: device indent: indent found: found];

  // Print all volumes on the device.
  [self printDiskVolumes: device];
  }

@end
