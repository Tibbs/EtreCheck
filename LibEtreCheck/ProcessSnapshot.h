/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "Process.h"

// Encapsulate a running process.
@interface ProcessSnapshot : Process
  
// Constructor with a line from the following ps command:
// @"-raxcww", @"-o", @"pid, %cpu, rss, command"
- (instancetype) initWithPsLine: (NSString *) line;

// Constructor with a line from the following top command:
// @"-stats", @"pid,cpu,rize,power,command"
- (instancetype) initWithTopLine: (NSString *) line;

// Constructor with a line from a complex nettop command.
// @"-raxcww", @"-o", @"pid, %cpu, rss, command"
- (instancetype) initWithNettopLine: (NSString *) line;

@end
