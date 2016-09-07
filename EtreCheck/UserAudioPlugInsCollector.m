/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "UserAudioPlugInsCollector.h"

// Collect user audio plug-ins.
@implementation UserAudioPlugInsCollector

// Constructor.
- (id) init
  {
  self = [super initWithName: @"useraudioplugins"];
  
  if(self)
    {
    return self;
    }
    
  return nil;
  }

// Perform the collection.
- (void) collect
  {
  [self
    updateStatus: NSLocalizedString(@"Checking user audio plug-ins", NULL)];

  [self
    parseUserPlugins: NSLocalizedString(@"User Audio Plug-ins:", NULL)
    path: @"/Library/Audio/Plug-ins"];
    
  dispatch_semaphore_signal(self.complete);
  }

@end
