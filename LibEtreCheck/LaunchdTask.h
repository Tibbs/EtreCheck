/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

// A wrapper around a launchd task.
@interface LaunchdTask : NSObject
  {
  // The launchd domain.
  NSString * myDomain;
  
  // The launchd label.
  NSString * myLabel;
  
  // The process ID.
  long myPID;
  
  // The last exit code.
  long myLastExitCode;
  
  // The executable or script.
  NSString * myExecutable;
  
  // The arguments.
  NSArray * myArguments;
  
  // The signature.
  NSString * mySignature;
  
  // The developer.
  NSString * myDeveloper;
  }

// The launchd domain.
@property (readonly, nonnull) NSString * domain;

// The launchd label.
@property (readonly, nonnull) NSString * label;

// The process ID.
@property (readonly) long PID;

// The last exit code.
@property (readonly) long lastExitCode;

// The executable or script.
@property (readonly, nonnull) NSString * executable;

// The arguments.
@property (readonly, nonnull) NSArray * arguments;

// The signature.
@property (readonly, nonnull) NSString * signature;

// The developer.
@property (readonly, nullable) NSString * developer;

// Constructor with NSDictionary.
- (nullable instancetype) initWithDictionary: (nonnull NSDictionary *) dict
  inDomain: (nonnull NSString *) domain;

// Constructor with new 10.10 launchd output.
- (nullable instancetype) initWithLaunchd: (nullable NSString *) plist
  inDomain: (nonnull NSString *) domain;

@end
