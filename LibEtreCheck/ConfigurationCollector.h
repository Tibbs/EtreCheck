/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "Collector.h"

// Collect changes to config files like /etc/sysctl.conf and /etc/hosts.
@interface ConfigurationCollector : Collector
  {
  NSArray * myConfigFiles;
  NSArray * myModifiedFiles;
  NSArray * myModifications;
  }

// Config files that exist, but shouldn't.
@property (retain) NSArray * configFiles;

// Config files that are modified.
@property (retain) NSArray * modifiedFiles;

// Other modifications.
@property (retain) NSArray * modifications;

@end
