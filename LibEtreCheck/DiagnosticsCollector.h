/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "Collector.h"

@class DiagnosticEvent;
@class Model;

// Collect diagnostics information.
@interface DiagnosticsCollector : Collector
  {
  bool insufficientPermissions;
  
  BOOL hasOutput;
  
  NSMutableSet * myPaths;
  }

@property (retain) NSMutableSet * paths;

// Parse diagnostic data.
+ (void) parseDiagnosticData: (NSString *) contents
  event: (DiagnosticEvent *) event model: (Model *) model;

@end
