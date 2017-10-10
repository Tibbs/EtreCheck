/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "Collector.h"

// Collect all sorts of launchd information.
@interface LaunchdCollector : Collector
  {
  // Additional attributes indexed by path.
  NSMutableDictionary * myAttributes;
  }
  
// Additional attributes indexed by path.
@property (readonly, nonnull) NSMutableDictionary * attributes;

// Print files in a given directory.
- (void) printFilesInDirectory: (nonnull NSString *) directory;

@end
