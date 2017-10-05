/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

// A wrapper around all things launchd.
@interface Launchd : NSObject
  {
  // Launchd tasks. Tasks are not unique by either label or path.
  NSMutableArray * myTasks;
  }
  
// Return the singeton.
+ (nonnull Launchd *) shared;

// Launchd tasks. Tasks are not unique by either label or path.
@property (readonly, nonnull) NSMutableArray * tasks;

// Load all entries.
- (void) load;

@end
