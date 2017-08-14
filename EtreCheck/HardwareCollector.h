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

// Find a machine icon.
- (NSImage *) findMachineIcon: (NSString *) code;

@end
