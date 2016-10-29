/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "Collector.h"

// Collect old startup items.
@interface StartupItemsCollector : Collector
  {
  NSDictionary * startupBundles;
  BOOL startupItemsFound;
  }

@end
