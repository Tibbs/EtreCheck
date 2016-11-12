/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "UserITunesPlugInsCollector.h"

// Collect user iTunes plug-ins.
@implementation UserITunesPlugInsCollector

// Constructor.
- (id) init
  {
  self = [super initWithName: @"useritunesplugins"];
  
  if(self)
    {
    return self;
    }
    
  return nil;
  }

// Perform the collection.
- (void) performCollection
  {
  [self
    updateStatus:
      NSLocalizedString(@"Checking user iTunes plug-ins", NULL)];

  [self
    parseUserPlugins: NSLocalizedString(@"User iTunes Plug-ins:", NULL)
    path:  @"/Library/iTunes/iTunes Plug-ins"];
  }

@end
