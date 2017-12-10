/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "NSMutableArray+Etresoft.h"

@implementation NSMutableArray (Etresoft)

// Is this a valid object?
+ (BOOL) isValid: (NSMutableArray *) array
  {
  if(array != nil)
    return [array respondsToSelector: @selector(insertObject:atIndex:)];
    
  return NO;
  }

@end
