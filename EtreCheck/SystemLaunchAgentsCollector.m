/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "SystemLaunchAgentsCollector.h"
#import "Utilities.h"
#import "SubProcess.h"

@implementation SystemLaunchAgentsCollector

// Constructor.
- (id) init
  {
  self = [super initWithName: @"systemlaunchagents"];
  
  if(self)
    {
    return self;
    }
    
  return nil;
  }

// Collect system launch agents.
- (void) collect
  {
  [self
    updateStatus:
      NSLocalizedString(@"Checking system launch agents", NULL)];
 
  // Make sure the base class is setup.
  [super collect];
  
  NSArray * args =
    @[
      @"/System/Library/LaunchAgents",
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
  
@end
