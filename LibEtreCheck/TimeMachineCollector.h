/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "Collector.h"

@class ByteCountFormatter;

// Collect information about Time Machine.
@interface TimeMachineCollector : Collector
  {
  // An OS-independent byte count formatter.
  ByteCountFormatter * formatter;

  // Keep track of the minimum and maximum required sizes.
  unsigned long long minimumBackupSize;
  unsigned long long maximumBackupSize;

  // Time Machine destinations indexed by UUID.
  NSMutableDictionary * destinations;

  // Excluded paths.
  NSMutableSet * excludedPaths;

  // Excluded volumes.
  NSMutableSet * excludedVolumeUUIDs;
  }

@end
