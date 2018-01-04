/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

// Wrapper around Safari information.
@interface Safari : NSObject
  {
  // Extensions keyed by identifier.
  NSMutableDictionary * myExtensions;
  
  // Extensions keyed by name.
  NSMutableDictionary * myExtensionsByName;
  
  // Extensions identified as adware.
  NSMutableSet * myAdwareExtensions;
  
  // Extensions that are not loaded.
  NSMutableSet * myOrphanExtensions;
  
  // Counter for unique identifier.
  int myCounter;

  // A queue for unique identifiers.
  dispatch_queue_t myQueue;
  }

// Extensions keyed by identifier.
@property (readonly, nonnull) NSMutableDictionary * extensions;

// Extensions keyed by name.
@property (readonly, nonnull) NSMutableDictionary * extensionsByName;

// Extensions identified as adware.
@property (readonly, nonnull) NSMutableSet * adwareExtensions;

// Extensions that are not loaded.
@property (readonly, nonnull) NSMutableSet * orphanExtensions;

// Counter for unique identifier.
@property (assign) int counter;

// A queue for unique identifiers.
@property (readonly, nonnull) dispatch_queue_t queue;

// Load safari information.
- (void) load;

@end
