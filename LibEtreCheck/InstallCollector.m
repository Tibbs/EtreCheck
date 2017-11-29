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
  
  if([installs count])
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
    
    // Only print the most recent install for each item.
    NSMutableDictionary * installsByName = [NSMutableDictionary new];
    NSMutableArray * installsToPrint = [NSMutableArray new];
    
    for(NSDictionary * install in installs)
      {
      NSString * name = [install objectForKey: @"_name"];
      NSDate * date = [install objectForKey: @"install_date"];
      NSString * source = [install objectForKey: @"package_source"];
      
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
        
        if(currentInstall != nil)
          {
          NSDate * currentDate = 
            [currentInstall objectForKey: @"install_date"];
            
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
        {
        NSString * name = [install objectForKey: @"_name"];
        NSDate * date = [install objectForKey: @"install_date"];
        NSString * version = [install objectForKey: @"install_version"];

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
  
    if(plist && [plist count])
      {
      NSArray * items =
        [[plist objectAtIndex: 0] objectForKey: @"_items"];
        
      if([items count])
        for(NSDictionary * item in items)
          [installs addObject: item];
      }
    }

  [subProcess release];
  
  [installs
    sortUsingComparator:
      ^NSComparisonResult(id _Nonnull obj1, id _Nonnull obj2)
      {
      NSDictionary * install1 = obj1;
      NSDictionary * install2 = obj2;
      
      NSDate * date1 = [install1 objectForKey: @"install_date"];
      NSDate * date2 = [install2 objectForKey: @"install_date"];
      
      if(date2 == nil)
        return NSOrderedDescending;
        
      return [date1 compare: date2];
      }];
  
  return installs;
  }

@end
