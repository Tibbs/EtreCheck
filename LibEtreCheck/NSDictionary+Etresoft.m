/***********************************************************************
 ** Etresoft, Inc.
 ** John Daniel
 ** Copyright (c) 2012-2017. All rights reserved.
 **********************************************************************/

#import "NSDictionary+Etresoft.h"
#import "NSObject+Etresoft.h"

@implementation NSDictionary (Etresoft)

// Read from a property list file or data and make sure it is a dictionary.
+ (NSDictionary *) readPropertyList: (NSString *) path
  {
  NSDictionary * dictionary = [NSObject readPropertyList: path];
  
  if([dictionary respondsToSelector: @selector(objectForKey:)])
    return dictionary;
    
  return nil;
  }

+ (NSDictionary *) readPropertyListData: (NSData *) data
  {
  NSDictionary * dictionary = [NSObject readPropertyListData: data];
  
  if([dictionary respondsToSelector: @selector(objectForKey:)])
    return dictionary;
    
  return nil;
  }

@end
