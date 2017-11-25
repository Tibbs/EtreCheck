/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

@class LaunchdFile;

typedef void (^LaunchdCompletion)(LaunchdFile * _Nonnull file);
typedef void (^TrashCompletion)(NSArray * _Nonnull trashedFiles);

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
+ (void) load: (nonnull LaunchdFile *) file 
  completion: (nonnull LaunchdCompletion) completion;

// Unload a launchd file.
+ (void) unload: (nonnull LaunchdFile *) file 
  completion: (nonnull LaunchdCompletion) completion;

// Purge user notifications.
+ (void) purgeUserNotifications: (nonnull NSArray *) notifications;

// Trash files.
+ (void) trashFiles: (nonnull NSArray *) files 
  completion: (nonnull TrashCompletion) completion;

@end
