/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014-2017. All rights reserved.
 **********************************************************************/

#import "UserInternetPlugInsCollector.h"
#import "LocalizedString.h"

// Collect user internet plug-ins.
@implementation UserInternetPlugInsCollector

// Constructor.
- (id) init
  {
  self = [super initWithName: @"userinternetplugins"];
  
  if(self != nil)
    {
    }
    
  return self;
  }

// Perform the collection.
- (void) performCollect
  {
  [self
    parseUserPlugins: ECLocalizedString(@"User Internet Plug-ins:")
    path: @"Library/Internet Plug-Ins"];
  }

@end
