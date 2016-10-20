/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2013. All rights reserved.
 **********************************************************************/

#import "NumberFormatter.h"

@implementation NumberFormatter

@synthesize formatter;

// Singleton accessor.
+ (NumberFormatter *) sharedNumberFormatter
  {
  static NumberFormatter * formatter = nil;
  
  if(!formatter)
    formatter = [[NumberFormatter alloc] init];
  
  return formatter;
  }

// Constructor.
- (id) init
  {
  if(self = [super init])
    {
    formatter = [[NSNumberFormatter alloc] init];
    
    [formatter setNumberStyle: NSNumberFormatterNoStyle];
    }
  
  return self;
  }

// Convert a number to a string.
- (NSString *) convertToString: (NSNumber *) number
  {
  NSString * string = nil;
  
  @synchronized(self.formatter)
    {
    string = [self.formatter stringFromNumber: number];
    }
  
  return string;
  }

// Convert a string to a number.
- (NSNumber *) convertFromString: (NSString *) string
  {
  NSNumber * number = nil;
  
  @synchronized(self.formatter)
    {
    number = [self.formatter numberFromString: string];
    }
  
  return number;
  }

@end
