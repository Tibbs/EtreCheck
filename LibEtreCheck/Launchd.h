/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

// A wrapper around all things launchd.
@interface Launchd : NSObject
  {
  // Launchd tasks keyed by config file path. 
  // Values are task objects since they are guaranteed to be unique.
  NSMutableDictionary * myTasksByPath;
  
  // Launchd tasks keyed by label. 
  // Values are NSMutableArrays since they might not be unique.
  NSMutableDictionary * myTasksByLabel;

  // Array of loaded launchd tasks.
  NSMutableArray * myEphemeralTasks;
  
  // Only load once.
  BOOL myLoaded;
  }
  
// Return the singeton.
+ (nonnull Launchd *) shared;

// Launchd tasks keyed by config file path. 
// Values are task objects since they are guaranteed to be unique.
@property (readonly, nonnull) NSMutableDictionary * tasksByPath;

// Launchd tasks keyed by label. 
// Values are NSMutableArrays since they might not be unique.
@property (readonly, nonnull) NSMutableDictionary * tasksByLabel;

// Array of loaded launchd tasks.
@property (readonly, nonnull) NSMutableArray * ephemeralTasks;

// Only load once.
@property (readonly) BOOL loaded;

// Load all entries.
- (void) load;

@end
