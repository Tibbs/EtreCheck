/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2016. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

#define kExecutableTimeout @"executabletimeout"

@interface SubProcess : NSObject
  {
  BOOL myTimedout;
  int myTimeout;
  int myResult;
  NSMutableData * myStandardOutput;
  NSMutableData * myStandardError;
  BOOL myUsePseudoTerminal;
  NSData * myDebugStandardOutput;
  NSData * myDebugStandardError;
  }

@property (assign) BOOL timedout;
@property (assign) int timeout;
@property (readonly) int result;
@property (readonly) NSMutableData * standardOutput;
@property (readonly) NSMutableData * standardError;
@property (assign) BOOL usePseudoTerminal;
@property (retain) NSData * debugStandardOutput;
@property (retain) NSData * debugStandardError;

// Execute an external program and return the results.
// If this returns NO, internal data structures are undefined.
- (BOOL) execute: (NSString *) program arguments: (NSArray *) args;

@end
