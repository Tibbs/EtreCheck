/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

// A wrapper around all things launchd.
@interface Launchd : NSObject
  {
  // Launchd files keyed by config file path. 
  // Values are task objects since they are guaranteed to be unique.
  NSMutableDictionary * myFilesByPath;
  
  // Launchd files keyed by label. 
  // Values are NSMutableArrays since they might not be unique.
  NSMutableDictionary * myFilesByLabel;

  // Set of launchd files with missing executables.
  NSMutableSet * myOrphanFiles;
  
  // Files identified as adware.
  NSMutableSet * myAdwareFiles;
  
  // Files lacking a signature.
  NSMutableSet * myUnsignedFiles;
  
  // Set of loaded launchd tasks.
  NSMutableSet * myEphemeralTasks;
  
  // Only load once.
  BOOL myLoaded;
  
  // Apple launchd file.
  NSMutableDictionary * myAppleFiles;
  
  // Launchd files indexed by identifier.
  NSMutableDictionary * myLaunchdFileLookup;
  }
  
// Launchd files keyed by config file path. 
// Values are task objects since they are guaranteed to be unique.
@property (readonly, nonnull) NSMutableDictionary * filesByPath;

// Launchd files keyed by label. 
// Values are NSMutableArrays since they might not be unique.
@property (readonly, nonnull) NSMutableDictionary * filesByLabel;

// Set of launchd files with missing executables.
@property (readonly, nonnull) NSMutableSet * orphanFiles;

// Set of launchd files identified as adware.
@property (readonly, nonnull) NSMutableSet * adwareFiles;

// Files lacking a signature.
@property (readonly, nonnull) NSMutableSet * unsignedFiles;

// Set of loaded launchd tasks.
@property (readonly, nonnull) NSMutableSet * ephemeralTasks;

// Only load once.
@property (readonly) BOOL loaded;

// Apple launchd file.
@property (readonly, nonnull) NSMutableDictionary * appleFiles;

// Launchd files indexed by identifier.
@property (readonly, nonnull) NSMutableDictionary * launchdFileLookup;

// Load all entries.
- (void) load;

@end
