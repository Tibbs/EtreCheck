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
  }

// All extensions.
@property (retain) NSMutableDictionary * extensions;

// Loaded extensions.
@property (retain) NSMutableDictionary * loadedExtensions;

// Unloaded extensions.
@property (retain) NSMutableDictionary * unloadedExtensions;

// Unexpected extensions.
@property (retain) NSMutableDictionary * unexpectedExtensions;

// Extensions organized by directory.
@property (retain) NSMutableDictionary * extensionsByLocation;

@end
