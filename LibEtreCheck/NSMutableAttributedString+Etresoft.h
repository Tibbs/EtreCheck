/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2012-2014. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

@interface NSMutableAttributedString (Etresoft)

// Append a carriage return. Hopefully this will be less of a newline
// than a newline and cause less spacing issues on ASC.
- (void) appendCR;

// Append a plain old string.
- (void) appendString: (NSString *) string;

// Append a plain old string with attributes.
- (void) appendString: (NSString *) string
  attributes: (NSDictionary *) attributes;

// Append RTF content.
- (void) appendRTFData: (NSData *) data;

@end
