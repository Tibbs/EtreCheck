/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "PrintableItem.h"
#import "XMLBuilder.h"

// Any kind of item that can be printed in an EtreCheck report.
@implementation PrintableItem

// The modification date for this item.
@synthesize modificationDate = myModificationDate;

// The author name for this item.
@synthesize authorName = myAuthorName;

// The attributed string value.
@synthesize attributedStringValue = myAttributedStringValue;

// The XML value.
@dynamic xml;

// The attributed string value.
- (NSMutableAttributedString * ) attributedStringValue
  {
  if(myAttributedStringValue == nil)
    {
    myAttributedStringValue = [NSMutableAttributedString new];
    
    [self buildAttributedStringValue: myAttributedStringValue];
    }
    
  return myAttributedStringValue;
  }
  
// The XML value.
- (XMLBuilderElement * ) xml
  {
  if(myXML == nil)
    {
    myXML = [XMLBuilder new];

    [self buildXMLValue: myXML];
    }
    
  return [myXML root];
  }

// Destructor.
- (void) dealloc
  {
  self.modificationDate = nil;
  self.authorName = nil;
  
  [myAttributedStringValue release];
  [myXML release];
  
  [super dealloc];
  }

// Build the attributedString value.
- (void) buildAttributedStringValue: 
  (NSMutableAttributedString *) attributedString
  {
  }
  
// Build the XML value.
- (void) buildXMLValue: (XMLBuilder *) xml
  {
  }

@end
