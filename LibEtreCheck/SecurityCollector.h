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
  NSString * myInstalledXProtectVersion;
  
  // Installed Gatekeeper version.
  NSString * myInstalledGatekeeperVersion;
  
  // Installed MRT version.
  NSString * myInstalledMRTVersion;

  // Current XProtect version.
  NSString * myCurrentXProtectVersion;
  
  // Current Gatekeeper version.
  NSString * myCurrentGatekeeperVersion;
  
  // Current MRT version.
  NSString * myCurrentMRTVersion;
  
  // Are security versions outdated?
  BOOL myOutdated;
  }
  
// Names of critical Apple installs.
@property (readonly, nonnull) NSSet * AppleSecurityPackageNames;

// System Integrity Protection status.
@property (strong, nullable) NSString * SIPStatus;

// Installed XProtect version.
@property (strong, nullable) NSString * installedXProtectVersion;

// Installed Gatekeeper version.
@property (strong, nullable) NSString * installedGatekeeperVersion;

// Installed MRT version.
@property (strong, nullable) NSString * installedMRTVersion;

// Current XProtect version.
@property (strong, nullable) NSString * currentXProtectVersion;

// Current Gatekeeper version.
@property (strong, nullable) NSString * currentGatekeeperVersion;

// Current MRT version.
@property (strong, nullable) NSString * currentMRTVersion;

// Are security versions outdated?
@property (assign) BOOL outdated;

// Collect the Gatekeeper setting.
- (GatekeeperSetting) collectGatekeeperSetting;

@end
