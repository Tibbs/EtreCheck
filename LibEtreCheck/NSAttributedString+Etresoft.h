/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2012-2014. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

// Some handy NSString functions for attributed strings.
@interface NSAttributedString (Etresoft)

- (NSAttributedString *) attributedStringByTrimmingCharactersInSet:
  (NSCharacterSet *)set;

- (NSAttributedString *) attributedStringByTrimmingWhitespace;

@end
