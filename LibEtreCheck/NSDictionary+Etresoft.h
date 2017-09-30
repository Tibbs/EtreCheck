/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2012-2014. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

@interface NSDictionary (Etresoft)

// Read from a property list file or data and make sure it is a dictionary.
+ (NSDictionary *) readPropertyList: (NSString *) path;
+ (NSDictionary *) readPropertyListData: (NSData *) data;

@end
