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
  
  if([NSArray isValid: array])
    return array;
    
  return nil;
  }

+ (NSArray *) readPropertyListData: (NSData *) data
  {
  NSArray * array = [NSObject readPropertyListData: data];
  
  if([NSArray isValid: array])
    return array;
    
  return nil;
  }

// Is this a valid object?
+ (BOOL) isValid: (NSArray *) array
  {
  if(array != nil)
    return [array respondsToSelector: @selector(objectAtIndex:)];
    
  return NO;
  }

// Return the first 10 values at most.
- (NSArray *) head
  {
  if(self.count > 10)
    return [self subarrayWithRange: NSMakeRange(0, 10)];
    
  return self;
  }
  
@end
