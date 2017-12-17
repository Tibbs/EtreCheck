/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "Collector.h"

// Collect information about unsigned files.
@interface UnsignedCollector : Collector
  {
  // Track all unique whitelist prefixes.
  NSSet * myWhitelistPrefixes;
  
  // Prefixes being looked up.
  NSMutableDictionary * myNetworkPrefixes;
  
  // A queue for managing asyncronous tasks.
  dispatch_queue_t myQueue;
  
  // A dispatch group for waiting for a number of tasks.
  dispatch_group_t myPendingTasks;
  
  // Am I emitting content already?
  BOOL myEmittingContent;
  }
  
// Track all unique whitelist prefixes.
@property (readonly) NSSet * whitelistPrefixes;

// Prefixes being looked up.
@property (readonly) NSMutableDictionary * networkPrefixes;
  
// A queue for managing asyncronous tasks.
@property (readonly) dispatch_queue_t queue;

// A semaphore for waiting for a number of tasks.
@property (readonly) dispatch_group_t pendingTasks;

// Am I emitting content already?
@property (assign) BOOL emittingContent;

@end
