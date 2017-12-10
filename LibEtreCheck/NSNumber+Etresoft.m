/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "NSNumber+Etresoft.h"

@implementation NSNumber (Etresoft)

// Is this a valid object?
+ (BOOL) isValid: (NSNumber *) number
  {
  if(number != nil)
    return [number respondsToSelector: @selector(isEqualToNumber:)];
    
  return NO;
  }
  
@end
