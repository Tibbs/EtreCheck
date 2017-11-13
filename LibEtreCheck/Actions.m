/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "Actions.h"
#import "Launchd.h"
#import "SubProcess.h"
#import "OSVersion.h"
#import "Utilities.h"
#import "EtreCheckConstants.h"
#import <Carbon/Carbon.h>
#import "LaunchdFile.h"
#import "LaunchdTask.h"
#import <sqlite3.h>
#import "UserNotification.h"

@implementation Actions

// Turn on Gatekeeper.
+ (void) enableGatekeeper
  {
  NSMutableString * command =
    [NSMutableString stringWithString: @"/usr/sbin/spctl --master-enable"];

  NSArray * statements =
    [NSArray arrayWithObject:
      [NSString
        stringWithFormat:
          @"do shell script(\"%@\") with administrator privileges",
          command]];
    
  // Execute the statements.
  [self executeAppleScriptStatements: statements];
  }

// Restart the machine.
+ (BOOL) restart
  {
  AEAddressDesc targetDesc;
  
  static const ProcessSerialNumber kPSNOfSystemProcess =
    { 0, kSystemProcess };
    
  AppleEvent eventReply = {typeNull, NULL};
  AppleEvent appleEventToSend = {typeNull, NULL};

  OSStatus error =
    AECreateDesc(
      typeProcessSerialNumber,
      & kPSNOfSystemProcess,
      sizeof(kPSNOfSystemProcess),
      & targetDesc);

  if(error != noErr)
    return NO;

  error =
    AECreateAppleEvent(
      kCoreEventClass,
      kAERestart,
      & targetDesc,
      kAutoGenerateReturnID,
      kAnyTransactionID,
      & appleEventToSend);

  AEDisposeDesc(& targetDesc);
  
  if(error != noErr)
    return NO;

  error =
    AESend(
      & appleEventToSend,
      & eventReply,
      kAENoReply,
      kAENormalPriority,
      kAEDefaultTimeout,
      NULL,
      NULL);

  AEDisposeDesc(& appleEventToSend);
  
  if(error != noErr)
    return NO;

  AEDisposeDesc(& eventReply);

  return YES;
  }

// Reveal a file in the Finder.
+ (void) revealFile: (NSString *) file
  {
  NSString * path = [file stringByExpandingTildeInPath];
  
  if([[NSFileManager defaultManager] fileExistsAtPath: path])
    {
    NSURL * url = [[NSURL alloc] initFileURLWithPath: path];
    
    NSArray * urls = [[NSArray alloc] initWithObjects: url, nil];
    
    [url release];
    
    [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs: urls];
    
    [urls release];
    }
  }
  
// Open a file in the default app.
+ (void) openFile: (NSString *) file
  {
  NSString * path = [file stringByExpandingTildeInPath];

  [[NSWorkspace sharedWorkspace] openFile: path];
  }
  
// Open a URL in the default web browser.
+ (void) openURL: (NSURL *) url
  {
  [[NSWorkspace sharedWorkspace] openURL: url];
  }
  
// Uninstall launchd files.
+ (nullable NSArray *) uninstall: (nonnull NSArray *) files
  {
  if(files.count > 0)
    {
    NSMutableSet * filesToUninstall = 
      [[NSMutableSet alloc] initWithArray: files];
  
    NSArray * uninstalledUserFiles = 
      [self uninstallUserFiles: filesToUninstall];
      
    for(LaunchdFile * file in uninstalledUserFiles)
      [filesToUninstall removeObject: file];
      
    NSArray * filesUninstalled =
      [self uninstallSystemFiles: filesToUninstall];
      
    [filesToUninstall release];
    
    return filesUninstalled;
    }
    
  return nil;
  }

// Load a launchd file.
+ (void) load: (nonnull LaunchdFile *) file
  {
  [file load];
  }

// Unload a launchd file.
+ (void) unload: (nonnull LaunchdFile *) file
  {
  [file unload];
  }

// Purge user notifications.
+ (void) purgeUserNotifications: (NSArray *) notifications
  {
  if(notifications.count == 0)
    return;
    
  char user_dir[1024];
  
  size_t size = confstr(_CS_DARWIN_USER_DIR, user_dir, 1024);
  
  if(size >= 1023)
    return;
  
  NSString * path =
    [[NSString stringWithUTF8String: user_dir]
      stringByAppendingPathComponent:
        @"com.apple.notificationcenter/db/db"];
  
  sqlite3 * handle = NULL;
  
  int result = sqlite3_open(path.fileSystemRepresentation, & handle);
  
  NSMutableArray * note_ids = [NSMutableArray new];
  
  for(UserNotification * notification in notifications)
    [note_ids addObject: notification.noteID];
    
  if(result == SQLITE_OK)
    {
    NSString * arguments = [note_ids componentsJoinedByString: @","];
    
    NSString * SQL =
      [NSString
        stringWithFormat:
          @"delete from notifications where note_id in (%@);", arguments];
    
    result = sqlite3_exec(handle, SQL.UTF8String, NULL, NULL, NULL);
    
    SQL =
      [NSString
        stringWithFormat:
          @"delete from scheduled_notifications where note_id in (%@);",
          arguments];
    
    sqlite3_exec(handle, SQL.UTF8String, NULL, NULL, NULL);

    SQL =
      [NSString
        stringWithFormat:
          @"delete from presented_notifications where note_id in (%@);",
          arguments];
    
    sqlite3_exec(handle, SQL.UTF8String, NULL, NULL, NULL);

    SQL =
      [NSString
        stringWithFormat:
          @"delete from presented_alerts where note_id in (%@);",
          arguments];
    
    sqlite3_exec(handle, SQL.UTF8String, NULL, NULL, NULL);

    SQL =
      [NSString
        stringWithFormat:
          @"delete from today_summary_notifications where note_id in (%@);",
          arguments];
    
    sqlite3_exec(handle, SQL.UTF8String, NULL, NULL, NULL);

    SQL =
      [NSString
        stringWithFormat:
          @"delete from tomorrow_summary_notifications where note_id in (%@);",
          arguments];
    
    sqlite3_exec(handle, SQL.UTF8String, NULL, NULL, NULL);

    SQL =
      [NSString
        stringWithFormat:
          @"delete from notification_source where note_id in (%@);",
          arguments];
    
    sqlite3_exec(handle, SQL.UTF8String, NULL, NULL, NULL);
    }
    
  [note_ids release];
  
  sqlite3_close(handle);
  }

// Trash files.
// There is no difference between privileged and unprivileged modes. The
// Finder handles that.
// Returns files that were successfully trashed.
+ (nullable NSArray *) trashFiles: (nonnull NSArray *) files
  {
  NSMutableArray * appleScriptStatements = [NSMutableArray new];
  
  // Build the statements I will need.
  [appleScriptStatements
    addObjectsFromArray: [self buildTrashStatements: files]];
  
  // Execute the statements. Go ahead and require administrator to simplify
  // the logic.
  [self executeAppleScriptStatements: appleScriptStatements];
  
  [appleScriptStatements release];
  
  NSMutableArray * trashedFiles = [NSMutableArray array];
  
  if(trashedFiles.count > 0)
    {
    for(NSString * path in files)
      if(![[NSFileManager defaultManager] fileExistsAtPath: path])
        [trashedFiles addObject: path];
        
    [self recordTrashedFiles: trashedFiles];
    }
    
  return trashedFiles;
  }

#pragma mark - Private methods

// Execute a list of AppleScript statements.
+ (void) executeAppleScriptStatements: (NSArray *) statements
  {
  if([statements count] == 0)
    return;
    
  NSMutableArray * args = [NSMutableArray array];
  
  for(NSString * statement in statements)
    if([statement length])
      {
      [args addObject: @"-e"];
      [args addObject: statement];
      }
    
  if([args count] == 0)
    return;
    
  SubProcess * subProcess = [[SubProcess alloc] init];

  [subProcess execute: @"/usr/bin/osascript" arguments: args];

  [subProcess release];
  }

// Uninstall user files.
// Returns files that were successfully uninstalled.
+ (NSArray *) uninstallUserFiles: (NSMutableSet *) filesToUninstall
  {
  NSSet * userFiles = [self findUserFiles: filesToUninstall];
  
  if(userFiles.count > 0)
    {
    NSSet * unloadedUserFiles = [self unloadUserFiles: userFiles];
  
    if(unloadedUserFiles.count > 0)
      return [self trashFiles: [unloadedUserFiles allObjects]];
    }
    
  return nil;
  }
  
// Uninstall system files.
// Returns files that were successfully uninstalled.
+ (NSArray *) uninstallSystemFiles: (NSMutableSet *) filesToUninstall
  {
  if(filesToUninstall.count > 0)
    {
    NSSet * unloadedSystemFiles = 
      [self unloadSystemFiles: filesToUninstall];
  
    if(unloadedSystemFiles.count > 0)
      return [self trashFiles: [unloadedSystemFiles allObjects]];
    }
    
  return nil;
  }

// Find all files that appear to be in the user context and will not need
// administrator privileges.
+ (NSSet *) findUserFiles: (NSSet *) files
  {
  NSMutableSet * userFiles = [NSMutableSet set];
  
  for(LaunchdFile * file in files)
    if([file.context isEqualToString: kLaunchdUserContext])
      [userFiles addObject: files];
      
  return userFiles;
  }
  
// Unload all user files.
// Returns all files in an unloaded state.
+ (NSSet *) unloadUserFiles: (NSSet *) files
  {
  NSMutableArray * paths = [NSMutableArray new];
  
  NSMutableSet * unloadedFiles = [NSMutableSet set];
  
  for(LaunchdFile * file in files)
    if(file.loaded)
      [paths addObject: file.path];
    else
      [unloadedFiles addObject: file];
      
  [self unloadLaunchdTasksInUserSpace: paths];
  [self killLaunchdTasksInUserSpace: paths];
  
  [paths release];

  for(LaunchdFile * file in files)
    {
    if(file.loaded)
      [file requery];
    
    if(!file.loaded)
      [unloadedFiles addObject: file];
    }
        
  return unloadedFiles;
  }
  
// Unload launchd tasks in userspace.
+ (void) unloadLaunchdTasksInUserSpace: (NSArray *) tasks
  {
  NSArray * args = [self buildUnloadArguments: tasks];
  
  if([args count] > 1)
    {
    SubProcess * unload = [[SubProcess alloc] init];

    [unload execute: @"/bin/launchctl" arguments: args];

    [unload release];
    }
  }

// Build an argument list for an unload command for a list of tasks.
+ (NSArray *) buildUnloadArguments: (NSArray *) tasks
  {
  NSMutableArray * args = [NSMutableArray array];
  
  [args addObject: @"unload"];
  [args addObject: @"-wF"];
  
  for(NSDictionary * info in tasks)
    {
    NSString * status = [info objectForKey: kStatus];

    // If it isn't already loaded, don't try to unload.
    if([status isEqualToString: kStatusNotLoaded])
      continue;
      
    // Try to unload with any other status, including failed.
    NSString * path = [info objectForKey: kPath];
    
    if([path length] > 0)
      [args addObject: path];
    }
    
  return args;
  }

// Kill launchd tasks in userspace.
+ (void) killLaunchdTasksInUserSpace: (NSArray *) tasks
  {
  NSArray * args = [self buildKillArguments: tasks];
  
  if([args count] > 1)
    {
    SubProcess * kill = [[SubProcess alloc] init];

    [kill execute: @"/bin/kill" arguments: args];

    [kill release];
    }
  }

// Build an argument list for a kill command for a list of tasks.
+ (NSArray *) buildKillArguments: (NSArray *) tasks
  {
  NSMutableArray * args = [NSMutableArray array];
  
  [args addObject: @"-9"];
  
  for(NSDictionary * info in tasks)
    {
    NSNumber * PID = [info objectForKey: kPID];
    
    // Make sure the process is valid and still running.
    if([PID integerValue] > 0)
      if([self ps: PID] != nil)
        [args addObject: [PID stringValue]];
    }
    
  return args;
  }

// Query the status of a process.
+ (NSString *) ps: (NSNumber *) pid
  {
  NSString * line = nil;
  
  SubProcess * ps = [[SubProcess alloc] init];
  
  if([ps execute: @"/bin/ps" arguments: @[ [pid stringValue] ]])
    {
    NSArray * lines = [Utilities formatLines: ps.standardOutput];
    
    if([lines count] > 1)
      line = [lines objectAtIndex: 1];
    }
    
  [ps release];
  
  return line;
  }

// Unload all system files using administrator privileges.
// Returns all files in an unloaded state.
+ (NSSet *) unloadSystemFiles: (NSSet *) files
  {
  NSMutableArray * paths = [NSMutableArray new];
  
  NSMutableSet * unloadedFiles = [NSMutableSet set];
  
  for(LaunchdFile * file in files)
    if(file.loaded)
      [paths addObject: file.path];
    else
      [unloadedFiles addObject: file];
      
  // Since this needs a password, try to do the kill here too.
  [self unloadLaunchdTasksInSystemSpace: paths];
  
  [paths release];

  for(LaunchdFile * file in files)
    {
    if(file.loaded)
      [file requery];
    
    if(!file.loaded)
      [unloadedFiles addObject: file];
    }
        
  return unloadedFiles;
  }

// Unload launchd tasks in userspace.
+ (void) unloadLaunchdTasksInSystemSpace: (NSArray *) tasks
  {
  NSMutableArray * appleScriptStatements = [NSMutableArray new];
  
  // Build the statements I will need.
  [appleScriptStatements
    addObjectsFromArray: [self buildUnloadStatements: tasks]];
  [appleScriptStatements
    addObjectsFromArray: [self buildKillStatement: tasks]];
  
  // Execute the statements.
  [self executeAppleScriptStatements: appleScriptStatements];
  
  [appleScriptStatements release];
  }

// Build one or more AppleScript statements to unload a list of
// launchd tasks.
+ (NSArray *) buildUnloadStatements: (NSArray *) tasks
  {
  NSMutableArray * statements = [NSMutableArray array];
  
  NSMutableString * command =
    [NSMutableString stringWithString: @"/bin/launchctl"];

  NSArray * filesToBeUnloaded = [self buildUnloadArguments: tasks];
  
  for(NSString * file in filesToBeUnloaded)
    [command appendFormat: @" %@", file];
    
  [statements addObject:
    [NSString
      stringWithFormat:
        @"do shell script(\"%@\") with administrator privileges",
        command]];
    
  return statements;
  }

// Build an AppleScript statement to kill a list of launchd tasks.
+ (NSArray *) buildKillStatement: (NSArray *) tasks
  {
  NSMutableArray * statements = [NSMutableArray array];
  
  NSMutableString * command =
    [NSMutableString stringWithString: @"/bin/kill"];

  NSArray * filesToBeUnloaded = [self buildKillArguments: tasks];
  
  for(NSString * file in filesToBeUnloaded)
    [command appendFormat: @" %@", file];
    
  [statements addObject:
    [NSString
      stringWithFormat:
        @"do shell script(\"%@\") with administrator privileges",
        command]];
    
  return statements;
  }

// Build an AppleScript statement to trash a list of files.
+ (NSArray *) buildTrashStatements: (NSArray *) paths
  {
  NSMutableArray * statements = [NSMutableArray array];
  
  NSMutableString * source = [NSMutableString string];
  
  [source appendString: @"set posixFiles to {"];
  
  int i = 0;
  
  for(NSString * path in paths)
    {
    if(i)
      [source appendString: @","];
      
    [source appendFormat: @"POSIX file \"%@\"", path];
    
    ++i;
    }

  [source appendString: @"}"];

  // Return an empty string that won't crash but can be ignored later.
  if(i > 0)
    {
    [statements addObject: source];
    
    [statements addObject: @"tell application \"Finder\""];
    [statements addObject: @"activate"];
    [statements addObject: @"repeat with posixFile in posixFiles"];
    [statements addObject: @"set f to posixFile as alias"];
    [statements addObject: @"set locked of f to false"];
    [statements addObject: @"end repeat"];
    [statements addObject: @"move posixFiles to the trash"];
    [statements addObject: @"end tell"];
    }
    
  return statements;
  }

// Record trashed files in preferences.
+ (void) recordTrashedFiles: (NSArray *) files
  {
  // Save deleted files.
  NSArray * currentDeletedFiles =
    [[NSUserDefaults standardUserDefaults]
      objectForKey: @"deletedfiles"];
    
  NSMutableArray * deletedFiles = [NSMutableArray array];
  
  if([currentDeletedFiles count])
    {
    // Remove any old files.
    NSDate * then =
      [[NSDate date] dateByAddingTimeInterval: -60 * 60 * 24 * 7];
    
    for(NSDictionary * entry in currentDeletedFiles)
      {
      NSDate * date = [entry objectForKey: @"date"];
      
      if([then compare: date] == NSOrderedAscending)
        [deletedFiles addObject: entry];
      }
    }
    
  NSDate * now = [NSDate date];
  
  // Add newly deleted files.
  for(NSString * path in files)
    {
    NSDictionary * entry =
      [NSDictionary
        dictionaryWithObjectsAndKeys:
          now, @"date",
          path, @"file",
          nil];
      
    [deletedFiles addObject: entry];
    }

  [[NSUserDefaults standardUserDefaults]
    setObject: deletedFiles forKey: @"deletedfiles"];
  }

@end
