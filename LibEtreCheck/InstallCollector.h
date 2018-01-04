/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "Collector.h"

// Collect install information.
@interface InstallCollector : Collector
  {
  // Critical Apple installs.
  NSMutableDictionary * myCriticalAppleInstalls;
  
  // Critical Apple installs still pending.
  NSMutableDictionary * myPendingCriticalAppleInstalls;
  
  // Names of critical Apple installs.
  NSSet * myCriticalAppleInstallNames;
  
  // A lookup table for critical Apple install names from package filenames.
  NSDictionary * myCriticalAppleInstallNameLookup;
  
  // Install items.
  NSMutableArray * myInstalls;
  
  // Names of security updates.
  NSSet * mySecurityUpdateNames;
  }

// Critical Apple installs.
@property (readonly) NSMutableDictionary * criticalAppleInstalls;

// Critical Apple installs still pending.
@property (readonly) NSMutableDictionary * pendingCriticalAppleInstalls;
  
// Names of critical Apple installs.
@property (readonly) NSSet * criticalAppleInstallNames;

// A lookup table for critical Apple install names from package filenames.
@property (readonly) NSDictionary * criticalAppleInstallNameLookup;

// Install items.
@property (readonly) NSMutableArray * installs;

// Names of security updates.
@property (readonly) NSSet * securityUpdateNames;

@end
