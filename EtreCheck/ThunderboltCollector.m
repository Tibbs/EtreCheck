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

// Collect information about Thunderbolt devices.
@implementation ThunderboltCollector

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    self.name = @"thunderbolt";
    self.title = NSLocalizedStringFromTable(self.name, @"Collectors", NULL);
    }
    
  return self;
  }

// Perform the collection.
- (void) collect
  {
  [self
    updateStatus:
      NSLocalizedString(@"Checking Thunderbolt information", NULL)];

  NSArray * args =
    @[
      @"-xml",
      @"SPThunderboltDataType"
    ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  //subProcess.debugStandardOutput =
  //  [NSData dataWithContentsOfFile: @"/tmp/SPThunderboltDataType.xml"];

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
  
  BOOL found = [self collectSerialATA];
  found = [self collectNVMExpress: found];
  
  dispatch_semaphore_signal(self.complete);
  }

// Collect information about a single Thunderbolt device.
- (void) printThunderboltDevice: (NSDictionary *) device
  indent: (NSString *) indent found: (bool *) found
  {
  NSString * name = [device objectForKey: @"_name"];
  NSString * vendor_name = [device objectForKey: @"vendor_name_key"];
        
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
      [self printThunderboltDevice: device indent: indent found: found];
  }

// Perform the collection for old Serial ATA controllers.
- (BOOL) collectSerialATA
  {
  BOOL dataFound = NO;
      
  NSArray * args =
    @[
      @"-xml",
      @"SPSerialATADataType"
    ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  //subProcess.debugStandardOutput =
  //  [NSData
  //    dataWithContentsOfFile: @"/tmp/SPSerialATADataType.xml"];
    
  if([subProcess execute: @"/usr/sbin/system_profiler" arguments: args])
    {
     NSArray * plist =
       [NSArray readPropertyListData: subProcess.standardOutput];
  
    if(plist && [plist count])
      {
      NSDictionary * controllers =
        [[plist objectAtIndex: 0] objectForKey: @"_items"];
        
      for(NSDictionary * controller in controllers)
        if([self shouldPrintController: controller])
          if([self printSerialATAController: controller])
            dataFound = YES;
      }
    }

  [subProcess release];
  
  return dataFound;
  }

// Perform the collection for new NVM controllers.
- (BOOL) collectNVMExpress: (BOOL) dataFound
  {
  NSArray * args =
    @[
      @"-xml",
      @"SPNVMeDataType"
    ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  [subProcess autorelease];
  
  if([subProcess execute: @"/usr/sbin/system_profiler" arguments: args])
    {
    NSArray * plist =
      [NSArray readPropertyListData: subProcess.standardOutput];
  
    if(plist && [plist count])
      {
      NSDictionary * controllers =
        [[plist objectAtIndex: 0] objectForKey: @"_items"];
        
      for(NSDictionary * controller in controllers)
        if([self shouldPrintController: controller])
          if([self printNVMExpressController: controller])
            dataFound = YES;
      }
    }

  return dataFound;
  }

// Should this controller be printed here?
- (BOOL) shouldPrintController: (NSDictionary *) controller
  {
  NSString * name = [controller objectForKey: @"_name"];
  
  if([name hasPrefix: @"Thunderbolt"])
    return YES;
    
  return NO;
  }

@end
