/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "Collector.h"

// Collect Safari extensions.
@interface SafariExtensionsCollector : Collector
  {
  NSMutableDictionary * myExtensions;
  NSMutableDictionary * myExtensionsByName;
  }

// Key is extension idenifier.
@property (retain) NSMutableDictionary * extensions;

// Key is extension name.
@property (retain) NSMutableDictionary * extensionsByName;

@end
