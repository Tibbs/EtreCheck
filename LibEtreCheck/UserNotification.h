/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

@interface UserNotification : NSObject
  {
  // The unique idenifier for each notification.
  NSNumber * myNoteID;
  
  // The bundle ID for the notification's creating app.
  NSString * myBundleID;
  
  // The notification itself.
  NSUserNotification * myNotification;
  }
  
// The unique idenifier for each notification.
@property (retain, nonnull) NSNumber * noteID;

// The bundle ID for the notification's creating app.
@property (retain, nonnull) NSString * bundleID;

// The notification itself.
@property (retain, nonnull) NSUserNotification * notification;

// Constructor.
- (nullable instancetype) initWithBundleID: (nonnull NSString *) bundleID
  noteID: (nonnull NSNumber *) noteID;
  
@end
