/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014-2017. All rights reserved.
 **********************************************************************/

#import "ITunesPlugInsCollector.h"

// Collect iTunes plug-ins.
@implementation ITunesPlugInsCollector

// Constructor.
- (id) init
  {
  self = [super initWithName: @"itunesplugins"];
  
  if(self != nil)
    {
    }
    
  return self;
  }

// Perform the collection.
- (void) performCollect
  {
  [self parsePlugins: @"/Library/iTunes/iTunes Plug-ins"];
  }

@end
