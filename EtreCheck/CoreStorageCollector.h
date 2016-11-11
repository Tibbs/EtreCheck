/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "Collector.h"

// Collect information about Core Storage.
@interface CoreStorageCollector : Collector

// Keep track of CoreStorage volumes.
@property (readonly) NSMutableDictionary * coreStorageVolumes;

@end
