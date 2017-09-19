/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

@interface NSObject (Etresoft)

// Read a property list.
+ (id) readPropertyList: (NSString *) path;
  
// Read a property list.
+ (id) readPropertyListData: (NSData *) data;

@end
