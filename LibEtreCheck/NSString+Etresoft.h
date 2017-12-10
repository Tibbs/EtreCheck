/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2012-2017. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

@interface NSString (Etresoft)

// Return a UUID.
+ (nullable NSString *) UUID;

// Remove quotes, if present, from a string.
@property (readonly, nonnull) NSString * stringByRemovingQuotes;

// Remove leading and trailing whitespace.
@property (readonly, nonnull) NSString * trim;

// Is this a valid object?
+ (BOOL) isValid: (nullable NSString *) string;

@end
