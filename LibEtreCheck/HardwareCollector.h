/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "Collector.h"

// Collect hardware information.
@interface HardwareCollector : Collector
  {
  // Machine properties.
  NSDictionary * myProperties;
  
  // Machine icon.
  NSImage * myMachineIcon;
  
  // A generic document icon in case a machine image lookup fails.
  NSImage * myGenericDocumentIcon;
  
  // The Apple Marketing name.
  NSString * myMarketingName;
  
  // English version of Apple Marketing name for the technical 
  // specifications fallback.
  NSString * myEnglishMarketingName;
  
  // The CPU code.
  NSString * myCPUCode;
  
  // Does the machine support handoff?
  BOOL mySupportsHandoff;
  
  // Does the machine support instant hotspot?
  BOOL mySupportsInstantHotspot;
  
  // Does the machine support low energy?
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

// English version of Apple Marketing name for the technical 
// specifications fallback.
@property (retain) NSString * EnglishMarketingName;

// The CPU code.
@property (retain) NSString * CPUCode;

// Does the machine support handoff?
@property (assign) BOOL supportsHandoff;

// Does the machine support instant hotspot?
@property (assign) BOOL supportsInstantHotspot;

// Does the machine support low energy?
@property (assign) BOOL supportsLowEnergy;

@end
