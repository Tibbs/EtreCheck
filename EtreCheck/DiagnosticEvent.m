/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "DiagnosticEvent.h"

// Try to extract events from log files and various types of system reports.
@implementation DiagnosticEvent

@synthesize type = myType;
@synthesize date = myDate;
@synthesize name = myName;
@synthesize details = myDetails;
@synthesize file = myFile;
@synthesize safefile = mySafeFile;
@synthesize path = myPath;
@synthesize identifier = myIdentifier;
@synthesize information = myInformation;

// Destructor.
- (void) dealloc
  {
  [myDate release];
  [myName release];
  [myDetails release];
  [mySafeFile release];
  [myFile release];
  [myPath release];
  [myIdentifier release];
  [myInformation release];
  
  [super dealloc];
  }

@end
