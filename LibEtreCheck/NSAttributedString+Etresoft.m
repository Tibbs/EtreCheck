//
/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2012-2014. All rights reserved.
 **********************************************************************/

#import "NSAttributedString+Etresoft.h"

// Some handy NSString functions for attributed strings.
@implementation NSAttributedString (Etresoft)

- (NSAttributedString *) attributedStringByTrimmingCharactersInSet:
  (NSCharacterSet *)set
  {
  NSMutableAttributedString * newStr = [[self mutableCopy] autorelease];

  NSRange range = [[newStr string] rangeOfCharacterFromSet:set];

  while((range.length != 0) && (range.location == 0))
    {
    [newStr replaceCharactersInRange: range withString: @""];
    range = [[newStr string] rangeOfCharacterFromSet: set];
    }

  range =
    [[newStr string]
      rangeOfCharacterFromSet: set options: NSBackwardsSearch];

  while((range.length != 0) && (NSMaxRange(range) == [newStr length]))
    {
    [newStr replaceCharactersInRange: range withString: @""];
    
    range =
      [[newStr string]
        rangeOfCharacterFromSet: set options: NSBackwardsSearch];
    }

  return [[newStr copy] autorelease];
  }

- (NSAttributedString *) attributedStringByTrimmingWhitespace
  {
  return
    [self
      attributedStringByTrimmingCharactersInSet:
        [NSCharacterSet whitespaceAndNewlineCharacterSet]];
  }

@end
