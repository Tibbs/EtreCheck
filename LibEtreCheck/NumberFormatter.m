/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2013-2017. All rights reserved.
 **********************************************************************/

#import "NumberFormatter.h"

@implementation NumberFormatter

@synthesize formatter = myFormatter;

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
    myFormatter = [[NSNumberFormatter alloc] init];
    
    [myFormatter setNumberStyle: NSNumberFormatterNoStyle];
    }
  
  return self;
  }

// Convert a number to a string.
- (NSString *) convertToString: (NSNumber *) number
  {
  NSString * string = nil;
  
  if(number != nil)
    {
    @synchronized(self.formatter)
      {
      string = [self.formatter stringFromNumber: number];
      }
    }
  
  return string;
  }

// Convert a string to a number.
- (NSNumber *) convertFromString: (NSString *) string
  {
  NSNumber * number = nil;
  
  if(string.length > 0)
    {
    @synchronized(self.formatter)
      {
      number = [self.formatter numberFromString: string];
      }
    }
  
  return number;
  }

@end
