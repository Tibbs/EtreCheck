/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2012. All rights reserved.
 **********************************************************************/

#import "ByteCountFormatter.h"
#import "LocalizedString.h"

@implementation ByteCountFormatter

@synthesize k1000 = myK1000;

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    myK1000 = 1000.0;
    
  return self;
  }

// Convert a byte count to a string.
- (NSString *) stringFromByteCount: (unsigned long long) byteCount
  {
  NSArray * unitValues =
    [ECLocalizedString(@"B KB MB GB TB") componentsSeparatedByString: @" "];
    
  int precisionValues[] = { 0, 0, 0, 2, 2};
  NSUInteger unitsIndex = 0;
  
  NSString * displayMem = @"?";
  
  double value = byteCount;
  
  while(YES)
    {
    if(value < self.k1000)
      {
      int precision = 0;
      NSString * units = @"";
      
      if(unitsIndex < 5)
        {
        precision = precisionValues[unitsIndex];
        units = [unitValues objectAtIndex: unitsIndex];
        }
        
      displayMem =
        [NSString
          stringWithFormat: @"%.*lf %@", precision, value, units];
        
      break;
      }
      
    ++unitsIndex;
    
    value /= self.k1000;
    }
    
  return displayMem;
  }

@end
