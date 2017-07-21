/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2015. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

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

// Start a new element.
- (void) startElement: (NSString *) name;

// Add a null attribute.
- (void) addNullAttribute: (NSString *) name;

// Add a string attribute.
- (void) addStringAttribute: (NSString *) name value: (NSString *) value;

// Add an NSObject attribute.
- (void) addAttribute: (NSString *) name value: (NSObject *) value;

// Add a boolen attribute.
- (void) addBooleanAttribute: (NSString *) name value: (BOOL) value;

// Add an integer attribute.
- (void) addIntegerAttribute: (NSString *) name value: (NSInteger) value;

// Add an unsigned integer attribute.
- (void) addUnsignedIntegerAttribute: (NSString *) name 
  value: (NSUInteger) value;

// Add a long long attribute.
- (void) addLongLongAttribute: (NSString *) name value: (long long) value;

// Add a double attribute.
- (void) addDoubleAttribute: (NSString *) name value: (double) value;

// Add a date attribute.
- (void) addDateAttribute: (NSString *) name value: (NSDate *) value;

// Add a URL attribute.
- (void) addURLAttribute: (NSString *) name value: (NSURL *) value;

// Add a string to the current element's contents.
- (void) addString: (NSString *) string;

// Add a CDATA string.
- (void) addCDATA: (NSString *) string;

// Add a null element.
- (void) addNullElement: (NSString *) name;

// Add a string element.
- (void) addStringElement: (NSString *) name value: (NSString *) value;

// Add an NSObject element.
- (void) addElement: (NSString *) name value: (NSObject *) value;

// Add a boolen element.
- (void) addBooleanElement: (NSString *) name value: (BOOL) value;

// Add an integer element.
- (void) addIntegerElement: (NSString *) name value: (NSInteger) value;

// Add an unsigned integer element.
- (void) addUnsignedIntegerElement: (NSString *) name 
  value: (NSUInteger) value;

// Add a long long element.
- (void) addLongLongElement: (NSString *) name value: (long long) value;

// Add a double element.
- (void) addDoubleElement: (NSString *) name value: (double) value;

// Add a date element.
- (void) addDateElement: (NSString *) name value: (NSDate *) value;

// Add a URL element.
- (void) addURLElement: (NSString *) name value: (NSURL *) value;

// Finish the specified element, finishing any open elements if necessary.
- (void) endElement: (NSString *) name;

// Finish the specified element if it is open.
- (void) endOpenElement: (NSString *) name;

@end
