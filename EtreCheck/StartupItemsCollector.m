/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "StartupItemsCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"
#import "NSArray+Etresoft.h"
#import "NSDictionary+Etresoft.h"
#import "SubProcess.h"
#import "XMLBuilder.h"
#import "Model.h"

// Collect old startup items.
@implementation StartupItemsCollector

// Constructor.
- (id) init
  {
  self = [super initWithName: @"startupitems"];
  
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
    updateStatus:
      NSLocalizedString(@"Checking obsolete startup items", NULL)];

  // Get startup item bundles on disk.
  startupBundles = [self getStartupItemBundles];
  
  [self printStartupItems];
  [self printMachInitFiles];
  
  dispatch_semaphore_signal(self.complete);
  }

// Print Startup Items.
- (void) printStartupItems
  {
  NSArray * args =
    @[
      @"-xml",
      @"SPStartupItemDataType"
    ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  if([subProcess execute: @"/usr/sbin/system_profiler" arguments: args])
    {
    NSArray * plist =
      [NSArray readPropertyListData: subProcess.standardOutput];
  
    if(plist && [plist count])
      {
      NSArray * items = [[plist objectAtIndex: 0] objectForKey: @"_items"];
        
      if([items count])
        {
        [self.result appendAttributedString: [self buildTitle]];
        
        if([items count] > 0)
          {
          [self.XML addAttribute: @"severity" value: @"serious"];
          [self.XML
            addAttribute: @"severity_explanation"
            value: @"Startup items deprecated"];
          }
          
        for(NSDictionary * item in items)
          [self printStartupItem: item];
          
        [self.result
          appendString: NSLocalizedString(@"startupitemsdeprecated", NULL)
          attributes:
            @{
              NSForegroundColorAttributeName : [[Utilities shared] red],
            }];

        [self.result appendCR];
        }
      }
    }
    
  [subProcess release];
  }

// Print Mach init files.
- (void) printMachInitFiles
  {
  // Deprecated in 10.3, still in use by Apple in 10.6.
  if([[Model model] majorOSVersion] == kSnowLeopard)
    return;

  NSArray * machInitFiles = [Utilities checkMachInit: @"/etc/mach_init.d"];
  
  if([machInitFiles count] == 0)
    return;
    
  if(!startupItemsFound)
    {
    [self.result appendAttributedString: [self buildTitle]];
    startupItemsFound = YES;
    }

  for(NSString * file in machInitFiles)
    [self.result
      appendString:
        [NSString
          stringWithFormat:
            NSLocalizedString(@"    %@\n", NULL),
            [Utilities cleanPath: file]]
      attributes:
        @{
          NSForegroundColorAttributeName : [[Utilities shared] red],
        }];
    
  [self.result
    appendString: NSLocalizedString(@"machinitdeprecated", NULL)
    attributes:
      @{
        NSForegroundColorAttributeName : [[Utilities shared] red],
      }];

  [self.result appendCR];
  }

// Get startup item bundles.
- (NSDictionary *) getStartupItemBundles
  {
  NSArray * args =
    @[
      @"/Library/StartupItems",
      @"-iname",
      @"Info.plist"];
  
  NSMutableDictionary * bundles = [NSMutableDictionary dictionary];

  SubProcess * subProcess = [[SubProcess alloc] init];
  
  if([subProcess execute: @"/usr/bin/find" arguments: args])
    {
    NSArray * files = [Utilities formatLines: subProcess.standardOutput];

    for(NSString * file in files)
      {
      NSDictionary * plist = [NSDictionary readPropertyList: file];

      if(plist)
        [bundles setObject: plist forKey: file];
      }
    }
    
  [subProcess release];
  
  return bundles;
  }

// Print a startup item.
- (void) printStartupItem: (NSDictionary *) item
  {
  [self.XML startElement: @"startupitem"];
  
  NSString * name = [item objectForKey: @"_name"];
  NSString * path = [item objectForKey: @"spstartupitem_location"];

  [self.XML addElement: @"name" value: name];
  [self.XML addElement: @"path" value: path];
  
  NSString * version = @"";
  
  for(NSString * infoPList in startupBundles)
    if([infoPList hasPrefix: path])
      {
      NSString * appVersion =
        [item objectForKey: @"CFBundleShortVersionString"];

      int age = 0;
      
      NSString * OSVersion = [self getOSVersion: item age: & age];
        
      if([appVersion length] || [OSVersion length])
        {
        NSMutableString * compositeVersion = [NSMutableString string];
        
        [compositeVersion
          appendFormat: @"(%@", [appVersion length] ? appVersion : @""];
        [compositeVersion
          appendFormat:
            @"%@%@)",
            ([appVersion length] && [OSVersion length])
              ? @" - "
              : @"",
            [OSVersion length] ? OSVersion : @""];
          
        version = compositeVersion;
        
        [self.XML addElement: @"version" value: version];
        }
      }
    
  [self.result
    appendString:
      [NSString
        stringWithFormat:
          NSLocalizedString(@"    %@: %@Path: %@\n", NULL),
          name, version, path]
    attributes:
      @{
        NSForegroundColorAttributeName : [[Utilities shared] red],
      }];
    
  [self.XML endElement: @"startupitem"];
  }

@end
