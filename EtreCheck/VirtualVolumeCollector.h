/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014-2017. All rights reserved.
 **********************************************************************/

#import "Collector.h"

// Collect information about virtual volumes.
@interface VirtualVolumeCollector : Collector

// Keep track of virtual volumes.
@property (readonly) NSMutableDictionary * virtualVolumes;

@end
