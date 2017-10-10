/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "Collector.h"

// Collect information about adware.
@interface AdwareCollector : Collector
  {
  // Launcd adware files.
  NSMutableArray * myLaunchdAdwareFiles;
  
  // Safari extension adware files.
  NSMutableArray * mySafariExtensionAdwareFiles;
  }

// Launcd adware files.
@property (readonly, nonnull) NSMutableArray * launchdAdwareFiles;

// Safari extension adware files.
@property (readonly, nonnull) NSMutableArray * safariExtensionAdwareFiles;

@end
