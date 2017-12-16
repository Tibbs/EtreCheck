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

  // Adware.
  NSString * myAdware;
  }
  
// Source path.
@property (retain, nullable) NSString * path;

// Name.
@property (retain, nullable) NSString * name;

// Display name.
@property (retain, nullable) NSString * displayName;

// Identifier.
@property (retain, nullable) NSString * bundleIdentifier;

// Loaded status.
@property (assign) BOOL loaded;

// Enabled status.
@property (assign) BOOL enabled;

// Developer web site.
@property (retain, nullable) NSString * developerWebSite;

// I will need a unique, XML-safe identifier for each launchd file.
@property (retain, nonnull) NSString * identifier;

// Adware type.
@property (strong, nullable) NSString * adware;

// Constructor with path to extension.
- (nullable instancetype) initWithPath: (nonnull NSString *) path;

// Is this a Safari extension?
- (BOOL) isSafariExtension;

// Is this a valid object?
+ (BOOL) isValid: (nullable SafariExtension *) extension;

@end
