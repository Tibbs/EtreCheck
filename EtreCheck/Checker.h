/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

// Perform the check.
@interface Checker : NSObject
  {
  NSMutableDictionary * myResults;
  NSMutableDictionary * myCompleted;
  dispatch_queue_t myQueue;
  }

@property (retain) NSMutableDictionary * results;
@property (retain) NSMutableDictionary * completed;
@property dispatch_queue_t queue;

// Do the check and return the report.
- (NSAttributedString *) check;

// Collect output.
- (void) collectOutput;

@end
