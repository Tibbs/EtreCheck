/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "Collector.h"

// Collect information about disks.
@interface DiskCollector : Collector

// Provide easy access to volumes.
@property (readonly) NSMutableDictionary * volumes;

// Get the SMART status for this disk.
- (void) collectSMARTStatus: (NSDictionary *) disk
  indent: (NSString *) indent;

// Print the volumes on a disk.
- (void) printDiskVolumes: (NSDictionary *) disk;

// Print information about a volume.
- (void) printVolume: (NSDictionary *) volume indent: (NSString *) indent;

// Get the size of a volume.
- (NSString *) volumeSize: (NSDictionary *) volume;

// Get the free space on the volume.
- (NSString *) volumeFreeSpace: (NSDictionary *) volume;

// Get more information about a device.
- (NSString *) errorsFor: (NSNumber *) errors;

// Print disks attached to a single NVMExpress controller.
- (BOOL) printController: (NSDictionary *) controller
  type: (NSString *) type dataFound: (BOOL) dataFound;

@end
