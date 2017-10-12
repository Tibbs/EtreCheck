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
  }

// Extensions keyed by identifier.
@property (readonly, nonnull) NSMutableDictionary * extensions;

// Extensions keyed by name.
@property (readonly, nonnull) NSMutableDictionary * extensionsByName;

// Extensions identified as adware.
@property (readonly, nonnull) NSMutableSet * adwareExtensions;

// Extensions that are not loaded.
@property (readonly, nonnull) NSMutableSet * orphanExtensions;

// Load safari information.
- (void) load;

@end
