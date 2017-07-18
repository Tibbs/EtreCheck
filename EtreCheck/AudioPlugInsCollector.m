/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014-2017. All rights reserved.
 **********************************************************************/

#import "AudioPlugInsCollector.h"

// Collect audio plug-ins.
@implementation AudioPlugInsCollector

// Constructor.
- (id) init
  {
  self = [super initWithName: @"audioplugins"];
  
  if(self != nil)
    {
    }
    
  return self;
  }

// Perform the collection.
- (void) performCollect
  {
  [self parsePlugins: @"/Library/Audio/Plug-ins"];
  }

@end
