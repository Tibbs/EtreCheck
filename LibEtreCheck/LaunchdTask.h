/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

#define kLaunchdAppleContext @"apple"
#define kLaunchdSystemContext @"system"
#define kLaunchdUserContext @"user"
#define kLaunchdUnknownContext @"unknown"

#define kLaunchdSystemDomain @"system"
#define kLaunchdUserDomain @"user"
#define kLaunchdUnknownDomain @"unknown"

#define kLaunchdServiceManagementSource @"sm"
#define kLaunchdOldLaunchctlSource @"oldlaunchctl"
#define kLaunchdNewLaunchctlSource @"newlaunchctl"
#define kLaunchdLaunchctlListingSource @"list"
#define kLaunchdFileSource @"file"

// A wrapper around a launchd task.
@interface LaunchdTask : NSObject
  {
  // Path to the config script.
  NSString * myPath;
  
  // Is the config script valid?
  BOOL myConfigScriptValid;
  
  // The launchd context. (apple, system, user)
  NSString * myContext;
  
  // The launchd domain. 
  NSString * myDomain;
  
  // The query source. (sm, oldlaunchd, newlaunchd, list, file)
  NSString * mySource;
  
  // The launchd label.
  NSString * myLabel;
  
  // The process ID.
  NSString * myPID;
  
  // The last exit code.
  NSString * myLastExitCode;
  
  // The executable or script.
  NSString * myExecutable;
  
  // The arguments.
  NSArray * myArguments;
  
  // The signature.
  NSString * mySignature;
  
  // The developer.
  NSString * myDeveloper;
  }

// Path to the config script.
@property (readonly, nullable) NSString * path;

// Is the config script valid?
@property (readonly) BOOL configScriptValid;

// The launchd context. (apple, system, user)
@property (readonly, nullable) NSString * context;

// The launchd domain. 
@property (readonly, nullable) NSString * domain;
  
// The query source. (oldlaunchd, newlaunchd, list, file)
@property (readonly, nonnull) NSString * source;

// The launchd label.
@property (readonly, nullable) NSString * label;

// The process ID. Sometimes, these are strings in Apple-land.
@property (readonly, nullable) NSString * PID;

// The last exit code. Sometimes, these are strings in Apple-land.
@property (readonly, nullable) NSString * lastExitCode;

// The executable or script.
@property (readonly, nullable) NSString * executable;

// The arguments.
@property (readonly, nullable) NSArray * arguments;

// The signature.
@property (readonly, nullable) NSString * signature;

// The developer.
@property (readonly, nullable) NSString * developer;

// Constructor with NSDictionary.
- (nullable instancetype) initWithDictionary: (nonnull NSDictionary *) dict;

// Constructor with new 10.10 launchd output.
- (nullable instancetype) initWithNewLaunchdData: (nonnull NSData *) data;

// Constructor with old launchd output.
- (nullable instancetype) initWithOldLaunchdData: (nonnull NSData *) data;

// Constructor with label.
- (nullable instancetype) initWithLabel: (nonnull NSString *) label
  PID: (nonnull NSString *) PID
  lastExitCode: (nonnull NSString *) lastExitCode;

// Constructor with path.
- (nullable instancetype) initWithPath: (nonnull NSString *) path;

// Load a launchd task.
- (void) load;

// Unload a launchd task.
- (void) unload;

@end
