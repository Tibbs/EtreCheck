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
#import "TTTLocalizedPluralString.h"
#import "LaunchdCollector.h"
#import <sqlite3.h>
#import <unistd.h>

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
  
  BOOL hasMissingExecutables = [self printMissingExecutables];
  
  [self printNotificationSPAM: !hasMissingExecutables];
  }

// Print any missing executables.
- (BOOL) printMissingExecutables
  {
  NSDictionary * orphanLaunchdFiles = [[Model model] orphanLaunchdFiles];
  
  if([orphanLaunchdFiles count] > 0)
    {
    [self.result appendAttributedString: [self buildTitle]];
    
    NSArray * sortedUnknownLaunchdFiles =
      [[orphanLaunchdFiles allKeys]
        sortedArrayUsingSelector: @selector(compare:)];
      
    [sortedUnknownLaunchdFiles
      enumerateObjectsUsingBlock:
        ^(id obj, NSUInteger idx, BOOL * stop)
          {
          [self.result
            appendString:
              [NSString
                stringWithFormat: @"    %@", [Utilities prettyPath: obj]]];

          NSDictionary * info = [orphanLaunchdFiles objectForKey: obj];
          
          NSString * signature = [info objectForKey: kSignature];
          
          [self.result
            appendString:
              [NSString
                stringWithFormat:
                  @"\n        %@\n",
                  [Utilities
                    formatExecutable: [info objectForKey: kCommand]]]];

          // Report a missing executable.
          if([signature isEqualToString: kExecutableMissing])
            {
            [self.result
              appendString:
                [NSString
                  stringWithFormat:
                    NSLocalizedString(
                      @"        Executable not found!\n", NULL)]
              attributes:
                @{
                  NSForegroundColorAttributeName : [[Utilities shared] red],
                  NSFontAttributeName : [[Utilities shared] boldFont]
                }];
            }
          }];
      
    NSString * message =
      TTTLocalizedPluralString(
        [orphanLaunchdFiles count], @"orphan file", NULL);

    [self.result appendString: @"    "];
    
    [self.result
      appendString: message
      attributes:
        @{
          NSForegroundColorAttributeName : [[Utilities shared] red],
          NSFontAttributeName : [[Utilities shared] boldFont]
        }];
    
    NSAttributedString * cleanupLink =
      [self generateRemoveOrphanFilesLink: @"files"];

    if(cleanupLink)
      {
      [self.result appendAttributedString: cleanupLink];
      [self.result appendString: @"\n"];
      }
    
    [self.result appendCR];
    
    [[Model model] setCleanupRequired: YES];
    
    return YES;
    }
    
  return NO;
  }

// Collection notification SPAM.
- (void) collectNotificationSPAM
  {
  int version = [[Model model] majorOSVersion];

  if(version < kMountainLion)
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
  
  if(result != SQLITE_OK)
    return;
    
  sqlite3_stmt * query;
    
  char * SQL =
    "select note_id, bundleid, encoded_data from scheduled_notifications "
      "left join app_info using (app_id), notifications using (note_id);";
    
  result =
    sqlite3_prepare_v2(handle, SQL, -1, & query, NULL);
    
  bool done = (result != SQLITE_OK);
  
  while(!done)
    {
    result = sqlite3_step(query);
  
    switch(result)
      {
      case SQLITE_ROW:
        [self collectionNotificationSPAMRow: query];
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
  }

// Collect a notification.
- (void) collectionNotificationSPAMRow: (sqlite3_stmt *) query
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
    
  NSDictionary * notification =
    [NSDictionary
      dictionaryWithObjectsAndKeys:
        note_id, kNotificationNoteID,
        bundle_id, kNotificationBundleID,
        userNotification, kNotificationUserNotification,
        nil];
    
  NSMutableDictionary * notifications =
    [[[Model model] notificationSPAMs] objectForKey: bundle_id];
    
  if(notifications == nil)
    {
    notifications = [NSMutableDictionary new];
    
    [[[Model model] notificationSPAMs]
      setObject: notifications forKey: bundle_id];
      
    [notifications release];
    }
    
  [notifications setObject: notification forKey: note_id];
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

// Print notification SPAM.
- (void) printNotificationSPAM: (BOOL) printTitle
  {
  for(NSString * spammer in [[Model model] notificationSPAMs])
    {
    NSMutableArray * notifications =
      [NSMutableArray
        arrayWithArray:
          [[[[Model model] notificationSPAMs] objectForKey: spammer] 
            allObjects]];
      
    NSUInteger count = [notifications count];
    
    if(count < 3)
      continue;
      
    [notifications
      sortUsingComparator:
        ^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2)
        {
        NSDictionary * notification1 = obj1;
        NSDictionary * notification2 = obj2;
        
        NSNumber * noteID1 =
          [notification1 objectForKey: kNotificationNoteID];
          
        NSNumber * noteID2 =
          [notification2 objectForKey: kNotificationNoteID];
        
        if(noteID2 == nil)
          return NSOrderedDescending;
          
        return [noteID1 compare: noteID2];
        }];
      
    NSInteger firstNoteID =
      [[[notifications firstObject]
        objectForKey: kNotificationNoteID] integerValue];
    
    NSInteger lastNoteID =
      [[[notifications lastObject]
        objectForKey: kNotificationNoteID] integerValue];
      
    if((lastNoteID - firstNoteID) == (count - 1))
      {
      if(printTitle)
        {
        [self.result appendAttributedString: [self buildTitle]];
        printTitle = NO;
        }
        
      NSString * message =
        TTTLocalizedPluralString(count, @"SPAM notification", NULL);

      [self.result appendString: @"    "];
      
      [self.result
        appendString:
          [NSString stringWithFormat: @"%@ - %@", spammer, message]
        attributes:
          @{
            NSForegroundColorAttributeName : [[Utilities shared] red],
            NSFontAttributeName : [[Utilities shared] boldFont]
          }];
      
      NSAttributedString * cleanupLink =
        [self generateRemoveNotificationSpamLink: spammer];

      if(cleanupLink)
        {
        [self.result appendAttributedString: cleanupLink];
        [self.result appendString: @"\n"];
        }
      
      [self.result appendCR];
      }
    }
  }

// Purge notification SPAM.
+ (BOOL) purgeNotificationSPAM: (NSArray *) note_ids
  {
  if([note_ids count] == 0)
    return NO;
    
  BOOL success = NO;
  
  char user_dir[1024];
  
  size_t size = confstr(_CS_DARWIN_USER_DIR, user_dir, 1024);
  
  if(size >= 1023)
    return NO;
  
  NSString * path =
    [[NSString stringWithUTF8String: user_dir]
      stringByAppendingPathComponent:
        @"com.apple.notificationcenter/db/db"];
  
  sqlite3 * handle = NULL;
  
  int result = sqlite3_open(path.fileSystemRepresentation, & handle);
  
  if(result == SQLITE_OK)
    {
    NSString * arguments = [note_ids componentsJoinedByString: @","];
    
    NSString * SQL =
      [NSString
        stringWithFormat:
          @"delete from notifications where note_id in (%@);", arguments];
    
    result = sqlite3_exec(handle, SQL.UTF8String, NULL, NULL, NULL);
    
    if(result == SQLITE_OK)
      success = YES;

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
    
  sqlite3_close(handle);
  
  return success;
  }

// Generate a "Clean up" link for orphan files.
- (NSAttributedString *) generateRemoveOrphanFilesLink: (NSString *) name
  {
  NSMutableAttributedString * urlString =
    [[NSMutableAttributedString alloc] initWithString: @""];
    
  [urlString appendString: @" "];
  
  [urlString
    appendString: NSLocalizedString(@"[Clean up]", NULL)
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
    appendString: NSLocalizedString(@"[Clean up]", NULL)
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
