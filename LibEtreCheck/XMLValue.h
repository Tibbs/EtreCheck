/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2015-2017. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

@class XMLBuilder;
@class XMLBuilderElement;

// A value that can represent itself as XML.
@protocol XMLValue

// Build the XML value.
- (void) buildXMLValue: (XMLBuilder *) xml;

// The XML value.
@property (readonly) XMLBuilderElement * xml;

@end
