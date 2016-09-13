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
  NSMutableDictionary * myAttributes;
  NSMutableString * myContents;
  BOOL myCDATARequired;
  BOOL myParent;
  BOOL myEmpty;
  BOOL mySingleLine;
  BOOL myStartTagEmitted;
  int myIndent;
  }

// The name of the element.
@property (retain) NSString * name;

// The element's attributes.
@property (retain) NSMutableDictionary * attributes;

// The element's (current) contents.
@property (retain) NSMutableString * contents;

// Do the current contents require a CDATA?
@property (assign) BOOL CDATARequired;

// Is this element a parent of another element?
@property (assign) BOOL parent;

// Is the current element empty?
@property (assign) BOOL empty;

// Is the current element a single-line element?
@property (assign) BOOL singleLine;

// Has the begin tag been emitted?
@property (assign) BOOL startTagEmitted;

// This element's indent level.
@property (assign) int indent;

// Constructor with name and indent.
- (instancetype) initWithName: (NSString *) name indent: (int) indent;

@end

@interface XMLBuilder : NSObject
  {
  NSMutableString * myDocument;
  int myIndent;
  BOOL myPretty;
  NSMutableArray * myElements;
  }

// The document content.
@property (retain) NSMutableString * document;

// The XML content.
@property (readonly) NSString * XML;

// The current indent level.
@property (assign) int indent;

// Should the output be pretty?
@property (assign) BOOL pretty;

// The stack of elements.
@property (retain) NSMutableArray * elements;

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
