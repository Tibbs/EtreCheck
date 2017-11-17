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
  long long myiCloudFree;
  }
  
// Network interfaces.
@property (readonly) NSMutableArray * interfaces;

// Ubiquity containers.
@property (readonly) NSMutableArray * ubiquityContainers;

// iCloud free amount.
@property (assign) long long iCloudFree;

@end
