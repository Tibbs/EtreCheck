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
  
  int printCount = 0;
  
  if([installs count])
    {
    NSDate * then =
      [[NSDate date] dateByAddingTimeInterval: -60 * 60 * 24 * 30];
  
    for(NSDictionary * install in installs)
      {
      NSString * name = [install objectForKey: @"_name"];
      NSDate * date = [install objectForKey: @"install_date"];
      NSString * version = [install objectForKey: @"install_version"];
      NSString * source = [install objectForKey: @"package_source"];
      
      if([source isEqualToString: @"package_source_other"])
        if([then compare: date] == NSOrderedAscending)
          {
          if(printCount == 0)
            [self.result appendAttributedString: [self buildTitle]];
    
          NSString * installDate =
            [Utilities installDateAsString: date];

          [self.model startElement: @"package"];
          
          [self.model addElement: @"name" value: name];
          [self.model addElement: @"version" value: version];
          [self.model addElement: @"installdate" day: date];
          
          [self.model endElement: @"package"];
          
          [self.result
            appendString:
              [NSString
                stringWithFormat:
                  NSLocalizedString(@"    %@: %@ (%@)\n", NULL),
                  name,
                  version,
                  installDate]];
            
          ++printCount;
          }
      }
      
    if(printCount > 0)
      {
      [self.result appendString: @"\n"];
      
      [self.result
        appendString: NSLocalizedString(@"installsincomplete", NULL)];
      }
      
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
