/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "Collector.h"

// Collect kernel extensions.
@interface KernelExtensionCollector : Collector
  {
  NSMutableDictionary * myExtensions;
  NSMutableDictionary * myLoadedExtensions;
  NSMutableDictionary * myUnloadedExtensions;
  NSMutableDictionary * myUnexpectedExtensions;
  NSMutableDictionary * myExtensionsByLocation;
  NSSet * myBlockedTeams;
  }

// All extensions.
@property (strong) NSMutableDictionary * extensions;

// Loaded extensions.
@property (strong) NSMutableDictionary * loadedExtensions;

// Unloaded extensions.
@property (strong) NSMutableDictionary * unloadedExtensions;

// Unexpected extensions.
@property (strong) NSMutableDictionary * unexpectedExtensions;

// Extensions organized by directory.
@property (strong) NSMutableDictionary * extensionsByLocation;

// Blocked extensions.
@property (strong) NSSet * blockedTeams;

@end
