/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2016. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

#define kExecutableTimeout @"executabletimeout"

// Run a subprocess.
@interface SubProcess : NSObject
  {
  // Did the task time out?
  BOOL myTimedout;
  
  // The task timeout.
  int myTimeout;
  
  // The task result.
  int myResult;
  
  // Standard output.
  NSMutableData * myStandardOutput;
  
  // Standard error.
  NSMutableData * myStandardError;
  
  // Does the task need a tty?
  BOOL myUsePseudoTerminal;
  
  // Debug data to stuff into standard output.
  NSData * myDebugStandardOutput;
  
  // Debug data to stuff into standard error.
  NSData * myDebugStandardError;
  
  // Path to save debug output.
  NSString * myDebugOutputPath;
  }

// Did the task time out?
@property (assign) BOOL timedout;

// The task timeout.
@property (assign) int timeout;
  
// The task result.
@property (readonly) int result;
  
// Standard output.
@property (readonly) NSMutableData * standardOutput;
  
// Standard error.
@property (readonly) NSMutableData * standardError;

// Does the task need a tty?
@property (assign) BOOL usePseudoTerminal;

// Debug data to stuff into standard output.
@property (strong) NSData * debugStandardOutput;

// Debug data to stuff into standard error.
@property (strong) NSData * debugStandardError;

// Path to save debug output.
@property (strong) NSString * debugOutputPath;

// Execute an external program and return the results.
// If this returns NO, internal data structures are undefined.
- (BOOL) execute: (NSString *) program arguments: (NSArray *) args;

// Load debug information.
- (void) loadDebugOutput: (NSString *) path;

// Save debug information.
- (void) saveDebugOutput: (NSString *) path;

@end
