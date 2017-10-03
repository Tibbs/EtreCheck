/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "Launchd.h"
#import "SubProcess.h"
#import "EtreCheckConstants.h"

@implementation Launchd

// Return the singeton.
+ (nonnull Launchd *) shared
  {
  static Launchd * launchd = nil;
  
  static dispatch_once_t onceToken;
  
  dispatch_once(
    & onceToken,
    ^{
      launchd = [Launchd new];
    });
    
  return launchd;
  }

// Constructor.
- (instancetype) init
  {
  self = [super init];
  
  if(self != nil)
    {
    }
    
  return self;
  }
  
@end
