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
  }
  
// Return the singeton.
+ (nonnull OSVersion *) shared;

// The OS major version.
@property (readonly) int major;

// The OS minor version.
@property (readonly) int minor;

@end
