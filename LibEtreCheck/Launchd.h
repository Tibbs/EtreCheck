/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

// A wrapper around all things launchd.
@interface Launchd : NSObject
  
// Return the singeton.
+ (nonnull Launchd *) shared;

@end
