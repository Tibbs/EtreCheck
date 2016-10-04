/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
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
  
  if(self)
    {
    return self;
    }
    
  return nil;
  }

// Perform the collection.
- (void) performCollection
  {
  [self
    updateStatus: NSLocalizedString(@"Checking USB information", NULL)];

  NSArray * args =
    @[
      @"-xml",
      @"SPUSBDataType"
    ];
  
  // result = [NSData dataWithContentsOfFile: @"/tmp/etrecheck/SPUSBDataType.xml"];
  
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
        [self printUSBDevice: device indent: @"    " found: & found];

      if(found)
        [self.result appendCR];
      }
    }
  else
    [self.result appendCR];
    
  [subProcess release];
  
  dispatch_semaphore_signal(self.complete);
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
    [self printDiskVolumes: device];
  }

@end
