/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2016. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>
#import "PopoverManager.h"

#define kFileDeleted @"filedeleted"
#define kPath @"path"
#define kLaunchdTask @"task"

@interface UninstallManager : NSObject
  {
  NSWindow * myWindow;
  NSTextView * myTextView;
  NSTableView * myTableView;
  
  // This is an array of dictionaries, not files. Because this class is
  // a manager for a user interface, use the concept being presented to
  // the user instead of what is actually going on.
  // Each dictionary has a path and optionally a launchd info dictionary.
  NSMutableArray * myFilesToRemove;
  
  BOOL myFilesRemoved;
  }

// The window itself.
@property (retain) IBOutlet NSWindow * window;

// The text view.
@property (retain) IBOutlet NSTextView * textView;

// The table view.
@property (retain) IBOutlet NSTableView * tableView;

// Can the manager remove any files?
@property (readonly) BOOL canRemoveFiles;

// Files to remove.
// This is an array of dictionaries, not files. Because this class is
// a manager for a user interface, use the concept being presented to
// the user instead of what is actually going on.
// Each dictionary has a path and optionally a launchd info dictionary.
@property (retain) NSMutableArray * filesToRemove;

// Were any files removed?
@property (assign) BOOL filesRemoved;

// Show the window.
- (void) show;

// Close the window.
- (IBAction) close: (id) sender;

// Remove files.
- (IBAction) removeFiles: (id) sender;

@end
