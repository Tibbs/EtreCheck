/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import <LibEtreCheck/LibEtreCheck.h>

@interface NetworkCollector : Collector
  {
  // Network interfaces.
  NSMutableArray * myInterfaces;
  
  // Ubiquity containers.
  NSMutableArray * myUbiquityContainers;
  
  // iCloud free amount.
  NSNumber * myiCloudFree;
  }
  
// Network interfaces.
@property (readonly) NSMutableArray * interfaces;

// Ubiquity containers.
@property (readonly) NSMutableArray * ubiquityContainers;

// iCloud free amount.
@property (assign) NSNumber * iCloudFree;

@end
