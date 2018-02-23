/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014-2017. All rights reserved.
 **********************************************************************/

#import "ApplicationsCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"
#import "Model.h"
#import "NSArray+Etresoft.h"
#import "NSDictionary+Etresoft.h"
#import "NSString+Etresoft.h"
#import "NSSet+Etresoft.h"
#import "SubProcess.h"
#import "LocalizedString.h"
#import "XMLBuilder.h"

// Collect installed applications.
@implementation ApplicationsCollector

// Constructor.
- (id) init
  {
  self = [super initWithName: @"applications"];
  
  if(self != nil)
    {
    }
    
  return self;
  }

// Perform the collection.
- (void) performCollect
  {
  [self.result appendAttributedString: [self buildTitle]];
  
  // Get the applications.
  NSDictionary * applications = [self collectApplications];
  
  // Save the applications.
  [self.model setApplications: applications];
  
  for(NSString * name in applications)
    {
    NSDictionary * application = [applications objectForKey: name];
    
    [self.xml startElement: @"application"];
    
    NSNumber * has64BitIntelCode = 
      [application objectForKey: @"has64BitIntelCode"];
    
    NSDate * lastModified = [application objectForKey: @"lastModified"];
    NSString * source = [application objectForKey: @"obtained_from"];
    NSString * path = [application objectForKey: @"path"];
    NSString * version = [application objectForKey: @"version"];
      
    if(!has64BitIntelCode.boolValue)
      [self.model.apps addObject: path];

    [self.xml addElement: @"name" value: name];
    [self.xml addElement: @"path" value: path];
    [self.xml addElement: @"path_safe" value: [Utilities cleanPath: path]];
    [self.xml addElement: @"version" value: version];
    [self.xml addElement: @"lastmodified" date: lastModified];
    [self.xml addElement: @"source" value: source];
    
    [self.xml 
      addElement: @"has64bit" boolValue: has64BitIntelCode.boolValue];
    
    [self.xml endElement: @"application"];
    }
  }

// Collect applications.
- (NSDictionary *) collectApplications
  {
  NSMutableDictionary * appDetails = [NSMutableDictionary new];
  
  NSString * key = @"SPApplicationsDataType";
  
  NSArray * args =
    @[
      @"-xml",
      key
    ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  [subProcess loadDebugOutput: [self.model debugInputPath: key]];
  [subProcess saveDebugOutput: [self.model debugOutputPath: key]];
  
  if([subProcess execute: @"/usr/sbin/system_profiler" arguments: args])
    {
    NSArray * plist =
      [NSArray readPropertyListData: subProcess.standardOutput];
  
    if([NSArray isValid: plist])
      {
      NSDictionary * results = [plist objectAtIndex: 0];
      
      if([NSDictionary isValid: results])
        {
        NSArray * applications = [results objectForKey: @"_items"];
          
        if([NSArray isValid: applications])
          for(NSDictionary * application in applications)
            {
            NSString * name = [application objectForKey: @"_name"];
            
            if(![NSString isValid: name])
              name = ECLocalizedString(@"[Unknown]");

            NSDictionary * details =
              [self collectApplicationDetails: application];
            
            if([NSDictionary isValid: details])
              [appDetails setObject: details forKey: name];
            }
        }
      }
    }
    
  [subProcess release];
    
  return [appDetails autorelease];
  }

// Collect details about a single application.
- (NSDictionary *) collectApplicationDetails: (NSDictionary *) application
  {
  if(![NSDictionary isValid: application])
    return nil;
    
  NSString * path = [application objectForKey: @"path"];
  
  if(![NSString isValid: path])
    path = ECLocalizedString(@"[Unknown]");
    
  // TODO: Grep executable for SMLoginItemSetEnabled
  // Perform /System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister -dump
  // and look for
  // 	flags:         apple-internal  has-display-name  ui-element  has-entitlements  
  // 	flags:         apple-internal  has-display-name  bg-only  launch-disabled  incomplete  requires-iphone-simulator  
  // See Antidote as example.
  NSString * versionPlist =
    [path stringByAppendingPathComponent: @"Contents/Info.plist"];

  NSDictionary * plist = [NSDictionary readPropertyList: versionPlist];

  NSMutableDictionary * info =
    [NSMutableDictionary dictionaryWithDictionary: application];
  
  if([NSDictionary isValid: plist])
    [info addEntriesFromDictionary: plist];
  
  return info;
  }

@end
