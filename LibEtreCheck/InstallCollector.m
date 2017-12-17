/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014-2017. All rights reserved.
 **********************************************************************/

#import "InstallCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"
#import "NSArray+Etresoft.h"
#import "SubProcess.h"
#import "XMLBuilder.h"
#import "LocalizedString.h"
#import "NSString+Etresoft.h"
#import "NSDate+Etresoft.h"
#import "NSSet+Etresoft.h"
#import "NSDictionary+Etresoft.h"

// Collect install information.
@implementation InstallCollector

// Constructor.
- (id) init
  {
  self = [super initWithName: @"install"];
  
  if(self != nil)
    {
    }
    
  return self;
  }

// Perform the collection.
- (void) performCollect
  {
  NSArray * installs = [self collectInstalls];
  
  if([NSArray isValid: installs] && (installs.count > 0))
    {
    NSDate * then =
      [[NSDate date] dateByAddingTimeInterval: -60 * 60 * 24 * 30];
  
    // I always want to print these critical Apple installs.
    NSSet * criticalAppleInstalls =
      [[NSSet alloc] 
        initWithObjects:
          @"XProtectPlistConfigData",
          @"MRTConfigData",
          @"MRT Configuration Data",
          @"Gatekeeper Configuration Data",
          @"EFI Allow List",
          nil];
    
    if(criticalAppleInstalls == nil)
      return;
      
    NSMutableArray * installsToPrint = [NSMutableArray new];
    
    if(installsToPrint == nil)
      {
      [criticalAppleInstalls release];
      
      return;
      }
      
    for(NSMutableDictionary * install in installs)
      if([NSDictionary isValid: install])
        {
        NSString * name = [install objectForKey: @"_name"];
        NSDate * date = [install objectForKey: @"install_date"];
        NSString * source = [install objectForKey: @"package_source"];
        
        if(![NSString isValid: name])
          continue;
          
        if(![NSDate isValid: date])
          continue;
          
        if(![NSString isValid: source])
          continue;
          
        // Any 3rd party installationsn in the last 30 days.
        if([source isEqualToString: @"package_source_other"])
          {
          if([then compare: date] == NSOrderedAscending)
            [installsToPrint addObject: install];
          }
          
        // The last critical Apple installation.
        else if([source isEqualToString: @"package_source_apple"])
          {
          bool critical = false;
          
          if([criticalAppleInstalls containsObject: name])
            critical = true;
          else if([name hasPrefix: @"Security Update"])
            critical = true;
              
          if(critical)
            [install setObject: @YES forKey: @"critical"];
            
          if(critical || [then compare: date] == NSOrderedAscending)
            [installsToPrint addObject: install];
          }
        }
    
    [self printInstalls: installsToPrint];
    
    [installsToPrint release];
    [criticalAppleInstalls release];
    
    [self.result appendCR];
    }
  }

// Collect installs.
- (NSArray *) collectInstalls
  {
  NSArray * args =
    @[
      @"-xml",
      @"SPInstallHistoryDataType"
    ];
  
  NSMutableArray * installs = [NSMutableArray array];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  if([subProcess execute: @"/usr/sbin/system_profiler" arguments: args])
    {
    NSArray * plist =
      [NSArray readPropertyListData: subProcess.standardOutput];
  
    if([NSArray isValid: plist])
      {
      NSDictionary * results = [plist objectAtIndex: 0];
      
      if([NSDictionary isValid: results])
        {
        NSArray * items = [results objectForKey: @"_items"];
          
        if([NSArray isValid: items])
          for(NSDictionary * item in items)
            {
            NSMutableDictionary * install = 
              [[NSMutableDictionary alloc] initWithDictionary: item];
            
            [installs addObject: install];
            
            [install release];
            }
        }
      }
    }

  [subProcess release];
  
  [installs
    sortUsingComparator:
      ^NSComparisonResult(id _Nonnull obj1, id _Nonnull obj2)
      {
      NSDictionary * install1 = obj1;
      NSDictionary * install2 = obj2;
      
      NSDate * date1 = nil;
      NSDate * date2 = nil;
      
      if([NSDictionary isValid: install1])
        date1 = [install1 objectForKey: @"install_date"];
      
      if([NSDictionary isValid: install2])
        date2 = [install2 objectForKey: @"install_date"];
      
      if(![NSDate isValid: date2])
        return NSOrderedDescending;
        
      if((date2 != nil) && [NSDate isValid: date1])
        return [date1 compare: date2];
        
      return NSOrderedSame;
      }];
  
  return installs;
  }

// Remove duplicates.
- (NSArray *) removeDuplicates: (NSArray *) installs
  {
  NSMutableDictionary * lastInstallsByNameAndVersion = 
    [NSMutableDictionary new];
  
  for(NSDictionary * install in installs)
    if([NSDictionary isValid: install])
      {
      NSString * name = [install objectForKey: @"_name"];
        
      [lastInstallsByNameAndVersion setObject: install forKey: name];
      }
      
  NSMutableSet * lastInstalls = 
    [[NSMutableSet alloc] 
      initWithArray: [lastInstallsByNameAndVersion allValues]];
  
  [lastInstallsByNameAndVersion release];
  
  NSMutableArray * installsToPrint = [NSMutableArray array];
  
  for(NSDictionary * install in installs)
    if([lastInstalls containsObject: install])
      [installsToPrint addObject: install];
      
  [lastInstalls release];
  
  return installsToPrint;
  }
  
// Print installs.
- (void) printInstalls: (NSArray *) installs
  {
  NSArray * installsToPrint = [self removeDuplicates: installs];
  
  if(installsToPrint.count > 0)
    {
    [self.result appendAttributedString: [self buildTitle]];

    for(NSDictionary * install in installsToPrint)
      if([NSDictionary isValid: install])
        {
        NSString * name = [install objectForKey: @"_name"];
        NSDate * date = [install objectForKey: @"install_date"];
        NSString * version = [install objectForKey: @"install_version"];
        NSString * source = [install objectForKey: @"package_source"];
        NSNumber * critical = [install objectForKey: @"critical"];

        if(![NSString isValid: name])
          continue;
          
        if(![NSDate isValid: date])
          continue;
          
        if(![NSString isValid: version])
          continue;
        
        NSString * installDate =
          [Utilities installDateAsString: date];

        [self.xml startElement: @"package"];
        
        [self.xml addElement: @"name" value: name];
        [self.xml addElement: @"version" value: version];
        [self.xml addElement: @"installdate" date: date];
        [self.xml addElement: @"source" value: source];
        [self.xml addElement: @"critical" boolValue: critical.boolValue];
        
        [self.xml endElement: @"package"];
        
        // TODO: Add source.
        [self.result
          appendString:
            [NSString
              stringWithFormat:
                ECLocalizedString(@"    %@: %@ (%@)\n"),
                name,
                version,
                installDate]];
          
        }
      
    [self.result appendString: @"\n"];
    
    [self.result
      appendString: ECLocalizedString(@"installsincomplete")];
    }
  }
  
@end
