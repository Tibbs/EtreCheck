/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014-2017. All rights reserved.
 **********************************************************************/

#import "UserITunesPlugInsCollector.h"
#import "LocalizedString.h"

// Collect user iTunes plug-ins.
@implementation UserITunesPlugInsCollector

// Constructor.
- (id) init
  {
  self = [super initWithName: @"useritunesplugins"];
  
  if(self != nil)
    {
    }
    
  return self;
  }

// Perform the collection.
- (void) performCollect
  {
  [self
    parseUserPlugins: ECLocalizedString(@"User iTunes Plug-ins:")
    path:  @"/Library/iTunes/iTunes Plug-ins"];    
  }

@end
