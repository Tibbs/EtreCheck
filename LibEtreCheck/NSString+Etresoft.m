/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2012-2017. All rights reserved.
 **********************************************************************/

#import "NSString+Etresoft.h"

@implementation NSString (Etresoft)

// Return a UUID.
+ (nullable NSString *) UUID
  {
  CFUUIDRef uuid = CFUUIDCreate(NULL);

  if(uuid == nil)
    return nil;
    
  NSString * result = (NSString *)CFUUIDCreateString(NULL, uuid);

  CFRelease(uuid);
    
  return [result autorelease];
  }
  
@end
