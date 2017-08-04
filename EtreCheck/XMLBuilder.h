/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2015-2017. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

@class XMLElement;

// An XML node.
@interface XMLNode : NSObject
  {
  XMLElement * myParent;
  }

// The node's parent.
@property (assign) XMLElement * parent;

@end

// An XML text node.
@interface XMLTextNode : XMLNode
  {
  NSString * myText;
  BOOL myIsCDATA;
  }

// The node's text.
@property (retain) NSString * text;
@property (assign) BOOL isCDATA;

// Constructor.
- (instancetype) initWithText: (NSString *) text;

@end

// Encapsulate each element.
@interface XMLElement : XMLNode
  {
  NSString * myName;
  NSMutableDictionary * myAttributes;
  NSMutableArray * myChildren;
  NSMutableArray * myOpenChildren;
  }

// The name of the element.
@property (retain) NSString * name;

// The element's attributes.
@property (retain) NSMutableDictionary * attributes;

// The stack of closed children.
@property (retain) NSMutableArray * children;

// The stack of open children.
@property (retain) NSMutableArray * openChildren;

// Constructor with name and indent.
- (instancetype) initWithName: (NSString *) name;

@end

@interface XMLBuilder : NSObject
  {
  NSMutableString * myDocument;
  XMLElement * myRoot;
  NSString * myDateFormat;
  NSString * myDayFormat;
  NSDateFormatter * myDateFormatter;
  NSDateFormatter * myDayFormatter;
  BOOL myValid;
  }

// The document root.
@property (retain) XMLElement * root;

// The date formatters.
@property (readonly) NSString * dateFormat;
@property (readonly) NSString * dayFormat;
@property (readonly) NSDateFormatter * dateFormatter;
@property (readonly) NSDateFormatter * dayFormatter;

// The XML content.
@property (readonly) NSString * XML;

// Is the XML valid?
@property (assign) BOOL valid;

// Pop the stack and return what we have.
- (NSString *) XML;
  
// Start a new element.
- (void) startElement: (NSString *) name;
  
// Add a null attribute.
- (void) addAttribute: (NSString *) name;

// Add an attribute to the current element.
- (void) addAttribute: (NSString *) name value: (NSString *) value;

// Add an attribute to the current element.
- (void) addAttribute: (NSString *) name number: (NSNumber *) value;
  
// Add an attribute to the current element.
- (void) addAttribute: (NSString *) name date: (NSDate *) date;

// Add an element and value with a convenience function.
- (void) addAttribute: (NSString *) name boolValue: (BOOL) value;

// Add an element and value with a convenience function.
- (void) addAttribute: (NSString *) name intValue: (int) value;

// Add an element and value with a convenience function.
- (void) addAttribute: (NSString *) name longValue: (long) value;

// Add an element and value with a convenience function.
- (void) addAttribute: (NSString *) name longlongValue: (long long) value;

// Add an element and value with a convenience function.
- (void) addAttribute: (NSString *) name
  unsignedIntValue: (unsigned int) value;

// Add an element and value with a convenience function.
- (void) addAttribute: (NSString *) name
  unsignedLongValue: (unsigned long) value;

// Add an element and value with a convenience function.
- (void) addAttribute: (NSString *) name
  unsignedLonglongValue: (unsigned long long) value;

// Add an element and value with a convenience function.
- (void) addAttribute: (NSString *) name integerValue: (NSInteger) value;

// Add an element and value with a convenience function.
- (void) addAttribute: (NSString *) name
  unsignedIntegerValue: (NSUInteger) value;

// Add an element and value with a convenience function.
- (void) addAttribute: (NSString *) name float: (float) value;

// Add an element and value with a convenience function.
- (void) addAttribute: (NSString *) name doubleValue: (double) value;

// Add an element and value with a convenience function.
- (void) addAttribute: (NSString *) name UTF8StringValue: (char *) value;

// Add a boolean to the current element's contents.
- (void) addBool: (BOOL) value;

// Add a string to the current element's contents.
- (void) addString: (NSString *) string;

// Add a CDATA string to the current element's contents.
- (void) addCDATA: (NSString *) string;

// Finish the current element.
- (void) endElement: (NSString *) name;
  
// Add an empty element with attributes.
- (void) addElement: (NSString *) name 
  attributes: (NSDictionary *) attributes;

// Add an empty element.
- (void) addElement: (NSString *) name;

// Add an element, value, and attributes with a convenience function.
- (void) addElement: (NSString *) name 
  value: (NSString *) value attributes: (NSDictionary *) attributes;

// Add an element and value with a convenience function.
- (void) addElement: (NSString *) name value: (NSString *) value;

// Add an element and value with a convenience function. Parse units out
// of the value and store as a number.
- (void) addElement: (NSString *) name valueWithUnits: (NSString *) value;

// Add an element and value with a convenience function. 
- (void) addElement: (NSString *) name 
  valueAsCDATA: (NSString *) value attributes: (NSDictionary *) attributes;
- (void) addElement: (NSString *) name valueAsCDATA: (NSString *) value;

// Add an element, value, and attributes with a convenience function.
- (void) addElement: (NSString *) name 
  number: (NSNumber *) value attributes: (NSDictionary *) attributes;

// Add an element and value with a convenience function.
- (void) addElement: (NSString *) name number: (NSNumber *) value;

// Add an element and value with a convenience function.
- (void) addElement: (NSString *) name date: (NSDate *) value;
- (void) addElement: (NSString *) name day: (NSDate *) date;

// Add an element and value with a convenience function.
- (void) addElement: (NSString *) name url: (NSURL *) value;

// Add an element and value with a convenience function.
- (void) addElement: (NSString *) name boolValue: (BOOL) value;

// Add an element, value, and attributes with a convenience function.
- (void) addElement: (NSString *) name 
  intValue: (int) value attributes: (NSDictionary *) attributes;

// Add an element and value with a convenience function.
- (void) addElement: (NSString *) name intValue: (int) value;

// Add an element, value, and attributes with a convenience function.
- (void) addElement: (NSString *) name 
  longValue: (long) value attributes: (NSDictionary *) attributes;

// Add an element and value with a convenience function.
- (void) addElement: (NSString *) name longValue: (long) value;

// Add an element, value, and attributes with a convenience function.
- (void) addElement: (NSString *) name 
  longlongValue: (long long) value attributes: (NSDictionary *) attributes;

// Add an element and value with a convenience function.
- (void) addElement: (NSString *) name longlongValue: (long long) value;

// Add an element, value, and attributes with a convenience function.
- (void) addElement: (NSString *) name
  unsignedIntValue: (unsigned int) value 
  attributes: (NSDictionary *) attributes;

// Add an element and value with a convenience function.
- (void) addElement: (NSString *) name
  unsignedIntValue: (unsigned int) value;

// Add an element, value, and attributes with a convenience function.
- (void) addElement: (NSString *) name
  unsignedLongValue: (unsigned long) value 
  attributes: (NSDictionary *) attributes;

// Add an element and value with a convenience function.
- (void) addElement: (NSString *) name
  unsignedLongValue: (unsigned long) value;

// Add an element, value, and attributes with a convenience function.
- (void) addElement: (NSString *) name
  unsignedLongLongValue: (unsigned long long) value 
  attributes: (NSDictionary *) attributes;

// Add an element and value with a convenience function.
- (void) addElement: (NSString *) name
  unsignedLongLongValue: (unsigned long long) value;

// Add an element, value, and attributes with a convenience function.
- (void) addElement: (NSString *) name 
  integerValue: (NSInteger) value attributes: (NSDictionary *) attributes;

// Add an element and value with a convenience function.
- (void) addElement: (NSString *) name integerValue: (NSInteger) value;

// Add an element, value, and attributes with a convenience function.
- (void) addElement: (NSString *) name
  unsignedIntegerValue: (NSUInteger) value 
  attributes: (NSDictionary *) attributes;

// Add an element and value with a convenience function.
- (void) addElement: (NSString *) name
  unsignedIntegerValue: (NSUInteger) value;

// Add an element, value, and attributes with a convenience function.
- (void) addElement: (NSString *) name 
  floatValue: (float) value attributes: (NSDictionary *) attributes;

// Add an element and value with a convenience function.
- (void) addElement: (NSString *) name floatValue: (float) value;

// Add an element, value, and attributes with a convenience function.
- (void) addElement: (NSString *) name 
  doubleValue: (double) value attributes: (NSDictionary *) attributes;

// Add an element and value with a convenience function.
- (void) addElement: (NSString *) name doubleValue: (double) value;

// Add an element and value with a convenience function.
- (void) addElement: (NSString *) name UTF8StringValue: (char *) value;

// Add a fragment from another XMLBuilder.
- (void) addFragment: (XMLElement *) xml;

@end
