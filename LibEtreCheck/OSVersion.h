/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

// A wrapper around the OS version.
@interface OSVersion : NSObject
  {
  int myMajor;
  int myMinor;
  NSString * myBuild;
  NSString * myVersion;
  }
  
// Return the singeton.
+ (nonnull OSVersion *) shared;

// The OS major version.
@property (readonly) int major;

// The OS minor version.
@property (readonly) int minor;

// The build version.
@property (readonly, nullable) NSString * build;

// The full version.
@property (readonly, nullable) NSString * version;

@end
