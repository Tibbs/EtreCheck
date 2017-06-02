/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2016. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

@interface NotificationSPAMCleanupManager : NSObject
  <NSTableViewDelegate, NSTableViewDataSource>
  {
  NSWindow * myWindow;
  NSTableView * myTableView;
  
  // This is an array of dictionaries, not files. Because this class is
  // a manager for a user interface, use the concept being presented to
  // the user instead of what is actually going on.
  // Each dictionary has a path and optionally a launchd info dictionary.
  NSMutableArray * myNotificationsToRemove;
  
  NSDateFormatter * myDateFormatter;
  
  BOOL myNotificationsRemoved;
  }

// The window itself.
@property (retain) IBOutlet NSWindow * window;

// The table view.
@property (retain) IBOutlet NSTableView * tableView;

// Can the manager remove any notifications?
@property (readonly) BOOL canRemove;

// Notifications to remove.
@property (readonly) NSMutableArray * notificationsToRemove;

// Date formatter.
@property (readonly) NSDateFormatter * dateFormatter;

// Were any notifications removed?
@property (assign) BOOL notificationsRemoved;

// Show the window.
- (void) show: (NSString *) bundleID;

// Close the window.
- (IBAction) close: (id) sender;

// Remove notifications.
- (IBAction) removeNotifications: (id) sender;

@end
