/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "PrintableItem.h"

// An iCloud file that needs to be reported.
@interface UbiquityFile : PrintableItem
  {
  // The file name.
  NSString * myName;
  
  // The status.
  NSString * myStatus;
  
  // The progress percentage.
  double myProgress;
  }

// The file name.
@property (readonly) NSString * name;

// The status.
@property (strong) NSString * status;

// The progress percentage.
@property (assign) double progress;

// Constructor.
- (instancetype) initWithName: (NSString *) name;

@end
