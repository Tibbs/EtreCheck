/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>
#import "Collector.h"

@interface OldLaunchdCollector : Collector
  {
  NSMutableDictionary * myHiddenItems;
  bool myShowExecutable;
  NSUInteger myPressureKilledCount;
  NSUInteger myAppleNotLoadedCount;
  NSUInteger myAppleLoadedCount;
  NSUInteger myAppleRunningCount;
  NSUInteger myAppleKilledCount;
  }

// These need to be shared by all launchd collector objects.
@property (retain) NSMutableDictionary * launchdStatus;
@property (retain) NSMutableSet * appleLaunchd;
@property (assign) bool showExecutable;
@property (assign) NSUInteger pressureKilledCount;
@property (assign) NSUInteger AppleNotLoadedCount;
@property (assign) NSUInteger AppleLoadedCount;
@property (assign) NSUInteger AppleRunningCount;
@property (assign) NSUInteger AppleKilledCount;
@property (retain) NSMutableSet * knownAppleFailures;

// Collect property list files.
// Returns an array of plists for printing.
- (NSArray *) collectPropertyListFiles: (NSArray *) paths;

// Print property lists files.
- (void) printPropertyLists: (NSArray *) plists;

// Format a status into a string.
- (NSAttributedString *) formatPropertyListStatus: (NSDictionary *) status;

// Get the job status.
- (NSMutableDictionary *) collectJobStatus: (NSString *) path;

// Collect the job status for a label.
- (NSMutableDictionary *) collectJobStatusForLabel: (NSString *) label;

// Collect the command of the launchd item.
- (NSArray *) collectLaunchdItemCommand: (NSDictionary *) plist;

- (NSString *) collectLaunchdItemExecutable: (NSArray *) command
  info: (NSMutableDictionary *) info;

// Update a funky new dynamic task.
- (void) updateDynamicTask: (NSMutableDictionary *) info;

// Is this an Apple file that I expect to see?
- (bool) isAppleFile: (NSString *) path;

// Should I hide Apple tasks?
- (bool) hideAppleTasks;

// Does this file have the expected signature?
- (bool) hasExpectedSignature: (NSString *) file
  signature: (NSString *) signature;

// Handle whitelist exceptions.
- (void) updateAppleCounts: (NSDictionary *) info;

// Format Apple counts.
// Return YES if there was any output.
- (bool) formatAppleCounts: (NSMutableAttributedString *) output;

// Format a codesign response.
- (NSAttributedString *) formatSignature: (NSDictionary *) info
  forPath: (NSString *) path;

// Create a support link for a plist dictionary.
- (NSAttributedString *) formatSupportLink: (NSDictionary *) info;

// Release memory.
+ (void) cleanup;

@end
