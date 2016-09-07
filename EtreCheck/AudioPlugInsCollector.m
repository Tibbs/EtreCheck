/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "AudioPlugInsCollector.h"

// Collect audio plug-ins.
@implementation AudioPlugInsCollector

// Constructor.
- (id) init
  {
  self = [super initWithName: @"audioplugins"];
  
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
    updateStatus: NSLocalizedString(@"Checking audio plug-ins", NULL)];

  [self parsePlugins: @"/Library/Audio/Plug-ins"];
    
  dispatch_semaphore_signal(self.complete);
  }

@end
