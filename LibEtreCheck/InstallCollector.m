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
      
    // Only print the most recent install for each item.
    NSMutableDictionary * installsByName = [NSMutableDictionary new];

    if(installsByName == nil)
      {
      [criticalAppleInstalls release];
      
      return;
      }
      
    NSMutableArray * installsToPrint = [NSMutableArray new];
    
    if(installsToPrint == nil)
      {
      [installsByName release];
      [criticalAppleInstalls release];
      
      return;
      }
      
    for(NSDictionary * install in installs)
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
        else if([criticalAppleInstalls containsObject: name])
          {
          // Get the current install that matches the name.
          NSDictionary * currentInstall = 
            [installsByName objectForKey: name];
          
          if([NSDictionary isValid: currentInstall])
            {
            NSDate * currentDate = 
              [currentInstall objectForKey: @"install_date"];
              
            if([NSDate isValid: currentDate])
            
              // If I have an older install, remove it.
              if([currentDate compare: date] == NSOrderedAscending)
                [installsToPrint removeObject: currentInstall];
            }
            
          [installsToPrint addObject: install];
          [installsByName setObject: install forKey: name];
          }
        }
    
    [installsByName release];
         
    if(installsToPrint.count > 0)
      {
      [self.result appendAttributedString: [self buildTitle]];

      for(NSDictionary * install in installsToPrint)
        if([NSDictionary isValid: install])
          {
          NSString * name = [install objectForKey: @"_name"];
          NSDate * date = [install objectForKey: @"install_date"];
          NSString * version = [install objectForKey: @"install_version"];

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
          
          [self.xml endElement: @"package"];
          
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
            [installs addObject: item];
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

@end
