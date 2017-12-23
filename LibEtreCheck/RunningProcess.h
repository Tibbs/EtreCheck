/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

// Encapsulate a running process.
@interface RunningProcess : NSObject
  {
  // The command being run.
  NSString * myCommand;

  // The path to the process.
  NSString * myPath;
  
  // The process name.
  NSString * myName;
  
  // The process ID.
  int myPID;
  
  // Is this an Apple app?
  BOOL myApple;
  
  // Was this app reported on an EtreCheck report?
  BOOL myReported;
  }
  
// The command being run.
@property (strong) NSString * command;

// The resolved path.
@property (readonly) NSString * path;

// The process name.
@property (readonly) NSString * name;

// The process ID.
@property (assign) int PID;

// Is this an Apple app?
@property (assign) BOOL apple;

// Was this app reported on an EtreCheck report?
@property (assign) BOOL reported;

@end
