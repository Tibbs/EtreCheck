/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014-2017. All rights reserved.
 **********************************************************************/

#import "UserLaunchAgentsCollector.h"
#import "Utilities.h"
#import "SubProcess.h"

@implementation UserLaunchAgentsCollector

// Constructor.
- (id) init
  {
  self = [super initWithName: @"userlaunchagents"];
  
  if(self != nil)
    {
    }
    
  return self;
  }

// Collect user launch agents.
- (void) performCollect
  {
  // Make sure the base class is setup.
  [super performCollect];
  
  NSString * launchAgentsDir =
    [NSHomeDirectory()
      stringByAppendingPathComponent: @"Library/LaunchAgents"];

  [self 
    printFilesInDirectory: 
      [launchAgentsDir stringByAbbreviatingWithTildeInPath]];
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
