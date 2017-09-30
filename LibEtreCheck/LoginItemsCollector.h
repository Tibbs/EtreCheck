/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "Collector.h"

// Collect login items.
@interface LoginItemsCollector : Collector
  {
  NSMutableArray * myLoginItems;
  }

@property (readonly) NSMutableArray * loginItems;

@end
