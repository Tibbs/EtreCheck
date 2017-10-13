/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

// A container for adware logic and data.
@interface Adware : NSObject
  {
  NSMutableSet * myAdwareExtensions;
  NSMutableSet * myWhitelistFiles;
  NSMutableSet * myWhitelistPrefixes;
  NSMutableSet * myBlacklistFiles;
  NSMutableSet * myBlacklistSuffixes;
  NSMutableSet * myBlacklistMatches;  

  NSMutableSet * myLegitimateStrings;  
  }
  
// Adware extensions.
@property (readonly) NSMutableSet * adwareExtensions;

// Whitelist files.
@property (readonly) NSMutableSet * whitelistFiles;

// Whitelist prefixes.
@property (readonly) NSMutableSet * whitelistPrefixes;

// Blacklist files.
@property (readonly) NSMutableSet * blacklistFiles;

// Blacklist suffixes.
@property (readonly) NSMutableSet * blacklistSuffixes;

// Blacklist matches.
@property (readonly) NSMutableSet * blacklistMatches;

// Strings of potentially legitimate files.
@property (readonly) NSMutableSet * legitimateStrings;

// Add to the adware extensions list.
- (void) appendToAdwareExtensions: (NSArray *) names;

// Add files to the whitelist.
- (void) appendToWhitelist: (NSArray *) names;

// Add files to the whitelist prefixes.
- (void) appendToWhitelistPrefixes: (NSArray *) names;

// Add files to the blacklist.
- (void) appendToBlacklist: (NSArray *) names;

// Set the blacklist suffixes.
- (void) appendToBlacklistSuffixes: (NSArray *) names;

// Set the blacklist matches.
- (void) appendToBlacklistMatches: (NSArray *) names;

// Simulate adware.
- (void) simulate;

@end
