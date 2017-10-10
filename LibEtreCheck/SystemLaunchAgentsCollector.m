/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014-2017. All rights reserved.
 **********************************************************************/

#import "SystemLaunchAgentsCollector.h"
#import "Launchd.h"

@implementation SystemLaunchAgentsCollector

// Constructor.
- (id) init
  {
  self = [super initWithName: @"systemlaunchagents"];
  
  if(self != nil)
    {
    }
    
  return self;
  }

// Collect system launch agents.
- (void) performCollect
  {
  // Make sure the base class is setup.
  [super performCollect];
  
  [self printFilesInDirectory: @"/System/Library/LaunchAgents/"];
  }
  
@end
