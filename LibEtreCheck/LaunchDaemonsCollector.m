/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014-2017. All rights reserved.
 **********************************************************************/

#import "LaunchDaemonsCollector.h"
#import "Utilities.h"
#import "SubProcess.h"

@implementation LaunchDaemonsCollector

// Constructor.
- (id) init
  {
  self = [super initWithName: @"launchdaemons"];
  
  if(self != nil)
    {
    }
    
  return self;
  }

// Collect 3rd party launch daemons.
- (void) performCollect
  {
  // Make sure the base class is setup.
  [super performCollect];
  
  [self printFilesInDirectory: @"/Library/LaunchDaemons/"];
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
