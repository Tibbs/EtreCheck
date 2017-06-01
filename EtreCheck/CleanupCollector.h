/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "Collector.h"

#define kNotificationNoteID @"noteid"
#define kNotificationBundleID @"bundleid"
#define kNotificationUserNotification @"notification"

// Collect information about clean up opportunities.
@interface CleanupCollector : Collector

// Purge notification SPAM.
+ (BOOL) purgeNotificationSPAM: (NSArray *) note_ids;

@end
