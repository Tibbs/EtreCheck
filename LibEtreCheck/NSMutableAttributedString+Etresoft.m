/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2012-2014. All rights reserved.
 **********************************************************************/

#import "NSMutableAttributedString+Etresoft.h"

@implementation NSMutableAttributedString (Etresoft)

// Append a carriage return. Hopefully this will be less of a newline
// than a newline and cause less spacing issues on ASC.
- (void) appendCR
  {
  NSAttributedString * CR =
    [[NSAttributedString alloc]
      initWithHTML: [@"<BR />" dataUsingEncoding: NSUTF8StringEncoding]
      documentAttributes: nil];
    
  [self appendAttributedString: CR];
  
  [CR release];
  }

// Append a plain old string.
- (void) appendString: (NSString *) string
  {
  NSAttributedString * attributedString =
    [[NSAttributedString alloc] initWithString: string];
  
  [self appendAttributedString: attributedString];
  
  [attributedString release];
  }

// Append a plain old string with attributes.
- (void) appendString: (NSString *) string
  attributes: (NSDictionary *) attributes
  {
  NSAttributedString * attributedString =
    [[NSAttributedString alloc]
      initWithString: string attributes: attributes];
  
  [self appendAttributedString: attributedString];
  
  [attributedString release];
  }
  
// Append RTF content.
- (void) appendRTFData: (NSData *) data
  {
  if(!data)
    return;
    
  NSAttributedString * attributedString =
    [[NSAttributedString alloc] initWithRTF: data documentAttributes: NULL];
    
  [self appendAttributedString: attributedString];
  
  [attributedString release];
  }

@end
