/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "ApplicationsCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"
#import "Model.h"
#import "NSArray+Etresoft.h"
#import "NSDictionary+Etresoft.h"
#import "SubProcess.h"
#import "XMLBuilder.h"
#import "Model.h"

// Collect installed applications.
@implementation ApplicationsCollector

// Constructor.
- (id) init
  {
  self = [super initWithName: @"applications"];
  
  if(self)
    {
    genericApplication =
      [[NSWorkspace sharedWorkspace] iconForFileType: @".app"];

    return self;
    }
    
  return nil;
  }

// Perform the collection.
- (void) performCollection
  {
  [self updateStatus: NSLocalizedString(@"Checking applications", NULL)];

  [self.result appendAttributedString: [self buildTitle]];
  
  // Get the applications.
  NSDictionary * applications = [self collectApplications];
  
  // Save the applications.
  [[Model model] setApplications: applications];
  
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
            name = NSLocalizedString(@"[Unknown]", NULL);

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
    path = NSLocalizedString(@"[Unknown]", NULL);
    
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
      [Utilities cleanPath: [application objectForKey: @"path"]];

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
    [self.XML startElement: kApplicationDirectory];
    
    [self.XML addElement: kApplicationDirectoryPath value: parent];
    
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
      [self.XML startElement: kApplication];
      
      NSAttributedString * output = [self applicationDetails: application];
      
      if(output)
        {
        if(!count)
          // Make sure the parent path is clean and print it.
          [self.result
            appendString:
              [NSString
                stringWithFormat:
                  @"    %@\n", [Utilities cleanPath: parent]]];

        ++count;
        
        [self.result appendAttributedString: output];
        }
        
      [self.XML endElement: kApplication];
      }
      
    [self.XML endElement: kApplicationDirectory];
    }
  }

// Return details about an application.
- (NSAttributedString *) applicationDetails: (NSDictionary *) application
  {
  NSString * name = [application objectForKey: @"_name"];
  NSString * path = [application objectForKey: @"path"];

  NSAttributedString * supportLink =
    [[[NSAttributedString alloc] initWithString: @""] autorelease];

  NSString * bundleID = [application objectForKey: @"CFBundleIdentifier"];

  NSString * version = [application objectForKey: @"CFBundleShortVersionString"];
  NSString * build = [application objectForKey: @"CFBundleVersion"];

  NSDate * date = [Utilities modificationDate: path];
  
  [self.XML addElement: kApplicationName value: name];
  [self.XML
    addElement: kApplicationPath value: [Utilities cleanPath: path]];
  [self.XML addElement: kApplicationBundleID value: bundleID];
  [self.XML addElement: kApplicationVersion value: version];
  [self.XML addElement: kApplicationBuild value: build];
  [self.XML addElement: kApplicationDate date: date];
  
  if(bundleID)
    {
    NSString * obtained_from = [application objectForKey: @"obtained_from"];

    if([obtained_from length] > 0)
      [self.XML addElement: kApplicationSource value: obtained_from];
    
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
          NSLocalizedString(@"        %@%@", NULL),
          name, [self formatVersionString: application]]];
    
  [output appendAttributedString: supportLink];
  [output appendString: @" "];
  
  NSAttributedString * detailsLink = [[Model model] getDetailsURLFor: name];
  
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

@end
