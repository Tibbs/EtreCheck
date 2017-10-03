/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

@interface Actions : NSObject

// Turn on Gatekeeper.
+ (void) enableGatekeeper;

// Restart the machine.
+ (BOOL) restart;

// Trash files.
+ (void) trashFiles: (NSArray *) files;

#pragma mark - Legacy methods to be re-done.

// Uninstall launchd tasks.
+ (void) uninstallLaunchdTasks: (NSArray *) tasks;

@end
