/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014-2017. All rights reserved.
 **********************************************************************/

#import "InternetPlugInsCollector.h"

// Collect internet plug-ins.
@implementation InternetPlugInsCollector

// Constructor.
- (id) init
  {
  self = [super initWithName: @"internetplugins"];
  
  if(self != nil)
    {
    }
    
  return self;
  }

// Perform the collection.
- (void) performCollect
  {
  [self parsePlugins: @"/Library/Internet Plug-Ins"];
  }

@end
