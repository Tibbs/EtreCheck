/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "InternetPlugInsCollector.h"

// Collect internet plug-ins.
@implementation InternetPlugInsCollector

// Constructor.
- (id) init
  {
  self = [super initWithName: @"internetplugins"];
  
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
    updateStatus: NSLocalizedString(@"Checking internet plug-ins", NULL)];

  [self parsePlugins: @"/Library/Internet Plug-Ins"];
  }

@end
