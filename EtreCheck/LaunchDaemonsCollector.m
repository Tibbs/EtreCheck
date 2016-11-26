/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "LaunchDaemonsCollector.h"
#import "Utilities.h"
#import "SubProcess.h"
#import "XMLBuilder.h"

@implementation LaunchDaemonsCollector

// Constructor.
- (id) init
  {
  self = [super initWithName: @"launchdaemons"];
  
  if(self)
    {
    return self;
    }
    
  return nil;
  }

// Collect 3rd party launch daemons.
- (void) performCollection
  {
  [self updateStatus: NSLocalizedString(@"Checking launch daemons", NULL)];

  // Make sure the base class is setup.
  [super performCollection];
  
  NSArray * args =
    @[
      @"/Library/LaunchDaemons",
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
    
    [self.XML addAttribute: @"domain" value: @"system"];
    [self.XML addAttribute: @"type" value: @"daemon"];

    [self printPropertyLists: plists];
    
    [self.XML endElement: @"tasks"];
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
