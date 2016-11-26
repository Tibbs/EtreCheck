/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "ThunderboltCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"
#import "NSArray+Etresoft.h"
#import "SubProcess.h"
#import "XMLBuilder.h"

// Collect information about Thunderbolt devices.
@implementation ThunderboltCollector

// Constructor.
- (id) init
  {
  self = [super initWithName: @"thunderbolt"];
  
  if(self)
    {
    return self;
    }
    
  return nil;
  }

// Perform the collection.
- (void) performCollection
  {
  // TODO: Sandbox does this work?
  [self
    updateStatus:
      NSLocalizedString(@"Checking Thunderbolt information", NULL)];

  NSArray * args =
    @[
      @"-xml",
      @"SPThunderboltDataType"
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
        [self
          printThunderboltDevice: device indent: @"    " found: & found];
        
      if(found)
        [self.result appendCR];
      }
    }
    
  [subProcess release];
  
  dispatch_semaphore_signal(self.complete);
  }

// Collect information about a single Thunderbolt device.
- (void) printThunderboltDevice: (NSDictionary *) device
  indent: (NSString *) indent found: (bool *) found
  {
  [self.XML startElement: @"device"];

  NSString * name = [device objectForKey: @"_name"];
  NSString * vendor_name = [device objectForKey: @"vendor_name_key"];
        
  [self.XML addElement: @"name" value: name];

  if(vendor_name)
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
            @"%@%@ %@\n", indent, vendor_name, name]];
            
    [self.XML
      addElement: @"manufacturer" value: vendor_name];

    indent = [NSString stringWithFormat: @"%@    ", indent];
    }
  
  [self collectSMARTStatus: device indent: indent];
  
  // There could be more devices.
  [self printMoreDevices: device indent: indent found: found];

  [self.XML endElement: @"device"];
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
      [self printThunderboltDevice: device indent: indent found: found];

  // Print all volumes on the device.
  [self printDiskVolumes: device];
  }

@end
