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
  NSString * myBundleIdentifier;
  
  // Loaded status.
  BOOL myLoaded;
  
  // Enabled status.
  BOOL myEnabled;
  
  // Developer web site.
  NSString * myDeveloperWebSite;

  // I will need a unique, XML-safe identifier for each launchd file.
  NSString * myIdentifier;

  // Adware information.
  NSString * myAdware;
  
  // Details about this file.
  NSString * myDetails;
  }
  
// Source path.
@property (strong, nullable) NSString * path;

// Name.
@property (strong, nullable) NSString * name;

// Display name.
@property (strong, nullable) NSString * displayName;

// Identifier.
@property (strong, nullable) NSString * bundleIdentifier;

// Loaded status.
@property (assign) BOOL loaded;

// Enabled status.
@property (assign) BOOL enabled;

// Developer web site.
@property (strong, nullable) NSString * developerWebSite;

// I will need a unique, XML-safe identifier for each launchd file.
@property (strong, nullable) NSString * identifier;

// Adware information.
@property (strong, nullable) NSString * adware;

// Details about this file.
@property (strong, nullable) NSString * details;

// Constructor with path to extension.
- (nullable instancetype) initWithPath: (nonnull NSString *) path;

// Is this a Safari extension?
- (BOOL) isSafariExtension;

// Is this a valid object?
+ (BOOL) isValid: (nullable SafariExtension *) extension;

@end
