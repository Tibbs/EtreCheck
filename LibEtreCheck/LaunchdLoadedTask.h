/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "LaunchdTask.h"

// Before 10.10, there is no gui domain.
#define kLaunchdSystemDomain @"system"
#define kLaunchdUserDomain @"user"
#define kLaunchdGUIDomain @"gui"

// A wrapper around a loaded launchd task.
@interface LaunchdLoadedTask : LaunchdTask
  {
  // The launchd domain. 
  NSString * myDomain;
  
  // The process ID.
  // Modern launchctl uses strings.
  NSString * myPID;
  
  // There can be multiple tasks per service identifier. Such tasks
  // have a UUID appended to the label. Try to remove that.
  NSString * baseLabel;
  }

// The launchd domain. 
@property (readonly, nullable) NSString * domain;
  
// The process ID. Sometimes, these are strings in Apple-land.
@property (readonly, nullable) NSString * PID;

// There can be multiple tasks per service identifier. Such tasks
// have a UUID appended to the label. Try to remove that.
@property (readonly, nonnull) NSString * baseLabel;

// Constructor with NSDictionary.
- (nullable instancetype) initWithDictionary: (nonnull NSDictionary *) dict
  inDomain: (nonnull NSString *) domain;

// Constructor with label.
- (nullable instancetype) initWithLabel: (nonnull NSString *) label
  inDomain: (nonnull NSString *) domain;

// Re-query a launchd task.
- (void) requery;

@end
