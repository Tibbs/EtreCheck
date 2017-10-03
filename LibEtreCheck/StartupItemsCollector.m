/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014-2017. All rights reserved.
 **********************************************************************/

#import "StartupItemsCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"
#import "NSArray+Etresoft.h"
#import "NSDictionary+Etresoft.h"
#import "SubProcess.h"
#import "Model.h"
#import "XMLBuilder.h"
#import "LocalizedString.h"
#import "EtreCheckConstants.h"

// Collect old startup items.
@implementation StartupItemsCollector

// Constructor.
- (id) init
  {
  self = [super initWithName: @"startupitems"];
  
  if(self != nil)
    {
    }
    
  return self;
  }

// Perform the collection.
- (void) performCollect
  {
  // Get startup item bundles on disk.
  startupBundles = [self getStartupItemBundles];
  
  [self printStartupItems];
  [self printMachInitFiles];
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
        
      if(self.simulating && ([items count] == 0))
        items = 
          [NSArray arrayWithObject: 
            [NSDictionary 
              dictionaryWithObjectsAndKeys:
                @"Simulated startup item", @"_name", 
                @"/Library/StartupItems/SimItem", @"spstartupitem_location", 
                @"1.0", @"CFBundleShortVersionString",
                nil]];
      
      if([items count])
        {
        if(!startupItemsFound)
          {
          [self.result appendAttributedString: [self buildTitle]];
          startupItemsFound = YES;
          }
          
        for(NSDictionary * item in items)
          [self printStartupItem: item];
          
        [self.result
          appendString: ECLocalizedString(@"startupitemsdeprecated")
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
  
  if(self.simulating && ([machInitFiles count] == 0))
    machInitFiles = [NSArray arrayWithObject: @"/Library/SimMacInit"];

  if([machInitFiles count] == 0)
    return;
    
  if(!startupItemsFound)
    {
    [self.result appendAttributedString: [self buildTitle]];
    startupItemsFound = YES;
    }

  for(NSString * file in machInitFiles)
    {
    NSString * cleanPath = [Utilities cleanPath: file];
    
    [self.model startElement: @"startupitem"];
    
    [self.model addElement: @"name" value: [cleanPath lastPathComponent]];
    [self.model addElement: @"path" value: cleanPath];
    [self.model addElement: @"type" value: @"machinit"];
    
    [self.result
      appendString: [NSString stringWithFormat: @"    %@\n", cleanPath]
      attributes:
        @{
          NSForegroundColorAttributeName : [[Utilities shared] red],
        }];
        
    [self.model endElement: @"startupitem"];
    }
    
  [self.result
    appendString: ECLocalizedString(@"machinitdeprecated")
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
  
  if(self.simulating)
    [bundles 
      setObject: 
        [NSDictionary 
          dictionaryWithObjectsAndKeys:
            @"Simulated startup item", @"_name", 
            @"/Library/StartupItems/SimItem", @"spstartupitem_location", 
            @"1.0", @"CFBundleShortVersionString",
            nil] 
      forKey: @"/Library/StartupItems/SimItem"];
    
  return bundles;
  }

// Print a startup item.
- (void) printStartupItem: (NSDictionary *) item
  {
  NSString * name = [item objectForKey: @"_name"];
  NSString * path = [item objectForKey: @"spstartupitem_location"];

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
        
        if([appVersion length] > 0)
          [compositeVersion appendString: appVersion];
        
        if([OSVersion length] > 0)
          [compositeVersion appendFormat: @" - %@", OSVersion];

        version = compositeVersion;
        }
      }
    
  NSString * cleanPath = [Utilities cleanPath: path];

  [self.model startElement: @"startupitem"];
  
  [self.model addElement: @"name" value: name];
  [self.model addElement: @"path" value: cleanPath];
  [self.model addElement: @"type" value: @"startupitem"];
  [self.model addElement: @"version" value: version];
  
  [self.model endElement: @"startupitem"];
  
  [self.result
    appendString:
      [NSString
        stringWithFormat:
          ECLocalizedString(@"    %@: %@ Path: %@\n"),
          name, 
          [version length] > 0
            ? [NSString stringWithFormat: @"(%@)", version]
            : @"", 
          cleanPath]
    attributes:
      @{
        NSForegroundColorAttributeName : [[Utilities shared] red],
      }];
  }

@end
