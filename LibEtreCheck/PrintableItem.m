/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "PrintableItem.h"
#import "XMLBuilder.h"
#import "NSMutableAttributedString+Etresoft.h"

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

// The XML builder.
@synthesize xmlBuilder = myXMLBuilder;

// The attributed string indent value.
@synthesize indent = myIndent;

// The attributed string value.
- (NSMutableAttributedString * ) attributedStringValue
  {
  if(myAttributedStringValue == nil)
    {
    myAttributedStringValue = [NSMutableAttributedString new];
    
    for(int i = 0; i < self.indent; ++i)
      [myAttributedStringValue appendString: @"    "];
      
    [self buildAttributedStringValue: myAttributedStringValue];
    }
    
  return myAttributedStringValue;
  }

// Set the attributed string value.
- (void) setAttributedStringValue: 
  (NSMutableAttributedString *) attributedStringValue
  {
  if(myAttributedStringValue != attributedStringValue)
    {
    [self willChangeValueForKey: @""];
    
    [myAttributedStringValue release];
    
    myAttributedStringValue = [attributedStringValue retain];
    
    [self didChangeValueForKey: @""];
    }
  }
    
// The XML value.
- (XMLBuilderElement * ) xml
  {
  if(myXMLBuilder == nil)    
    myXMLBuilder = [XMLBuilder new];

  if([[[self.xmlBuilder root] children] count] == 0)
    [self buildXMLValue: myXMLBuilder];
    
  return [self.xmlBuilder root];
  }

// Destructor.
- (void) dealloc
  {
  self.modificationDate = nil;
  self.authorName = nil;
  
  [myAttributedStringValue release];
  [myXMLBuilder release];
  
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
