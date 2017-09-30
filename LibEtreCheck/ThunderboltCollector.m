/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014-2017. All rights reserved.
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
      @"SPThunderboltDataType"
    ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  //subProcess.debugStandardOutput =
  //  [NSData dataWithContentsOfFile: @"/tmp/SPThunderboltDataType.xml"];

  bool dataFound = NO;
      
  if([subProcess execute: @"/usr/sbin/system_profiler" arguments: args])
    {
    NSArray * plist =
      [NSArray readPropertyListData: subProcess.standardOutput];
  
    if(plist && [plist count])
      {
      NSDictionary * devices =
        [[plist objectAtIndex: 0] objectForKey: @"_items"];
        
      for(NSDictionary * device in devices)
        dataFound =
          [self
            printThunderboltDevice: device
            indent: @"    "
            dataFound: dataFound];
        
      if(dataFound)
        [self.result appendCR];
      }
    }
    
  [subProcess release];
  
  dataFound = [self collectSerialATA: dataFound];
  [self collectNVMExpress: dataFound];
  }

// Collect information about a single Thunderbolt device.
- (BOOL) printThunderboltDevice: (NSDictionary *) device
  indent: (NSString *) indent dataFound: (BOOL) dataFound
  {
  [self.model startElement: @"node"];

  NSString * name = [device objectForKey: @"_name"];
  NSString * vendor_name = [device objectForKey: @"vendor_name_key"];
        
  [self.model addElement: @"manufacturer" value: vendor_name];
  [self.model addElement: @"name" value: name];  

  if(vendor_name)
    {
    if(!dataFound)
      {
      [self.result appendAttributedString: [self buildTitle]];
      
      dataFound = YES;
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
  dataFound =
    [self printMoreDevices: device indent: indent dataFound: dataFound];
    
  [self.model endElement: @"node"];

  return dataFound;
  }

// Print more devices.
- (BOOL) printMoreDevices: (NSDictionary *) device
  indent: (NSString *) indent dataFound: (BOOL) dataFound
  {
  NSDictionary * devices = [device objectForKey: @"_items"];
  
  if(!devices)
    devices = [device objectForKey: @"units"];
    
  if(devices)
    for(NSDictionary * device in devices)
      {
      BOOL printed =
        [self
          printThunderboltDevice: device
          indent: indent
          dataFound: dataFound];
          
      if(printed)
        dataFound = YES;
      }
      
  return dataFound;
  }

// Perform the collection for old Serial ATA controllers.
- (BOOL) collectSerialATA: (BOOL) dataFound
  {
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
          {
          BOOL printed =
            [self 
              printController: controller 
              type: @"SerialATA" 
              dataFound: dataFound];
              
          if(printed)
            dataFound = YES;
          }
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
          {
          BOOL printed =
            [self 
              printController: controller 
              type: @"NVMExpress" 
              dataFound: dataFound];
              
          if(printed)
            dataFound = YES;
          }
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
