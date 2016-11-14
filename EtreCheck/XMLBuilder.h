/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2015. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

// XML has to be precise. We'll need exceptions.
@interface XMLException : NSException

@end

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
  BOOL myLeadingWhitespace;
  BOOL myTrailingWhitespace;
  BOOL myMultiLine;
  }

// The node's text.
@property (assign) NSString * text;
@property (assign) BOOL leadingWhitespace;
@property (assign) BOOL trailingWhitespace;
@property (assign) BOOL multiLine;

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

// A root element.
@interface XMLRootElement : XMLElement

@end

@interface XMLBuilder : NSObject
  {
  NSMutableString * myDocument;
  XMLElement * myRoot;
  NSDateFormatter * myDateFormatter;
  }

// The document root.
@property (retain) XMLElement * root;

// The date formatter.
@property (readonly) NSDateFormatter * dateFormatter;

// The XML content.
@property (readonly) NSString * XML;

// Pop the stack and return what we have.
- (NSString *) XML;
  
// Start a new element.
- (void) startElement: (NSString *) name;
  
// Add an attribute to the current element.
- (void) addAttribute: (NSString *) name value: (NSString *) value;

// Add an attribute to the current element.
- (void) addAttribute: (NSString *) name number: (NSNumber *) value;
  
// Add an attribute to the current element.
- (void) addAttribute: (NSString *) name date: (NSDate *) date;

// Add an element and value with a conveneience function.
- (void) addAttribute: (NSString *) name boolValue: (BOOL) value;

// Add an element and value with a conveneience function.
- (void) addAttribute: (NSString *) name intValue: (int) value;

// Add an element and value with a conveneience function.
- (void) addAttribute: (NSString *) name longValue: (long) value;

// Add an element and value with a conveneience function.
- (void) addAttribute: (NSString *) name longlongValue: (long long) value;

// Add an element and value with a conveneience function.
- (void) addAttribute: (NSString *) name
  unsignedIntValue: (unsigned int) value;

// Add an element and value with a conveneience function.
- (void) addAttribute: (NSString *) name
  unsignedLongValue: (unsigned long) value;

// Add an element and value with a conveneience function.
- (void) addAttribute: (NSString *) name
  unsignedLonglongValue: (unsigned long long) value;

// Add an element and value with a conveneience function.
- (void) addAttribute: (NSString *) name integerValue: (NSInteger) value;

// Add an element and value with a conveneience function.
- (void) addAttribute: (NSString *) name
  unsignedIntegerValue: (NSUInteger) value;

// Add an element and value with a conveneience function.
- (void) addAttribute: (NSString *) name float: (float) value;

// Add an element and value with a conveneience function.
- (void) addAttribute: (NSString *) name doubleValue: (double) value;

// Add an element and value with a conveneience function.
- (void) addAttribute: (NSString *) name UTF8StringValue: (char *) value;

// Add a boolean to the current element's contents.
- (void) addBool: (BOOL) value;

// Add a string to the current element's contents.
- (void) addString: (NSString *) string;

// Finish the current element.
- (void) endElement: (NSString *) name;
  
// Add an empty element.
- (void) addElement: (NSString *) name;

// Add an element and value with a conveneience function.
- (void) addElement: (NSString *) name value: (NSString *) value;

// Add an element and value with a conveneience function.
- (void) addElement: (NSString *) name number: (NSNumber *) value;

// Add an element and value with a conveneience function.
- (void) addElement: (NSString *) name date: (NSDate *) value;

// Add an element and value with a conveneience function.
- (void) addElement: (NSString *) name boolValue: (BOOL) value;

// Add an element and value with a conveneience function.
- (void) addElement: (NSString *) name intValue: (int) value;

// Add an element and value with a conveneience function.
- (void) addElement: (NSString *) name longValue: (long) value;

// Add an element and value with a conveneience function.
- (void) addElement: (NSString *) name longlongValue: (long long) value;

// Add an element and value with a conveneience function.
- (void) addElement: (NSString *) name
  unsignedIntValue: (unsigned int) value;

// Add an element and value with a conveneience function.
- (void) addElement: (NSString *) name
  unsignedLongValue: (unsigned long) value;

// Add an element and value with a conveneience function.
- (void) addElement: (NSString *) name
  unsignedLonglongValue: (unsigned long long) value;

// Add an element and value with a conveneience function.
- (void) addElement: (NSString *) name integerValue: (NSInteger) value;

// Add an element and value with a conveneience function.
- (void) addElement: (NSString *) name
  unsignedIntegerValue: (NSUInteger) value;

// Add an element and value with a conveneience function.
- (void) addElement: (NSString *) name float: (float) value;

// Add an element and value with a conveneience function.
- (void) addElement: (NSString *) name doubleValue: (double) value;

// Add an element and value with a conveneience function.
- (void) addElement: (NSString *) name UTF8StringValue: (char *) value;

@end
