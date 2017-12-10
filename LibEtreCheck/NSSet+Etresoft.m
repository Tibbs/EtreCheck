/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "NSSet+Etresoft.h"

@implementation NSSet (Etresoft)

// Is this a valid object?
+ (BOOL) isValid: (NSSet *) set
  {
  if(set != nil)
    return [set respondsToSelector: @selector(setByAddingObject:)];
    
  return NO;
  }

@end
