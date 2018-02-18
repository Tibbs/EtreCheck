/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "Collector.h"

// Gatekeeper settings.
typedef enum
  {
  kNoGatekeeper,
  kSettingUnknown,
  kDisabled,
  kDeveloperID,
  kMacAppStore
  }
GatekeeperSetting;
    
// Collect Security status.
@interface SecurityCollector : Collector
  {
  // Names of Apple security packages.
  NSSet * myAppleSecurityPackageNames;
  
  // System Integrity Protection status.
  NSString * mySIPStatus;
  
  // Installed XProtect version.
  NSDate * myInstalledXProtectVersion;
  
  // Installed Gatekeeper version.
  NSDate * myInstalledGatekeeperVersion;
  
  // Installed MRT version.
  NSDate * myInstalledMRTVersion;

  // Current XProtect version.
  NSDate * myCurrentXProtectVersion;
  
  // Current Gatekeeper version.
  NSDate * myCurrentGatekeeperVersion;
  
  // Current MRT version.
  NSDate * myCurrentMRTVersion;
  
  // Are security versions outdated?
  BOOL myOutdated;
  }
  
// Names of critical Apple installs.
@property (readonly, nonnull) NSSet * AppleSecurityPackageNames;

// System Integrity Protection status.
@property (strong, nullable) NSString * SIPStatus;

// Installed XProtect version.
@property (strong, nullable) NSDate * installedXProtectVersion;

// Installed Gatekeeper version.
@property (strong, nullable) NSDate * installedGatekeeperVersion;

// Installed MRT version.
@property (strong, nullable) NSDate * installedMRTVersion;

// Current XProtect version.
@property (strong, nullable) NSDate * currentXProtectVersion;

// Current Gatekeeper version.
@property (strong, nullable) NSDate * currentGatekeeperVersion;

// Current MRT version.
@property (strong, nullable) NSDate * currentMRTVersion;

// Are security versions outdated?
@property (assign) BOOL outdated;

// Collect the Gatekeeper setting.
- (GatekeeperSetting) collectGatekeeperSetting;

@end
