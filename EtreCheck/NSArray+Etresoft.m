/***********************************************************************
 ** Etresoft, Inc.
 ** John Daniel
 ** Copyright (c) 2012-2017. All rights reserved.
 **********************************************************************/

#import "NSArray+Etresoft.h"
#import "NSObject+Etresoft.h"

@implementation NSArray (Etresoft)

// Read from a property list file or data and make sure it is an array.
+ (NSArray *) readPropertyList: (NSString *) path
  {
  NSArray * array = [NSObject readPropertyList: path];
  
  if([array respondsToSelector: @selector(objectAtIndex:)])
    return array;
    
  return nil;
  }

+ (NSArray *) readPropertyListData: (NSData *) data
  {
  NSArray * array = [NSObject readPropertyListData: data];
  
  if([array respondsToSelector: @selector(objectAtIndex:)])
    return array;
    
  return nil;
  }

@end
