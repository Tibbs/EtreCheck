/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

@class LaunchdFile;

@interface Actions : NSObject

// Turn on Gatekeeper.
+ (void) enableGatekeeper;

// Restart the machine.
+ (BOOL) restart;

// Reveal a file in the Finder.
+ (void) revealFile: (nonnull NSString *) file;

// Open a file in the default app.
+ (void) openFile: (nonnull NSString *) file;

// Open a URL in the default web browser.
+ (void) openURL: (nonnull NSURL *) url;

// Uninstall launchd files.
// Returns files that were successfully uninstalled.
+ (nullable NSArray *) uninstall: (nonnull NSArray *) files;

// Load a launchd file.
+ (void) load: (nonnull LaunchdFile *) file;

// Unload a launchd file.
+ (void) unload: (nonnull LaunchdFile *) file;

// Purge user notifications.
+ (void) purgeUserNotifications: (nonnull NSArray *) notifications;

// Trash files.
+ (nullable NSArray *) trashFiles: (nonnull NSArray *) files;

@end
