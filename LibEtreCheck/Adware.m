/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "Adware.h"

// A container for adware logic and data.
@implementation Adware

@synthesize adwareExtensions = myAdwareExtensions;
@synthesize whitelistFiles = myWhitelistFiles;
@synthesize whitelistPrefixes = myWhitelistPrefixes;
@synthesize blacklistFiles = myBlacklistFiles;
@synthesize blacklistMatches = myBlacklistMatches;
@synthesize blacklistSuffixes = myBlacklistSuffixes;
@synthesize legitimateStrings = myLegitimateStrings;

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    myAdwareExtensions = [NSMutableSet new];
    myWhitelistFiles = [NSMutableSet new];
    myWhitelistPrefixes = [NSMutableSet new];
    myBlacklistFiles = [NSMutableSet new];
    myBlacklistSuffixes = [NSMutableSet new];
    myBlacklistMatches = [NSMutableSet new];
    myLegitimateStrings = [NSMutableSet new];
    }
    
  return self;
  }

// Destructor.
- (void) dealloc
  {
  [myLegitimateStrings release];
  [myBlacklistSuffixes release];
  [myBlacklistMatches release];
  [myBlacklistFiles release];
  [myWhitelistFiles release];
  [myWhitelistPrefixes release];
  [myAdwareExtensions release];
  
  [super dealloc];
  }

// Add to the adware extensions list.
- (void) appendToAdwareExtensions: (NSArray *) names
  {
  [self.adwareExtensions addObjectsFromArray: names];
  }
  
// Add files to the whitelist.
- (void) appendToWhitelist: (NSArray *) names;
  {
  [self.whitelistFiles addObjectsFromArray: names];
  }
  
// Add files to the whitelist prefixes.
- (void) appendToWhitelistPrefixes: (NSArray *) names;
  {
  [self.whitelistPrefixes addObjectsFromArray: names];
  }
  
// Add files to the blacklist.
- (void) appendToBlacklist: (NSArray *) names
  {
  [self.blacklistFiles addObjectsFromArray: names];
  }

// Set the blacklist suffixes.
- (void) appendToBlacklistSuffixes: (NSArray *) names
  {
  [self.blacklistSuffixes addObjectsFromArray: names];
  }

// Set the blacklist matches.
- (void) appendToBlacklistMatches: (NSArray *) names
  {
  [self.blacklistMatches addObjectsFromArray: names];
  }

// Simulate adware.
- (void) simulate
  {
  [self.whitelistFiles removeObject: @"com.oracle.java.Java-Updater.plist"];
  [self.whitelistFiles removeObject: @"com.google.keystone.agent.plist"];
  [self.blacklistFiles addObject: @"com.google.keystone.agent.plist"];
  [self.blacklistMatches addObject: @"ASCPowerTools2"];
  }
  
@end
