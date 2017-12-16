/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

@class LaunchdFile;
@class SafariExtension;

typedef void (^GatekeeperCompletion)(BOOL success);
typedef void (^LaunchdCompletion)(LaunchdFile * _Nonnull file);
typedef 
  void (^SafariExtensionCompletion)(SafariExtension * _Nonnull extension);

typedef void (^RemoveAdwareCompletion)(
  NSArray * _Nonnull removedAdwareFiles);

@interface Actions : NSObject

// Turn on Gatekeeper.
+ (void) enableGatekeeper: (nonnull GatekeeperCompletion) completion;

// Restart the machine.
// Return false if the restart fails. No way to notify success.
+ (BOOL) restart;

// Reveal a file in the Finder.
+ (void) revealFile: (nonnull NSString *) file;

// Open a file in the default app.
+ (void) openFile: (nonnull NSString *) file;

// Open a URL in the default web browser.
+ (void) openURL: (nonnull NSURL *) url;

// Load a launchd file.
+ (void) load: (nonnull LaunchdFile *) file 
  completion: (nonnull LaunchdCompletion) completion;

// Unload a launchd file.
+ (void) unload: (nonnull LaunchdFile *) file 
  completion: (nonnull LaunchdCompletion) completion;

// Purge user notifications.
+ (void) purgeUserNotifications: (nonnull NSArray *) notifications;

// Remove a launchd file.
+ (void) removeLaunchdFile: (nonnull LaunchdFile *) file 
  reason: (nonnull NSString *) reason
  completion: (nonnull LaunchdCompletion) completion;

// Remove a Safari extension.
+ (void) removeSafariExtension: (nonnull SafariExtension *) extension 
  reason: (nonnull NSString *) reason
  completion: (nonnull SafariExtensionCompletion) completion;

@end
