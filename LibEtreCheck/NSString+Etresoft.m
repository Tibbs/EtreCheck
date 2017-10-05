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
  
// Remove quotes, if present, from a string.
- (nonnull NSString *) stringByRemovingQuotes
  {
  NSRange firstQuote = [self rangeOfString: @"\""];
  
  if(firstQuote.location == 0)
    {
    NSRange lastQuote =
      [self rangeOfString: @"\"" options: NSBackwardsSearch];
      
    if(firstQuote.location != lastQuote.location)
      if(lastQuote.location == ([self length] - 1))
        return
          [self substringWithRange: NSMakeRange(1, lastQuote.location - 1)];
    }
    
  return [[self copy] autorelease];
  }

@end
