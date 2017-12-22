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
  
  // Organize the applications by their parent directories.
  NSDictionary * parents = [self collectParentDirectories: applications];
  
  // Print all applications and their parent directories.
  [self printApplicationDirectories: parents];
  
  [self.result appendCR];
  [self.result
    deleteCharactersInRange: NSMakeRange(0, [self.result length])];
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

// Collect the parent directory of each application and return a dictionary
// where the keys are the parent directories and the value is an array
// of contained applications.
- (NSDictionary *) collectParentDirectories: (NSDictionary *) applications
  {
  NSMutableDictionary * parents = [NSMutableDictionary dictionary];
    
  for(NSString * name in applications)
    {
    NSDictionary * application = [applications objectForKey: name];
    
    if([NSDictionary isValid: application])
      {
      // Make sure to redact any user names in the path.
      NSString * path = [application objectForKey: @"path"];
      
      if([NSString isValid: path])
        path = [self cleanPath: path];

      NSString * parent = [path stringByDeletingLastPathComponent];
    
      NSMutableSet * siblings = [parents objectForKey: parent];
      
      if(siblings)
        [siblings addObject: application];
      else
        [parents
          setObject: [NSMutableSet setWithObject: application]
          forKey: parent];
      }
    }

  return parents;
  }

// Print application directories.
- (void) printApplicationDirectories: (NSDictionary *) parents
  {
  if(![NSDictionary isValid: parents])
    return;
    
  // Sort the parents.
  NSArray * sortedParents =
    [[parents allKeys] sortedArrayUsingSelector: @selector(compare:)];
  
  // Print each parent and its children.
  for(NSString * parent in sortedParents)
    {
    int count = 0;
    
    // Sort the applications and print each.
    NSSet * applications = [parents objectForKey: parent];
    
    if([NSSet isValid: applications])
      {
      NSSortDescriptor * descriptor =
        [[NSSortDescriptor alloc] initWithKey: @"_name" ascending: YES];
        
      NSArray * sortedApplications =
        [applications sortedArrayUsingDescriptors: @[descriptor]];
        
      [descriptor release];
      
      for(NSDictionary * application in sortedApplications)
        {
        NSAttributedString * output = 
          [self applicationDetails: application];
        
        if(output != nil)
          {
          if(!count)
            // Make sure the parent path is clean and print it.
            [self.result
              appendString:
                [NSString
                  stringWithFormat: @"    %@\n", [self cleanPath: parent]]];

          ++count;
          
          [self.result appendAttributedString: output];
          }
        }
      }
    }
  }

// Return details about an application.
- (NSAttributedString *) applicationDetails: (NSDictionary *) application
  {
  NSMutableAttributedString * output =
    [[NSMutableAttributedString alloc] init];
    
  [output autorelease];
  
  if(![NSDictionary isValid: application])
    return output;
    
  NSString * name = [application objectForKey: @"_name"];

  if(![NSString isValid: name])
    return output;
    
  NSAttributedString * supportLink =
    [[[NSAttributedString alloc] initWithString: @""] autorelease];

  NSString * bundleID = [application objectForKey: @"CFBundleIdentifier"];

  if([NSString isValid: bundleID])
    {
    NSString * obtained_from = [application objectForKey: @"obtained_from"];
    
    if([NSString isValid: obtained_from])
      if([obtained_from isEqualToString: @"apple"])
        return nil;
      
    if([bundleID hasPrefix: @"com.apple."])
      return nil;

    supportLink = [self getSupportURL: name bundleID: bundleID];
    }
   
  [output
    appendString:
      [NSString
        stringWithFormat:
          @"        %@%@", name, [self formatVersionString: application]]];
    
  [output appendAttributedString: supportLink];
  [output appendString: @" "];
  
  NSAttributedString * detailsLink = [self.model getDetailsURLFor: name];
  
  if(detailsLink != nil)
    {
    [output appendString: @" "];
    [output appendAttributedString: detailsLink];
    [output appendString: @"\n"];
    }
    
  return output;
  }

// Build a version string.
- (NSString *) formatVersionString: (NSDictionary *) application
  {
  int age = 0;
  
  NSString * OSVersion = [self getOSVersion: application age: & age];

  NSString * version = [application objectForKey: @"version"];

  if(!version && !OSVersion)
    return @"";
    
  if(!version)
    version = @"";

  if(!OSVersion)
    OSVersion = @"";
    
  return [NSString stringWithFormat: @": %@%@", version, OSVersion];
  }

@end
