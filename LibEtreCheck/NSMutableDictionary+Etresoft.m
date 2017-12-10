/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "NSMutableDictionary+Etresoft.h"

@implementation NSMutableDictionary (Etresoft)

// Is this a valid object?
+ (BOOL) isValid: (NSMutableDictionary *) dictionary
  {
  if(dictionary != nil)
    return [dictionary respondsToSelector: @selector(setObject:forKey:)];
    
  return NO;
  }

@end
