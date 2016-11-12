/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "UserInternetPlugInsCollector.h"

// Collect user internet plug-ins.
@implementation UserInternetPlugInsCollector

// Constructor.
- (id) init
  {
  self = [super initWithName: @"userinternetplugins"];
  
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
      NSLocalizedString(@"Checking user internet plug-ins", NULL)];

  [self
    parseUserPlugins: NSLocalizedString(@"User Internet Plug-ins:", NULL)
    path: @"Library/Internet Plug-Ins"];
  }

@end
