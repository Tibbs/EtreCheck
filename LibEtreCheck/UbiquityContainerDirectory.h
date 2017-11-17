/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "PrintableItem.h"

@class UbiquityContainer;

@interface UbiquityContainerDirectory : PrintableItem
  {
  // The container-relative directory.
  NSString * myName;
  
  // The display directory.
  NSString * myDisplayName;
  
  // Pending files.
  NSMutableArray * myPendingFiles;
  }
  
// The container-relative directory.
@property (readonly) NSString * name;

// The display directory.
@property (strong) NSString * displayName;

// Pending files.
@property (strong) NSMutableArray * pendingFiles;

// Constructor with directory name.
- (instancetype) initWithContainer: (UbiquityContainer *) container 
  directory: (NSString *) name;

@end
