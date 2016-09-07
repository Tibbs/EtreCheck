/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "LaunchAgentsCollector.h"
#import "Utilities.h"
#import "SubProcess.h"

@implementation LaunchAgentsCollector

// Constructor.
- (id) init
  {
  self = [super initWithName: @"launchagents"];
  
  if(self)
    {
    return self;
    }
    
  return nil;
  }

// Collect 3rd party launch agents.
- (void) collect
  {
  [self updateStatus: NSLocalizedString(@"Checking launch agents", NULL)];

  // Make sure the base class is setup.
  [super collect];
  
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
    
  dispatch_semaphore_signal(self.complete);
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
