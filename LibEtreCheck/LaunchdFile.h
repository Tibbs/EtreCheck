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
  
  // Loaded tasks.
  NSMutableArray * myLoadedTasks;
  
  // The executable's signature.
  NSString * mySignature;
  
  // The plist CRC.
  NSString * myPlistCRC;
  
  // The executable CRC.
  NSString * myExecutableCRC;
  
  // The safety scrore.
  int mySafetyScore;
  
  // Adware.
  BOOL myAdware;
  
  // I will need a unique, XML-safe identifier for each launchd file.
  NSString * myIdentifier;
  }

// The config script contents.
@property (readonly, nullable) NSDictionary * plist;

// Is the config script valid?
@property (readonly) BOOL configScriptValid;

// The launchd context. (apple, system, user)
@property (readonly, nullable) NSString * context;

// Loaded tasks.
@property (readonly, nonnull) NSMutableArray * loadedTasks;

// The executable's signature.
@property (retain, nullable) NSString * signature;

// The plist CRC.
@property (retain, nullable) NSString * plistCRC;

// The executable CRC.
@property (retain, nullable) NSString * executableCRC;

// Is the file loaded?
@property (readonly) BOOL loaded;

// The safety scrore.
@property (assign) int safetyScore;

// Adware.
@property (assign) BOOL adware;

// I will need a unique, XML-safe identifier for each launchd file.
@property (retain, nonnull) NSString * identifier;

// Constructor with path.
- (nullable instancetype) initWithPath: (nonnull NSString *) path;

// Load a launchd task.
- (void) load;

// Unload a launchd task.
- (void) unload;

// Requery the file.
- (void) requery;

@end
