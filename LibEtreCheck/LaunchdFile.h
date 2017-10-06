/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "LaunchdTask.h"

// EtreCheck's context, where a file lives.
#define kLaunchdAppleContext @"apple"
#define kLaunchdSystemContext @"system"
#define kLaunchdUserContext @"user"
#define kLaunchdUnknownContext @"unknown"

// A wrapper around a launchd config file.
@interface LaunchdFile : LaunchdTask
  {
  // The config script contents.
  NSDictionary * myPlist;
  
  // Is the config script valid?
  BOOL myConfigScriptValid;
  
  // The launchd context. (apple, system, user)
  NSString * myContext;
  }

// The config script contents.
@property (readonly, nullable) NSDictionary * plist;

// Is the config script valid?
@property (readonly) BOOL configScriptValid;

// The launchd context. (apple, system, user)
@property (readonly, nullable) NSString * context;

// Loaded tasks.
@property (readonly, nonnull) NSMutableArray * loadedTasks;

// Constructor with path.
- (nullable instancetype) initWithPath: (nonnull NSString *) path;

// Load a launchd task.
- (void) load;

// Unload a launchd task.
- (void) unload;

@end
