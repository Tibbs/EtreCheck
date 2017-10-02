/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014.-2017 All rights reserved.
 **********************************************************************/

#import "UserAudioPlugInsCollector.h"
#import "LocalizedString.h"

// Collect user audio plug-ins.
@implementation UserAudioPlugInsCollector

// Constructor.
- (id) init
  {
  self = [super initWithName: @"useraudioplugins"];
  
  if(self != nil)
    {
    }
    
  return self;
  }

// Perform the collection.
- (void) performCollect
  {
  [self
    parseUserPlugins: ECLocalizedString(@"User Audio Plug-ins:")
    path: @"/Library/Audio/Plug-ins"];
  }

@end
