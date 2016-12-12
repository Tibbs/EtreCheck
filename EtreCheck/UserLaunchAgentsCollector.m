/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "UserLaunchAgentsCollector.h"
#import "Utilities.h"
#import "SubProcess.h"
#import "XMLBuilder.h"

@implementation UserLaunchAgentsCollector

// Constructor.
- (id) init
  {
  self = [super initWithName: @"userlaunchagents"];
  
  if(self)
    {
    return self;
    }
    
  return nil;
  }

// Collect user launch agents.
- (void) performCollection
  {
  // TODO: Sandbox does this work or not?
  [self
    updateStatus: NSLocalizedString(@"Checking user launch agents", NULL)];

  // Make sure the base class is setup.
  [super performCollection];
  
  NSString * launchAgentsDir =
    [NSHomeDirectory()
      stringByAppendingPathComponent: @"Library/LaunchAgents"];

  if([[NSFileManager defaultManager] fileExistsAtPath: launchAgentsDir])
    {
    NSArray * args =
      @[
        launchAgentsDir,
        @"-type", @"f",
        @"-or",
        @"-type", @"l"
      ];
    
    SubProcess * subProcess = [[SubProcess alloc] init];
    
    if([subProcess execute: @"/usr/bin/find" arguments: args])
      {
      NSArray * files = [Utilities formatLines: subProcess.standardOutput];
    
      NSArray * plists = [self collectPropertyListFiles: files];
    
      [self.XML startElement: @"tasks"];
      
      [self.XML addAttribute: @"domain" value: @"user"];
      [self.XML addAttribute: @"type" value: @"agent"];
      
      [self printPropertyLists: plists];
    
      [self.XML endElement: @"tasks"];
      }
      
    [subProcess release];
    }
  }

// Should I hide Apple tasks?
- (bool) hideAppleTasks
  {
  return NO;
  }

// Since I am printing all Apple items, no need for counts.
- (bool) formatAppleCounts: (NSMutableAttributedString *) output
  {
  return NO;
  }

@end
