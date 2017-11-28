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
    genericApplication =
      [[NSWorkspace sharedWorkspace] iconForFileType: @".app"];
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
  
  NSArray * args =
    @[
      @"-xml",
      @"SPApplicationsDataType"
    ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  if([subProcess execute: @"/usr/sbin/system_profiler" arguments: args])
    {
    NSArray * plist =
      [NSArray readPropertyListData: subProcess.standardOutput];
  
    if([plist count])
      {
      NSArray * applications =
        [[plist objectAtIndex: 0] objectForKey: @"_items"];
        
      if([applications count])
        for(NSDictionary * application in applications)
          {
          NSString * name = [application objectForKey: @"_name"];
          
          if(!name)
            name = ECLocalizedString(@"[Unknown]");

          NSDictionary * details =
            [self collectApplicationDetails: application];
          
          if(details)
            [appDetails setObject: details forKey: name];
          }
      }
    }
    
  [subProcess release];
    
  return [appDetails autorelease];
  }

// Collect details about a single application.
- (NSDictionary *) collectApplicationDetails: (NSDictionary *) application
  {
  NSString * path = [application objectForKey: @"path"];
  
  if(!path)
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
  
  NSString * iconName = [plist objectForKey: @"CFBundleIconFile"];
  
  if(iconName)
    {
    NSString * appResources =
      [path stringByAppendingPathComponent: @"Contents/Resources"];
    
    NSString * iconPath =
      [appResources stringByAppendingPathComponent: iconName];
      
    if(iconPath)
      if([[NSFileManager defaultManager] fileExistsAtPath: iconPath])
        [info setObject: iconPath forKey: @"iconPath"];
    }
    
  if(plist)
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
    
    // Make sure to redact any user names in the path.
    NSString * path =
      [self cleanPath: [application objectForKey: @"path"]];

    NSString * parent = [path stringByDeletingLastPathComponent];
  
    NSMutableSet * siblings = [parents objectForKey: parent];
    
    if(siblings)
      [siblings addObject: application];
    else
      [parents
        setObject: [NSMutableSet setWithObject: application]
        forKey: parent];
    }

  return parents;
  }

// Print application directories.
- (void) printApplicationDirectories: (NSDictionary *) parents
  {
  // Sort the parents.
  NSArray * sortedParents =
    [[parents allKeys] sortedArrayUsingSelector: @selector(compare:)];
  
  // Print each parent and its children.
  for(NSString * parent in sortedParents)
    {
    int count = 0;
    
    // Sort the applications and print each.
    NSSet * applications = [parents objectForKey: parent];
    
    NSSortDescriptor * descriptor =
      [[NSSortDescriptor alloc] initWithKey: @"_name" ascending: YES];
      
    NSArray * sortedApplications =
      [applications sortedArrayUsingDescriptors: @[descriptor]];
      
    [descriptor release];
    
    for(NSDictionary * application in sortedApplications)
      {
      NSAttributedString * output = [self applicationDetails: application];
      
      if(output)
        {
        if(!count)
          // Make sure the parent path is clean and print it.
          [self.result
            appendString:
              [NSString
                stringWithFormat:
                  @"    %@\n", [self cleanPath: parent]]];

        ++count;
        
        [self.result appendAttributedString: output];
        }
      }
    }
  }

// Return details about an application.
- (NSAttributedString *) applicationDetails: (NSDictionary *) application
  {
  NSString * name = [application objectForKey: @"_name"];

  NSAttributedString * supportLink =
    [[[NSAttributedString alloc] initWithString: @""] autorelease];

  NSString * bundleID = [application objectForKey: @"CFBundleIdentifier"];

  if(bundleID)
    {
    NSString * obtained_from = [application objectForKey: @"obtained_from"];
    
    if([obtained_from isEqualToString: @"apple"])
      return nil;
      
    if([bundleID hasPrefix: @"com.apple."])
      return nil;

    supportLink = [self getSupportURL: name bundleID: bundleID];
    }
   
  NSMutableAttributedString * output =
    [[NSMutableAttributedString alloc] init];
    
  [output
    appendString:
      [NSString
        stringWithFormat:
          @"        %@%@", name, [self formatVersionString: application]]];
    
  [output appendAttributedString: supportLink];
  [output appendString: @" "];
  
  NSAttributedString * detailsLink = [self.model getDetailsURLFor: name];
  
  if(detailsLink)
    {
    [output appendString: @" "];
    [output appendAttributedString: detailsLink];
    [output appendString: @"\n"];
    }
    
  return [output autorelease];
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

// Get the application icons.
- (NSArray *) applicationIcons
  {
  NSMutableArray * icons = [NSMutableArray array];
  
  NSDictionary * applications = [self.model applications];
  
  for(NSString * name in applications)
    {
    NSDictionary * application = [applications objectForKey: name];
    
    if(application != nil)
      {
      NSImage * icon = [self applicationIcon: application];
    
      if(icon != nil)
        [icons addObject: icon];
      }
    }  
    
  return icons;
  }

// Get an application icon.
- (NSImage *) applicationIcon: (NSDictionary *) application
  {
  NSString * iconPath = [application objectForKey: @"iconPath"];
  
  if(!iconPath)
    return nil;
    
  // Only report 3rd party applications.
  NSString * obtained_from = [application objectForKey: @"obtained_from"];
  
  if([obtained_from isEqualToString: @"apple"])
    return nil;
      
  return [[[NSImage alloc] initWithContentsOfFile: iconPath] autorelease];
  }

@end
