/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014-2017. All rights reserved.
 **********************************************************************/

#import "LaunchAgentsCollector.h"
#import "Utilities.h"
#import "SubProcess.h"

@implementation LaunchAgentsCollector

// Constructor.
- (id) init
  {
  self = [super initWithName: @"launchagents"];
  
  if(self != nil)
    {
    }
    
  return self;
  }

// Collect 3rd party launch agents.
- (void) performCollect
  {
  // Make sure the base class is setup.
  [super performCollect];
  
  NSArray * args =
    @[
      @"/Library/LaunchAgents",
      @"-type", @"f",
      @"-or",
      @"-type", @"l"
    ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  if([subProcess execute: @"/usr/bin/find" arguments: args])
    {
    NSArray * files = [Utilities formatLines: subProcess.standardOutput];
    
    NSArray * plists = [self collectPropertyListFiles: files];
    
    [self printPropertyLists: plists];
    }
    
  [subProcess release];
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
