/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014-2017. All rights reserved.
 **********************************************************************/

#import "SystemLaunchDaemonsCollector.h"

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
  
  [self printFilesInDirectory: @"/System/Library/LaunchDaemons/"];
  }
  
@end

