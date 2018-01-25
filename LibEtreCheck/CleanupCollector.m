/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "CleanupCollector.h"
#import "Model.h"
#import "DiagnosticEvent.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"
#import "LaunchdCollector.h"
#import <sqlite3.h>
#import <unistd.h>
#import "XMLBuilder.h"
#import "EtreCheckConstants.h"
#import "LocalizedString.h"
#import "Launchd.h"
#import "LaunchdFile.h"
#import "Safari.h"
#import "SafariExtension.h"
#import "UserNotification.h"
#import "OSVersion.h"
#import "NSArray+Etresoft.h"
#import "NSString+Etresoft.h"
#import "NSDictionary+Etresoft.h"

#define kWhitelistKey @"whitelist"
#define kWhitelistPrefixKey @"whitelist_prefix"

// Collect information about clean up opportuntities.
@implementation CleanupCollector

// Constructor.
- (id) init
  {
  self = [super initWithName: @"cleanup"];
  
  if(self != nil)
    {
    }
    
  return self;
  }

// Perform the collection.
- (void) performCollect
  {
  [self collectNotificationSPAM];
  
  // Orphan launchd files have already been collected.
  
  [self collectOrphanSafariExtensions];
  
  [self printCleanup];
  [self exportCleanup];
  }

// Collection notification SPAM.
- (void) collectNotificationSPAM
  {
  if([[OSVersion shared] major] < kMountainLion)
    return;
    
  NSMutableDictionary * notifications = [self collectNotifications];
  
  if(self.simulating)
    {
    NSMutableArray * simulatedNotifications = [NSMutableArray new];
    
    for(int i = 2; i <= 5; ++i)
      {
      UserNotification * notification = 
        [[UserNotification alloc] 
          initWithBundleID: @"com.spammer.simulated" 
          noteID: [NSNumber numberWithInt: i]];
          
      [simulatedNotifications addObject: notification];
      
      [notification release];
      }
      
    [notifications 
      setObject: simulatedNotifications forKey: @"com.spammer.simulated"];
    }
  
  [self checkForSPAM: notifications];
  }
  
// Check for SPAM notifications.
- (void) checkForSPAM: (NSMutableDictionary *) notifications
  {
  for(NSString * bundleID in notifications)
    {
    NSMutableArray * appNotifications =
      [notifications objectForKey: bundleID];
      
    if(![NSArray isValid: appNotifications])
      continue;
      
    if(appNotifications.count < 4)
      continue;
      
    [appNotifications
      sortUsingComparator:
        ^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2)
        {
        UserNotification * notification1 = obj1;
        UserNotification * notification2 = obj2;
        
        if(notification1.noteID == nil)
          return NSOrderedDescending;
          
        return [notification1.noteID compare: notification2.noteID];
        }];
      
    NSInteger firstNoteID =
      [[[appNotifications firstObject] noteID] integerValue];
    
    NSInteger lastNoteID =
      [[[appNotifications lastObject] noteID] integerValue];
      
    if((lastNoteID - firstNoteID) == (appNotifications.count - 1))
      [[self.model notificationSPAMs]  
        setObject: appNotifications forKey:bundleID];
    }
  }
  
// Collect all notifications.
- (NSMutableDictionary *) collectNotifications
  {
  char user_dir[1024];
  
  size_t size = confstr(_CS_DARWIN_USER_DIR, user_dir, 1024);
  
  if(size >= 1023)
    return nil;
  
  NSString * path =
    [[NSString stringWithUTF8String: user_dir]
      stringByAppendingPathComponent:
        @"com.apple.notificationcenter/db/db"];
  
  sqlite3 * handle = NULL;
  
  int result = sqlite3_open(path.fileSystemRepresentation, & handle);
  
  if(result != SQLITE_OK)
    return nil;
    
  sqlite3_stmt * query;
    
  char * SQL =
    "select note_id, bundleid, encoded_data from scheduled_notifications "
      "left join app_info using (app_id), notifications using (note_id);";
    
  result =
    sqlite3_prepare_v2(handle, SQL, -1, & query, NULL);
    
  bool done = (result != SQLITE_OK);
  
  NSMutableDictionary * notifications = [NSMutableDictionary dictionary];
  
  while(!done)
    {
    result = sqlite3_step(query);
  
    switch(result)
      {
      case SQLITE_ROW:
        [self 
          parseSPAMNotificationsRow: query notifications: notifications];
        break;
      case SQLITE_DONE:
        done = YES;
        break;
      default:
        done = YES;
        break;
      }
    }

  sqlite3_finalize(query);

  sqlite3_close(handle);
  
  return notifications;
  }

// Collect a notification.
- (void) parseSPAMNotificationsRow: (sqlite3_stmt *) query
  notifications: (NSMutableDictionary *) notifications
  {
  NSNumber * note_id = (NSNumber *)[self load: query column: 0];
  NSString * bundle_id = (NSString *)[self load: query column: 1];
  NSUserNotification * userNotification =
    (NSUserNotification *)[self load: query column: 2];
  
  if(note_id == nil)
    return;
    
  if([bundle_id length] == 0)
    return;
    
  if(userNotification == nil)
    return;
    
  if(![userNotification respondsToSelector: @selector(deliveryDate)])
    return;
    
  UserNotification * notification = 
    [[UserNotification alloc] initWithBundleID: bundle_id noteID: note_id];
  
  notification.notification = userNotification;
  
  NSMutableArray * appNotifications = 
    [notifications objectForKey: bundle_id];
    
  if(![NSArray isValid: appNotifications])
    {
    appNotifications = [NSMutableArray new];
    
    if([NSArray isValid: appNotifications])
      [notifications setObject: appNotifications forKey: bundle_id];
    
    [appNotifications release];
    }
  
  [appNotifications addObject: notification];
  
  [notification release];
  }

// Load a single column's data.
- (nullable NSObject *) load: (sqlite3_stmt *) query column: (int) index
  {
  int size = sqlite3_column_bytes(query, index);
  
  switch(sqlite3_column_type(query, index))
    {
    case SQLITE_INTEGER:
      return
        [NSNumber
          numberWithLongLong:
            sqlite3_column_int64(query, index)];
      
    case SQLITE_TEXT:
      return
        [[[NSString alloc]
          initWithBytes: sqlite3_column_text(query, index)
          length: size
          encoding: NSUTF8StringEncoding] autorelease];

    case SQLITE_BLOB:
      {
      NSData * value =
        [[NSData alloc]
          initWithBytes: sqlite3_column_blob(query, index)
          length: size];
        
      NSObject * object =
        [NSKeyedUnarchiver unarchiveObjectWithData: value];
      
      [value release];
      
      return object;
      }
      
    default:
      break;
    }
    
  return nil;
  }

// Collect orphan Safari extensions.
- (void) collectOrphanSafariExtensions
  {
  Safari * safari = [self.model safari];
  
  for(NSString * path in safari.extensions)
    {
    SafariExtension * extension = [safari.extensions objectForKey: path];
    
    if([SafariExtension isValid: extension])
      if(!extension.loaded)
        [[[self.model safari] orphanExtensions] addObject: extension];
    }
  }
  
// Print any cleanup items.
- (void) printCleanup
  {
  int count = 0;
  
  count = [self printOrphanLaunchdFiles];
  count = [self printOrphanSafariExtensions: count];
  
  if(count > 0)
    {
    NSString * message = ECLocalizedPluralString(count, @"orphan file");

    [self.result appendString: @"    "];
    [self.result
      appendString: message
      attributes:
        @{
          NSFontAttributeName : [[Utilities shared] boldFont],
          NSForegroundColorAttributeName : [[Utilities shared] red],
        }];

    NSAttributedString * removeLink = [self generateRemoveAdwareLink];

    if(removeLink)
      {
      [self.result appendAttributedString: removeLink];
      [self.result appendString: @"\n"];
      }
    
    [self.result appendCR];
    }
    
  [self printNotificationSPAM: count];
  }

- (int) printOrphanLaunchdFiles
  {
  int count = 0;
  
  for(LaunchdFile * launchdFile in [self.model launchd].orphanFiles)
    {
    if([self hideFile: launchdFile])
      continue;
      
    if(count++ == 0)
      [self.result appendAttributedString: [self buildTitle]];
      
    // Print the file.
    [self.result appendString: launchdFile.path];
    [self.result appendString: @" "];

    if(launchdFile.executable.length > 0)
      {
      [self.result appendString: @"\n        "];
      [self.result 
        appendString: [self cleanPath: launchdFile.executable]];
      }
    
    [self.result appendString: @"\n"];
    }
    
  return count;
  }
  
// Should this file be hidden?
- (BOOL) hideFile: (LaunchdFile *) file
  {
  if([file.adware isEqualToString: kAdwareExecutablePermissions])
    return YES;
    
  Launchd * launchd = [self.model launchd];
  
  NSDictionary * appleFile = [launchd.appleFiles objectForKey: file.path];
  
  if([NSDictionary isValid: appleFile])
    {
    NSString * expectedSignature = [appleFile objectForKey: kSignature];
    
    if([NSString isValid: expectedSignature])
      if([expectedSignature isEqualToString: kExecutableMissing])
        return [self.model ignoreKnownAppleFailures];
    }
    
  return NO;
  }

- (int) printOrphanSafariExtensions: (int) count
  {
  Safari * safari = [self.model safari];
  
  for(SafariExtension * extension in safari.orphanExtensions)
    {
    if(count++ == 0)
      [self.result appendAttributedString: [self buildTitle]];

    // Print the extension.
    [self.result appendString: @"    "];
    [self.result appendString: ECLocalizedString(@"Safari extension: ")];
    [self.result appendString: extension.displayName];
    [self.result appendString: @"\n"];
    }
        
  return count;
  }
  
- (void) printNotificationSPAM: (int) count
  {
  for(NSString * bundleID in [self.model notificationSPAMs])
    {
    if(count++ == 0)
      [self.result appendAttributedString: [self buildTitle]];
    else
      [self.result appendCR];
      
    NSDictionary * notifications = 
      [[self.model notificationSPAMs] objectForKey: bundleID];
      
    if([NSDictionary isValid: notifications])
      {
      NSString * message =
        ECLocalizedPluralString(notifications.count, @"SPAM notification");

      [self.result appendString: @"    "];
      
      [self.result
        appendString:
          [NSString stringWithFormat: @"%@ - %@", bundleID, message]
        attributes:
          @{
            NSForegroundColorAttributeName : [[Utilities shared] red],
            NSFontAttributeName : [[Utilities shared] boldFont]
          }];
      
      NSAttributedString * cleanupLink =
        [self generateRemoveNotificationSpamLink: bundleID];

      if(cleanupLink)
        [self.result appendAttributedString: cleanupLink];
        
      [self.result appendString: @"\n"];
      }
    }
  }
  
// Export cleanup items.
- (void) exportCleanup
  {
  [self exportOrphanLaunchdFiles];
  [self exportOrphanSafariExtensions];
  [self exportNotificationSPAM];
  }
  
// Export orphan launchd files.
- (void) exportOrphanLaunchdFiles
  {
  if([self.model launchd].orphanFiles.count == 0)
    return;
    
  bool started = false;
  
  for(LaunchdFile * launchdFile in [self.model launchd].orphanFiles)
    {
    if([self hideFile: launchdFile])
      continue;

    if(!started)
      {
      [self.xml startElement: @"launchdfiles"];
  
      started = true;
      }
      
    // Export the XML.
    [self.xml addFragment: launchdFile.xml];
    }
    
  if(started)
    [self.xml endElement: @"launchdfiles"];
  }
  
// Export orphan safari extensions.
- (void) exportOrphanSafariExtensions
  {
  Safari * safari = [self.model safari];
  
  if(safari.orphanExtensions.count == 0)
    return;
    
  [self.xml startElement: @"safariextensions"];

  for(SafariExtension * extension in safari.orphanExtensions)

    // Export the XML.
    [self.xml addFragment: extension.xml];

  [self.xml endElement: @"safariextensions"];
  }

// Export notification spam.
- (void) exportNotificationSPAM
  {
  if([[self.model notificationSPAMs] count] == 0)
    return;
    
  [self.xml startElement: @"notificationspam"];
  
  for(NSString * bundleID in [self.model notificationSPAMs])
    {
    [self.xml startElement: @"spammer"];
  
    [self.xml addElement: @"name" value: bundleID];
    
    NSArray * notifications = 
      [[self.model notificationSPAMs] objectForKey: bundleID];
      
    if([NSArray isValid: notifications])
      {
      [self.xml startElement: @"notifications"];
      
      for(UserNotification * notification in notifications)
        {
        [self.xml addElement: @"identifier" number: notification.noteID];
        [self.xml 
          addElement: @"text" value: notification.notification.title];
        }
        
      [self.xml endElement: @"notifications"];
      }
      
    [self.xml endElement: @"spammer"];
    }
    
  [self.xml endElement: @"notificationspam"];
  }

// Generate a "Clean up" link for orphan files.
- (NSAttributedString *) generateRemoveOrphanFilesLink: (NSString *) name
  {
  NSMutableAttributedString * urlString =
    [[NSMutableAttributedString alloc] initWithString: @""];
    
  [urlString appendString: @" "];
  
  [urlString
    appendString: ECLocalizedString(@"[Clean up]")
    attributes:
      @{
        NSFontAttributeName : [[Utilities shared] boldFont],
        NSForegroundColorAttributeName : [[Utilities shared] red],
        NSLinkAttributeName : @"etrecheck://cleanup/orphans"
      }];
    
  return [urlString autorelease];
  }

// Generate a "Clean up" link for notification SPAM.
- (NSAttributedString *) generateRemoveNotificationSpamLink:
  (NSString *) name
  {
  NSMutableAttributedString * urlString =
    [[NSMutableAttributedString alloc] initWithString: @""];
    
  [urlString appendString: @" "];
  
  [urlString
    appendString: ECLocalizedString(@"[Clean up]")
    attributes:
      @{
        NSFontAttributeName : [[Utilities shared] boldFont],
        NSForegroundColorAttributeName : [[Utilities shared] red],
        NSLinkAttributeName :
          [NSString
            stringWithFormat:
              @"etrecheck://cleanup/notificationspam/%@", name]
      }];
    
  return [urlString autorelease];
  }

@end
