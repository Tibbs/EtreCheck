/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2016. All rights reserved.
 **********************************************************************/

#import "NotificationSPAMCleanupManager.h"
#import "Model.h"
#import "TTTLocalizedPluralString.h"
#import "CleanupCollector.h"
#import "Utilities.h"

#define kRemove @"remove"
#define kKeep @"keep"
#define kApp @"app"
#define kText @"text"
#define kDate @"date"

#define kRemoveColumnIndex 0
#define kKeepColumnIndex 1

@implementation NotificationSPAMCleanupManager

@synthesize window = myWindow;
@synthesize tableView = myTableView;
@dynamic canRemove;
@synthesize notificationsToRemove = myNotificationsToRemove;
@synthesize dateFormatter = myDateFormatter;
@synthesize notificationsRemoved = myNotificationsRemoved;

// Destructor.
- (void) dealloc
  {
  [myDateFormatter release];
  [myWindow release];
  [myTableView release];
  [myNotificationsToRemove release];
  
  [super dealloc];
  }

// Can I remove notifications?
- (BOOL) canRemove
  {
  // Count the number of notification that have a remove flag.
  int count = 0;
  
  for(NSDictionary * notification in self.notificationsToRemove)
    {
    BOOL remove = [[notification objectForKey: kRemove] boolValue];
    
    if(remove)
      ++count;
    }
    
  return count > 0;
  }

- (NSDateFormatter *) dateFormatter
  {
  if(myDateFormatter == nil)
    myDateFormatter = [[NSDateFormatter alloc] init];
    
  return myDateFormatter;
  }

// Show the window.
- (void) show: (NSString *) bundleID
  {
  // Use a compact date format.
  [self.dateFormatter setDateStyle: NSDateFormatterShortStyle];
  [self.dateFormatter setTimeStyle: NSDateFormatterShortStyle];
  [self.dateFormatter setTimeZone: [NSTimeZone localTimeZone]];

  [self.window makeKeyAndOrderFront: self];
  
  [self loadNotifications: bundleID];
  }

// Load the notifications into the table.
- (void) loadNotifications: (NSString *) bundleID
  {
  self.notificationsRemoved = NO;
  
  myNotificationsToRemove = [NSMutableArray new];
  
  [self willChangeValueForKey: @"canRemove"];
  
  // Wrap each notification in another dictionary with remove/keep values.
  NSMutableDictionary * notifications =
    [[[Model model] notificationSPAMs] objectForKey: bundleID];
  
  for(NSString * note_id in notifications)
    {
    NSDictionary * notification = [notifications objectForKey: note_id];
    
    NSMutableDictionary * tableNotification =
      [[NSMutableDictionary alloc] initWithDictionary: notification];
      
    [tableNotification
      setObject: [NSNumber numberWithBool: YES] forKey: kRemove];
    [tableNotification
      setObject: [NSNumber numberWithBool: NO] forKey: kKeep];
    
    [self.notificationsToRemove addObject: tableNotification];
    
    [tableNotification release];
    }
    
  // Sort by date.
  [self.notificationsToRemove
    sortUsingComparator:
      ^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2)
      {
      NSDictionary * notification1 = obj1;
      NSDictionary * notification2 = obj2;
      
      NSUserNotification * userNotification1 =
        [notification1 objectForKey: @"notification"];

      NSUserNotification * userNotification2 =
        [notification2 objectForKey: @"notification"];
      
      if(userNotification2.deliveryDate == nil)
        return NSOrderedDescending;
        
      return
        [userNotification1.deliveryDate
          compare: userNotification2.deliveryDate];
      }];
  
  [self.tableView reloadData];
  
  [self didChangeValueForKey: @"canRemove"];
  }

// Close the window.
- (IBAction) close: (id) sender
  {
  if(self.notificationsRemoved)
    [self suggestRestart];
  
  [myNotificationsToRemove release];
  myNotificationsToRemove = nil;

  [self.window close];
  }

// Remove the notifications.
- (IBAction) removeNotifications: (id) sender
  {
  // Save the spammer for later.
  NSString * spammer = nil;
  
  // Keep track of the notifications to remove.
  NSMutableArray * note_ids = [NSMutableArray new];
  
  // Kepp track of the notifications to keep.
  NSMutableArray * notificationsToKeep = [NSMutableArray new];
  
  for(NSDictionary * notification in self.notificationsToRemove)
    {
    // Should I remove this one?
    BOOL remove = [[notification objectForKey: kRemove] boolValue];
    
    if(remove)
      {
      // Add this notification ID to the list to remove.
      NSNumber * noteID = [notification objectForKey: kNotificationNoteID];
      
      if(noteID != nil)
        {
        // Save the spammer.
        spammer = [notification objectForKey: kNotificationBundleID];
        
        [note_ids addObject: noteID];
        
        // Suggest a restart at the end.
        self.notificationsRemoved = YES;
        }
      }
    else
      [notificationsToKeep addObject: notification];
    }

  // Remove the notifications.
  [CleanupCollector purgeNotificationSPAM: note_ids];

  // Now remove the notifications from the model in case the user clicks
  // again.
  NSMutableDictionary * modelNotifications =
    [[[Model model] notificationSPAMs] objectForKey: spammer];
    
  for(NSNumber * note_id in note_ids)
    [modelNotifications removeObjectForKey: note_id];
    
  // Setup the table for the notifications that the user wanted to keep.
  [myNotificationsToRemove release];
  [note_ids release];
  
  myNotificationsToRemove = notificationsToKeep;
  
  [self willChangeValueForKey: @"canRemove"];

  [self.tableView reloadData];
  
  [self didChangeValueForKey: @"canRemove"];
  }

// Suggest a restart.
- (void) suggestRestart
  {
  NSAlert * alert = [[NSAlert alloc] init];

  [alert
    setMessageText: NSLocalizedString(@"Restart recommended", NULL)];
    
  [alert setAlertStyle: NSInformationalAlertStyle];

  NSString * message = NSLocalizedString(@"restartrecommended", NULL);
  
  [alert setInformativeText: message];

  // This is the rightmost, first, default button.
  [alert addButtonWithTitle: NSLocalizedString(@"Restart", NULL)];

  [alert addButtonWithTitle: NSLocalizedString(@"Restart later", NULL)];

  NSInteger result = [alert runModal];

  [alert release];

  if(result == NSAlertFirstButtonReturn)
    {
    if(![Utilities restart])
      [self restartFailed];
    }
  }

// Restart failed.
- (void) restartFailed
  {
  NSAlert * alert = [[NSAlert alloc] init];

  [alert setMessageText: NSLocalizedString(@"Restart failed", NULL)];
    
  [alert setAlertStyle: NSWarningAlertStyle];

  [alert setInformativeText: NSLocalizedString(@"restartfailed", NULL)];

  // This is the rightmost, first, default button.
  [alert addButtonWithTitle: NSLocalizedString(@"OK", NULL)];
  
  [alert runModal];

  [alert release];
  }

#pragma mark - NSTableViewDataSource

- (NSInteger) numberOfRowsInTableView: (NSTableView *) aTableView
  {
  return self.notificationsToRemove.count;
  }

- (id) tableView: (NSTableView *) tableView
  objectValueForTableColumn: (NSTableColumn *) tableColumn
  row: (NSInteger) row
  {
  if(row >= self.notificationsToRemove.count)
    return nil;

  NSMutableDictionary * item =
    [self.notificationsToRemove objectAtIndex: row];
  
  if([[tableColumn identifier] isEqualToString: kKeep])
    return [item objectForKey: kKeep];

  if([[tableColumn identifier] isEqualToString: kRemove])
    return [item objectForKey: kRemove];
    
  NSString * bundleID = [item objectForKey: kNotificationBundleID];

  if([[tableColumn identifier] isEqualToString: kApp])
    return bundleID;
    
  NSUserNotification * notification =
    [item objectForKey: kNotificationUserNotification];
  
  if([[tableColumn identifier] isEqualToString: kText])
    return notification.title;
    
  if([[tableColumn identifier] isEqualToString: kDate])
    return [self.dateFormatter stringFromDate: notification.deliveryDate];

  return nil;
  }

- (void) tableView: (NSTableView *) tableView
  setObjectValue: (id) object
  forTableColumn: (NSTableColumn *) tableColumn
  row: (NSInteger) row
  {
  if(row >= self.notificationsToRemove.count)
    return;
    
  [self willChangeValueForKey: @"canRemove"];
    
  NSMutableDictionary * item =
    [self.notificationsToRemove objectAtIndex: row];
    
  if([[tableColumn identifier] isEqualToString: kKeep])
    {
    [item setObject: object forKey: kKeep];
    
    if([object boolValue])
      [item setObject: [NSNumber numberWithBool: NO] forKey: kRemove];

    [tableView
      reloadDataForRowIndexes: [NSIndexSet indexSetWithIndex: row]
      columnIndexes: [NSIndexSet indexSetWithIndex: kRemoveColumnIndex]];
    }
  else if([[tableColumn identifier] isEqualToString: kRemove])
    {
    [item setObject: object forKey: kRemove];
    
    if([object boolValue])
      [item setObject: [NSNumber numberWithBool: NO] forKey: kKeep];
      
    [tableView
      reloadDataForRowIndexes: [NSIndexSet indexSetWithIndex: row]
      columnIndexes: [NSIndexSet indexSetWithIndex: kKeepColumnIndex]];
    }

  [self didChangeValueForKey: @"canRemove"];
  }

#pragma mark - NSTableViewDelegate

@end
