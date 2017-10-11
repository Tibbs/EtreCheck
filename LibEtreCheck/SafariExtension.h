/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "PrintableItem.h"

#define kExtensionNotLoaded @"notloaded"
#define kExtensionDisabled @"disabled"
#define kExtensionEnabled @"enabled"

// Wrapper around a Safari extension.
@interface SafariExtension : PrintableItem
  {
  // Source path.
  NSString * myPath;
  
  // Name.
  NSString * myName;
  
  // Display name.
  NSString * myDisplayName;
  
  // Identifier.
  NSString * myIdentifier;
  
  // Loaded status.
  BOOL myLoaded;
  
  // Enabled status.
  BOOL myEnabled;
  
  // Developer web site.
  NSString * myDeveloperWebSite;
  }
  
// Source path.
@property (retain, nullable) NSString * path;

// Name.
@property (retain, nullable) NSString * name;

// Display name.
@property (retain, nullable) NSString * displayName;

// Identifier.
@property (retain, nullable) NSString * identifier;

// Loaded status.
@property (assign) BOOL loaded;

// Enabled status.
@property (assign) BOOL enabled;

// Developer web site.
@property (retain, nullable) NSString * developerWebSite;

// Constructor with path to extension.
- (nullable instancetype) initWithPath: (nonnull NSString *) path;

@end
