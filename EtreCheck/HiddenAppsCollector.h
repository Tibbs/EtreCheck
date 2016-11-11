/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "LaunchdCollector.h"

// Collect "other" files like modern login items.
@interface HiddenAppsCollector : LaunchdCollector
  {
  NSDictionary * myProcesses;
  }

@property (retain) NSDictionary * processes;

@end
