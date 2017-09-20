/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "Collector.h"

// Collect hardware information.
@interface HardwareCollector : Collector
  {
  NSDictionary * myProperties;
  NSImage * myMachineIcon;
  NSImage * myGenericDocumentIcon;
  NSString * myMarketingName;
  NSString * myEnglishMarketingName;
  NSString * myCPUCode;
  BOOL mySupportsHandoff;
  BOOL mySupportsInstantHotspot;
  BOOL mySupportsLowEnergy;
  }

// Machine properties.
@property (retain) NSDictionary * properties;

// The machine icon.
@property (retain) NSImage * machineIcon;

// A generic document icon in case a machine image lookup fails.
@property (retain) NSImage * genericDocumentIcon;

// The Apple Marketing name.
@property (retain) NSString * marketingName;

// English version of Apple Marketing name for the technical specifications
// fallback.
@property (retain) NSString * EnglishMarketingName;

// The CPU code.
@property (retain) NSString * CPUCode;

// Does the machine support handoff?
@property (assign) BOOL supportsHandoff;

// Does the machien support instant hotspot?
@property (assign) BOOL supportsInstantHotspot;

// Does the machien support low energy?
@property (assign) BOOL supportsLowEnergy;

@end
