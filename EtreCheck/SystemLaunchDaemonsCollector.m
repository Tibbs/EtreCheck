/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014-2017. All rights reserved.
 **********************************************************************/

#import "SystemLaunchDaemonsCollector.h"
#import "Utilities.h"
#import "SubProcess.h"

@implementation SystemLaunchDaemonsCollector

// Constructor.
- (id) init
  {
  self = [super initWithName: @"systemlaunchdaemons"];
  
  if(self != nil)
    {
    }
    
  return self;
  }

// Collect system launch daemons.
- (void) performCollect
  {
  // Make sure the base class is setup.
  [super performCollect];
  
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
    
    [self printPropertyLists: plists];
    }
    
  [subProcess release];    
  }
  
@end

