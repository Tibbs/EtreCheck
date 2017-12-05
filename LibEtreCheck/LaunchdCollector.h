/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "Collector.h"

// Collect all sorts of launchd information.
@interface LaunchdCollector : Collector
  
// Print files in a given directory.
- (void) printFilesInDirectory: (nonnull NSString *) directory;

@end
