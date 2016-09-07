/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "ITunesPlugInsCollector.h"

// Collect iTunes plug-ins.
@implementation ITunesPlugInsCollector

// Constructor.
- (id) init
  {
  self = [super initWithName: @"itunesplugins"];
  
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
    updateStatus: NSLocalizedString(@"Checking iTunes plug-ins", NULL)];

  [self parsePlugins: @"/Library/iTunes/iTunes Plug-ins"];
    
  dispatch_semaphore_signal(self.complete);
  }

@end
