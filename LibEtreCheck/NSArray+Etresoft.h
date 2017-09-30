/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2012-2014. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

@interface NSArray (Etresoft)

// Read from a property list file or data and make sure it is an array.
+ (NSArray *) readPropertyList: (NSString *) path;
+ (NSArray *) readPropertyListData: (NSData *) data;

@end
