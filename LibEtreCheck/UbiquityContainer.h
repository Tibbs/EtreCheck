/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "PrintableItem.h"

@class UbiquityContainerDirectory;

@interface UbiquityContainer : PrintableItem
  {
  // The ubiquity ID for this container.
  NSString * myUbiquityID;
  
  // This container's bundle ID.
  NSString * myBundleID;
  
  // A dictionary of UbiquityContainerDirectories.
  NSMutableDictionary * myDirectories;
  
  // The current directory.
  UbiquityContainerDirectory * myCurrentDirectory;
  }
  
// The ubiquity ID for this container.
@property (readonly) NSString * ubiquityID;

// This container's bundle ID.
@property (strong) NSString * bundleID;

// A dictionary of UbiquityContainerDirectories.
@property (strong) NSMutableDictionary * directories;

// The current directory.
@property (strong) UbiquityContainerDirectory * currentDirectory;

// The pending file count.
@property (readonly) int pendingFileCount;

// Constructor.
- (instancetype) initWithUbiquityID: (NSString *) ubiquityID;

// Parse a line from brctl status.
- (void) parseBrctlStatusLine: (NSString *) line;

@end
