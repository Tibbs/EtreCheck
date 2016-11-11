/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2013. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

@interface NumberFormatter : NSObject
  {
  NSNumberFormatter * myFormatter;
  }

@property (readonly) NSNumberFormatter * formatter;

// Singleton accessor.
+ (NumberFormatter *) sharedNumberFormatter;

// Convert a number to a string.
- (NSString *) convertToString: (NSNumber *) number;

// Convert a string to a number.
- (NSNumber *) convertFromString: (NSString *) string;

@end
