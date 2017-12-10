/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014-2017. All rights reserved.
 **********************************************************************/

#import "StartupItemsCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"
#import "NSArray+Etresoft.h"
#import "NSString+Etresoft.h"
#import "NSDictionary+Etresoft.h"
#import "SubProcess.h"
#import "Model.h"
#import "XMLBuilder.h"
#import "LocalizedString.h"
#import "EtreCheckConstants.h"
#import "OSVersion.h"

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
  
    if([NSArray isValid: plist])
      {
      NSDictionary * results = [plist objectAtIndex: 0];
      
      if([NSDictionary isValid: results])
        {
        NSArray * items = [results objectForKey: @"_items"];
        
        if([NSArray isValid: items])
          {
          if(self.simulating && ([items count] == 0))
            items = 
              [NSArray arrayWithObject: 
                [NSDictionary 
                  dictionaryWithObjectsAndKeys:
                    @"Simulated startup item", 
                    @"_name", 
                    @"/Library/StartupItems/SimItem", 
                    @"spstartupitem_location", 
                    @"1.0", 
                    @"CFBundleShortVersionString",
                    nil]];
          
          if(items.count > 0)
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
      }
    }
    
  [subProcess release];
  }

// Print Mach init files.
- (void) printMachInitFiles
  {
  // Deprecated in 10.3, still in use by Apple in 10.6.
  if([[OSVersion shared] major] == kSnowLeopard)
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
    NSString * cleanPath = [self cleanPath: file];
    
    [self.xml startElement: @"startupitem"];
    
    [self.xml addElement: @"name" value: [cleanPath lastPathComponent]];
    [self.xml addElement: @"path" value: cleanPath];
    [self.xml addElement: @"type" value: @"machinit"];
    
    [self.result
      appendString: [NSString stringWithFormat: @"    %@\n", cleanPath]
      attributes:
        @{
          NSForegroundColorAttributeName : [[Utilities shared] red],
        }];
        
    [self.xml endElement: @"startupitem"];
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
  if(![NSDictionary isValid: item])
    return;
    
  NSString * name = [item objectForKey: @"_name"];
  
  if(![NSString isValid: name])
    return;
    
  NSString * path = [item objectForKey: @"spstartupitem_location"];

  if(![NSString isValid: path])
    return;
    
  NSString * version = @"";
  
  for(NSString * infoPList in startupBundles)
    if([NSString isValid: infoPList])
      if([infoPList hasPrefix: path])
        {
        NSString * appVersion =
          [item objectForKey: @"CFBundleShortVersionString"];

        int age = 0;
        
        NSString * OSVersion = [self getOSVersion: item age: & age];
          
        if([NSString isValid: appVersion] || [NSString isValid: OSVersion])
          {
          NSMutableString * compositeVersion = [NSMutableString string];
          
          if([NSString isValid: appVersion])
            [compositeVersion appendString: appVersion];
          
          if([NSString isValid: OSVersion] > 0)
            [compositeVersion appendFormat: @" - %@", OSVersion];

          version = compositeVersion;
          }
        }
    
  NSString * cleanPath = [self cleanPath: path];

  [self.xml startElement: @"startupitem"];
  
  [self.xml addElement: @"name" value: name];
  [self.xml addElement: @"path" value: cleanPath];
  [self.xml addElement: @"type" value: @"startupitem"];
  [self.xml addElement: @"version" value: version];
  
  [self.xml endElement: @"startupitem"];
  
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
