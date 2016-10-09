/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "SystemLaunchDaemonsCollector.h"
#import "Utilities.h"
#import "SubProcess.h"
#import "XMLBuilder.h"
#import "Model.h"

@implementation SystemLaunchDaemonsCollector

// Constructor.
- (id) init
  {
  self = [super initWithName: @"systemlaunchdaemons"];
  
  if(self)
    {
    return self;
    }
    
  return nil;
  }

// Collect system launch daemons.
- (void) performCollection
  {
  [self
    updateStatus:
      NSLocalizedString(@"Checking system launch daemons", NULL)];

  // Make sure the base class is setup.
  [super performCollection];
  
  NSArray * args =
    @[
      @"/System/Library/LaunchDaemons",
      @"-type", @"f",
      @"-or",
      @"-type", @"l"
    ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  if([subProcess execute: @"/usr/bin/find" arguments: args])
    {
    NSArray * files = [Utilities formatLines: subProcess.standardOutput];
    
    NSArray * plists = [self collectPropertyListFiles: files];
    
    [self.XML startElement: kLaunchdTasks];
    
    [self.XML addAttribute: kLaunchdDomain value: @"apple"];
    [self.XML addAttribute: kLaunchdType value: @"daemon"];

    [self printPropertyLists: plists];
    
    [self.XML endElement: kLaunchdTasks];
    }
    
  [subProcess release];
    
  dispatch_semaphore_signal(self.complete);
  }
  
@end

