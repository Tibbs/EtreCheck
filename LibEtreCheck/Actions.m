/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "Actions.h"
#import "Launchd.h"
#import "SubProcess.h"
#import "Utilities.h"
#import "EtreCheckConstants.h"
#import <Carbon/Carbon.h>

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

// Trash files.
+ (void) trashFiles: (NSArray *) files
  {
  NSMutableArray * appleScriptStatements = [NSMutableArray new];
  
  // Build the statements I will need.
  [appleScriptStatements
    addObjectsFromArray: [self buildTrashStatements: files]];
  
  // Execute the statements. Go ahead and require administrator to simplify
  // the logic.
  [self executeAppleScriptStatements: appleScriptStatements];
  
  [appleScriptStatements release];
  
  [self recordTrashedFiles: files];
  }

// Reveal a file in the Finder.
+ (void) revealFile: (NSString *) file
  {
  // See if the file is a directory.
  BOOL isDirectory = NO;
  
  BOOL exists = 
    [[NSFileManager defaultManager] 
      fileExistsAtPath: file isDirectory: & isDirectory];
  
  if(!exists)
    return;
    
  // If the file is a directory, just open it.
  if(isDirectory)
    [[NSWorkspace sharedWorkspace] openFile: file];
    
  // Otherwise, open the parent and select the file.
  else
    {
    NSURL * url = [[NSURL alloc] initFileURLWithPath: file];
    
    NSArray * urls = [[NSArray alloc] initWithObjects: url, nil];
    
    [url release];
    
    [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs: urls];
    
    [urls release];
    }
  }
  
#pragma mark - Private methods

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

#pragma mark - Legacy methods to be re-done.

// Uninstall launchd tasks.
+ (void) uninstallLaunchdTasks: (NSArray *) tasks
  {
  // Uninstalling is very tricky. Root does not have super-user privileges
  // in this context. Root cannot unload a launchd task in user space.
  
  // First try in user space. Only attempt to delete files if the unload
  // is successful.
  [self uninstallLaunchdTasksInUserSpace: tasks];
  
  // Now see what tasks are still running and try to unload them as root.
  [self uninstallLaunchdTasksWithAdministratorPrivileges: tasks];
  }

// Uninstall launchd tasks in user space. Be extra pedantic about
// everything.
+ (void) uninstallLaunchdTasksInUserSpace: (NSArray *) tasks
  {
  NSArray * userTasks = [self userLaunchdTasks: tasks];
  
  if([userTasks count] > 0)
    {
    [self unloadLaunchdTasksInUserSpace: userTasks];
    [self killLaunchdTasksInUserSpace: userTasks];
    [self deleteLaunchdTasksInUserSpace: userTasks];
    }
  }

// Filter out any tasks that are not in the user's home directory.
+ (NSArray *) userLaunchdTasks: (NSArray *) tasks
  {
  NSString * homeDirectory = NSHomeDirectory();
  
  NSMutableArray * userTasks = [NSMutableArray array];
  
  for(NSDictionary * info in tasks)
    {
    // Try to unload with any other status, including failed.
    NSString * path = [info objectForKey: kPath];
    
    // Make sure the path is rooted in the user's home directory.
    // This will also guarantee its validity.
    if([path hasPrefix: homeDirectory])
      [userTasks addObject: info];
    }
    
  return userTasks;
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

// Delete launchd files in userspace.
+ (void) deleteLaunchdTasksInUserSpace: (NSArray *) tasks
  {
  // Now delete any files that were successfully unloaded and killed.
  // Use the list of tasks so that this method can be re-used for the
  // root version.
  NSArray * tasksToBeDeleted =
    [self buildListOfTasksToBeDeleted: tasks];
    
  if([tasksToBeDeleted count] > 0)
    {
    NSMutableArray * appleScriptStatements = [NSMutableArray new];
    
    // Build the statements I will need.
    [appleScriptStatements
      addObjectsFromArray:
        [self buildDeleteStatementsForTasks: tasksToBeDeleted]];
    
    // Execute the statements.
    [self executeAppleScriptStatements: appleScriptStatements];
    
    [appleScriptStatements release];

    [self saveDeletedTasks: tasks];
    }
  }

// Build a list of files to be deleted.
// Use the list of tasks so that this method can be re-used for the
// root version.
+ (NSArray *) buildListOfTasksToBeDeleted: (NSArray *) tasks
  {
  NSMutableArray * tasksToBeDeleted = [NSMutableArray array];
  
  for(NSDictionary * info in tasks)
    {
    NSString * path = [info objectForKey: kPath];
    
    // Make sure the path is rooted in the user's home directory and that
    // it really exists.
    if([path length] > 0)
      if([[NSFileManager defaultManager] fileExistsAtPath: path])
        [tasksToBeDeleted addObject: info];
    }
    
  return tasksToBeDeleted;
  }

// Uninstall launchd tasks with root power. Be extra pedantic about
// everything.
+ (void) uninstallLaunchdTasksWithAdministratorPrivileges: (NSArray *) tasks
  {
  NSArray * rootTasks = [self rootLaunchdTasks: tasks];
  
  if([rootTasks count] > 0)
    {
    NSMutableArray * appleScriptStatements = [NSMutableArray new];
    
    // Build the statements I will need.
    [appleScriptStatements
      addObjectsFromArray: [self buildUnloadStatements: rootTasks]];
    [appleScriptStatements
      addObjectsFromArray: [self buildKillStatement: rootTasks]];
    
    // Execute the statements.
    [self executeAppleScriptStatements: appleScriptStatements];
    
    [appleScriptStatements release];
    
    // The Finder can do this on its own and this seems to be required.
    [self deleteLaunchdTasksInUserSpace: rootTasks];
    }
  }

// Filter out any tasks that are in the user's home directory.
+ (NSArray *) rootLaunchdTasks: (NSArray *) tasks
  {
  NSString * homeDirectory = NSHomeDirectory();
  
  NSMutableArray * rootTasks = [NSMutableArray array];
  
  for(NSDictionary * info in tasks)
    {
    // Try to unload with any other status, including failed.
    NSString * path = [info objectForKey: kPath];
    
    // Make sure the path is rooted in the user's home directory.
    // This will also guarantee its validity.
    if(![path hasPrefix: homeDirectory])
      [rootTasks addObject: info];
    }
    
  return rootTasks;
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

// Build an AppleScript statement to delete a list of launchd tasks.
+ (NSArray *) buildDeleteStatementsForTasks: (NSArray *) tasks
  {
  NSMutableArray * files = [NSMutableArray array];
  
  NSArray * tasksToBeDeleted =
    [self buildListOfTasksToBeDeleted: tasks];
  
  for(NSDictionary * info in tasksToBeDeleted)
    {
    NSString * path = [info objectForKey: kPath];
    
    if([path length] > 0)
      [files addObject: path];
    }
    
  return [self buildTrashStatements: files];
  }

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

// Save deleted launchd tasks in preferences.
+ (void) saveDeletedTasks: (NSArray *) tasks
  {
  NSMutableArray * files = [NSMutableArray array];
  
  for(NSDictionary * info in tasks)
    {
    NSString * path = [info objectForKey: kPath];
    
    if([path length])
      [files addObject: path];
    }
  
  [self recordTrashedFiles: files];
  }

// Query the status of a process.
+ (NSString *) ps: (NSNumber *) pid
  {
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  [subProcess autorelease];

  if([subProcess execute: @"/bin/ps" arguments: @[ [pid stringValue] ]])
    {
    NSArray * lines = [Utilities formatLines: subProcess.standardOutput];
    
    if([lines count] > 1)
      return [lines objectAtIndex: 1];
    }
    
  return nil;
  }

@end
