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
    
// Collect Gatekeeper status.
@interface GatekeeperCollector : Collector

// Collect the Gatekeeper setting.
- (GatekeeperSetting) collectGatekeeperSetting;

@end
