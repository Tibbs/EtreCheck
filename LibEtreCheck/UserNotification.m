/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "UserNotification.h"

@implementation UserNotification

// The unique idenifier for each notification.
@synthesize noteID = myNoteID;

// The bundle ID for the notification's creating app.
@synthesize bundleID = myBundleID;

// The notification itself.
@synthesize notification = myNotification;

// Constructor.
- (nullable instancetype) initWithBundleID: (nonnull NSString *) bundleID
  noteID: (nonnull NSNumber *) noteID
  {
  self = [super init];
  
  if(self != nil)
    {
    myBundleID = [bundleID retain];
    myNoteID = [noteID retain];
    }
    
  return self;
  }
  
// Destructor.
- (void) dealloc
  {
  [myNoteID release];
  [myBundleID release];
  [myNotification release];
  
  [super dealloc];
  }
  
@end
