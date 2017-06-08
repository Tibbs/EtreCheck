/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014-2017. All rights reserved.
 **********************************************************************/

#import "DiskCollector.h"

// Collect information about virtual volumes.
@interface VirtualVolumeCollector : DiskCollector
  {
  NSMutableDictionary * myVirtualVolumes;
  }
  
// Keep track of virtual volumes.
@property (readonly) NSMutableDictionary * virtualVolumes;

@end
