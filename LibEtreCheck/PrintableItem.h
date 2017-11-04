/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>
#import "XMLBuilder.h"
#import "XMLValue.h"
#import "AttributedStringValue.h"

@class XMLBuilderElement;

// Any kind of item that can be printed in an EtreCheck report.
@interface PrintableItem : NSObject <XMLValue, AttributedStringValue>
  {
  // The modification date for this item.
  NSDate * myModificationDate;
  
  // The author name for this item.
  NSString * myAuthorName;
  
  // The attributed string value.
  NSMutableAttributedString * myAttributedStringValue;
  
  // The XML builder.
  XMLBuilder * myXMLBuilder;
  }
  
// The modification date for this item.
@property (retain, nullable) NSDate * modificationDate;

// The author name for this item.
@property (retain, nullable) NSString * authorName;

// The XML builder.
@property (readonly, nonnull) XMLBuilder * xmlBuilder;

@end
