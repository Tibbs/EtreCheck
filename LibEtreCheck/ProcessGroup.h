/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "ProcessAttributes.h"

// Encapsulate a running process.
@interface ProcessGroup : ProcessAttributes
  {
  // Was this process reported on an EtreCheck report?
  BOOL myReported;
  
  // The processes in this group.
  NSMutableSet * myProcesses;
  }
  
// Was this app reported on an EtreCheck report?
@property (assign) BOOL reported;

// How many processes are included?
@property (readonly) NSUInteger count;

// The processes in this group.
@property (readonly) NSMutableSet * processes;

// Constructor with process attributes.
- (instancetype) initWithProcessAttributes: 
  (ProcessAttributes *) processAttributes;

// Update with new process attributes.
- (void) update: (ProcessAttributes *) processAttributes types: (int) types;

@end
