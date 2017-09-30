/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "Collector.h"

// Base class that knows how to handle plug-ins of various types.
@interface PlugInsCollector : Collector

// Parse plugins
- (void) parsePlugins: (NSString *) path;

// Parse user plugins
- (void) parseUserPlugins: (NSString *) type path: (NSString *) path;

@end
