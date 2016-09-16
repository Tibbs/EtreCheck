/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2015. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

@interface XMLException : NSException

@end

// Encapsulate each element.
@interface XMLElement : NSObject
  {
  NSString * myName;
  XMLElement * myParent;
  NSMutableDictionary * myAttributes;
  BOOL mySingleLine;
  BOOL myCDATARequired;
  NSMutableArray * myChildren;
  NSMutableArray * myOpenChildren;
  }

// The name of the element.
@property (retain) NSString * name;

// The element's parent.
@property (assign) XMLElement * parent;

// The element's attributes.
@property (retain) NSMutableDictionary * attributes;

// Are the contents of this element a single line string?
@property (assign) BOOL singleLine;

// Do the current contents require a CDATA?
@property (assign) BOOL CDATARequired;

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
  }

// The document root.
@property (retain) XMLElement * root;

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

// Add a string to the current element's contents.
- (void) addString: (NSString *) string;

// Add a CDATA string.
- (void) addCDATA: (NSString *) cdata;
  
// Finish the current element.
- (void) endElement: (NSString *) name;
  
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
