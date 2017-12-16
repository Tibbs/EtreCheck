/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "LaunchdTask.h"

@class Launchd;

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
  
  // Adware.
  NSString * myAdware;
  
  // I will need a unique, XML-safe identifier for each launchd file.
  NSString * myIdentifier;
  
  // Is this an Apple file?
  BOOL myApple;
  
  // Is this file using globbing?
  BOOL myGlobbing;
  
  // Working directory.
  NSString * myWorkingDirectory;
  }

// The config script contents.
@property (strong, nullable) NSDictionary * plist;

// Is the config script valid?
@property (readonly) BOOL configScriptValid;

// The launchd context. (apple, system, user)
@property (strong, nullable) NSString * context;

// Loaded tasks.
@property (strong, nullable) NSMutableArray * loadedTasks;

// The executable's signature.
@property (strong, nullable) NSString * signature;

// The plist CRC.
@property (strong, nullable) NSString * plistCRC;

// The executable CRC.
@property (strong, nullable) NSString * executableCRC;

// Is the file loaded?
@property (readonly) BOOL loaded;

// Adware type.
@property (strong, nullable) NSString * adware;

// I will need a unique, XML-safe identifier for each launchd file.
@property (strong, nullable) NSString * identifier;

// Is this an Apple file?
@property (assign) BOOL apple;

// Is this file using globbing?
@property (assign) BOOL globbing;

// Working directory.
@property (strong, nullable) NSString * workingDirectory;

// Constructor with path.
- (nullable instancetype) initWithPath: (nonnull NSString *) path;

// Check the signature.
- (void) checkSignature: (nonnull Launchd *) launchd;

// Load a launchd task.
- (void) load;

// Unload a launchd task.
- (void) unload;

// Requery the file.
- (void) requery;

// Is this a launchd file?
- (BOOL) isLaunchdFile;

// Is this a valid object?
+ (BOOL) isValid: (nullable LaunchdFile *) file;

@end
