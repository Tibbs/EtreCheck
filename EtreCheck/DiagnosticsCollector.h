/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "Collector.h"

// Collect diagnostics information.
@interface DiagnosticsCollector : Collector
  {
  bool insufficientPermissions;
  
  BOOL hasOutput;
  
  NSMutableSet * myPaths;
  }

@property (retain) NSMutableSet * paths;

@end
