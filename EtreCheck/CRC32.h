/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2013. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

@interface CRC32 : NSObject
  {
  uint32_t myValue;
  }

@property (readonly, assign) uint32_t value;

// Add more data.
- (void) addData: (NSData *) data;
- (void) addBytes: (const void *) bytes size: (NSUInteger) size;

@end
