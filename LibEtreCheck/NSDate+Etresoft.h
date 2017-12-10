/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2012. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

@interface NSDate (Etresoft)

- (BOOL) isEarlierThan: (NSDate *) anotherDate;
- (BOOL) isEqualToOrEarlierThan: (NSDate *) anotherDate;

- (BOOL) isLaterThan: (NSDate *) anotherDate;
- (BOOL) isEqualToOrLaterThan: (NSDate *) anotherDate;

// Get a calendar.
+ (NSCalendar *) calendar;

// Is this a valid object?
+ (BOOL) isValid: (NSDate *) date;

@end
