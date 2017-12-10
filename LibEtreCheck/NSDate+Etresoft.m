/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2012. All rights reserved.
 **********************************************************************/

#import "NSDate+Etresoft.h"

@implementation NSDate (Etresoft)

- (BOOL) isEarlierThan: (NSDate *) anotherDate
  {
  if(!anotherDate)
    return NO;
    
  return [self compare: anotherDate] == NSOrderedAscending;
  }

- (BOOL) isEqualToOrEarlierThan: (NSDate *) anotherDate
  {
  if(!anotherDate)
    return NO;
  
  NSComparisonResult result = [self compare: anotherDate];
  
  if(result == NSOrderedAscending)
    return YES;
  
  if(result == NSOrderedSame)
    return YES;
  
  return NO;
  }

- (BOOL) isLaterThan: (NSDate *) anotherDate
  {
  if(!anotherDate)
    return YES;
  
  return [self compare: anotherDate] == NSOrderedDescending;
  }

- (BOOL) isEqualToOrLaterThan: (NSDate *) anotherDate
  {
  if(!anotherDate)
    return YES;
  
  NSComparisonResult result = [self compare: anotherDate];
  
  if(result == NSOrderedDescending)
    return YES;
  
  if(result == NSOrderedSame)
    return YES;
  
  return NO;
  }

// Get a calendar.
+ (NSCalendar *) calendar
  {
  static NSCalendar * calendar = nil;
  
  static dispatch_once_t onceToken;
  
  dispatch_once(
    & onceToken,
    ^{
      calendar =
        [[NSCalendar alloc]
          initWithCalendarIdentifier: NSGregorianCalendar];
    });
    
  return calendar;
  }

// Is this a valid object?
+ (BOOL) isValid: (NSDate *) date
  {
  if(date != nil)
    return [date respondsToSelector: @selector(isEqualToDate:)];
    
  return NO;
  }

@end
