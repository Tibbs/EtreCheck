/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2015-2017. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

// A value that can represent itself as XML.
@protocol AttributedStringValue

// Build the attributedString value.
- (void) buildAttributedStringValue: 
  (nonnull NSMutableAttributedString *) attributedString;

// The attributed string value.
@property (retain, nullable) 
  NSMutableAttributedString * attributedStringValue;

@end
