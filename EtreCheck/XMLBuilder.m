/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2015-2017. All rights reserved.
 **********************************************************************/

#import "XMLBuilder.h"
#import "Utilities.h"

// Encapsulate each element.
@implementation XMLElement

@synthesize name = myName;
@synthesize attributes = myAttributes;
@synthesize contents = myContents;
@synthesize CDATARequired = myCDATARequired;
@synthesize parent = myParent;
@synthesize empty = myEmpty;
@synthesize singleLine = mySingleLine;
@synthesize startTagEmitted = myStartTagEmitted;
@synthesize indent = myIndent;

// Constructor with name and indent.
- (instancetype) initWithName: (NSString *) name indent: (int) indent
  {
  self = [super init];
  
  if(self != nil)
    {
    myName = name;
    myIndent = indent;
    myContents = [NSMutableString new];
    myAttributes = [NSMutableDictionary new];
    }
    
  return self;
  }

// Destructor.
- (void) dealloc
  {
  [myAttributes release];
  [myContents release];
  
  [super dealloc];
  }

@end

// A class for building an XML document.
@implementation XMLBuilder

@synthesize document = myDocument;
@synthesize XML = myXML;
@synthesize indent = myIndent;
@synthesize pretty = myPretty;
@synthesize elements = myElements;

// Pop the stack and return what we have.
- (NSString *) XML
  {
  XMLElement * topElement = [self.elements lastObject];
  
  while(topElement != nil)
    [self endElement: topElement.name];
    
  return self.document;
  }
  
// Start a new element.
- (void) startElement: (NSString *) name
  {
  if(![self validName: name])
    NSLog(@"Invalid element name: %@", name);
    
  // If I already have an element, I can go ahead and emit it now.
  XMLElement * topElement = [self.elements lastObject];
  
  if(topElement != nil)
    {
    [self.document 
      appendString: [self emitStartTag: topElement autoclose: NO]];
    
    // Emit any contents that I have.
    [self.document appendString: [self emitContents: topElement]];
    
    if(topElement.parent)
      [self.document appendString: @"\n"];
      
    // I know the top element has child elements now.
    topElement.parent = YES;
    topElement.empty = NO;
    
    // Reset contents in case there are more after this node.
    [topElement.contents setString: @""];
    }

  [self.elements
    addObject: [[XMLElement alloc] initWithName: name indent: self.indent]];
    
  self.indent = self.indent + 1;
  }
    
// Add a null attribute.
- (void) addNullAttribute: (NSString *) name
  {
  if(![self validName: name])
    NSLog(@"Invalid attribute name: %@", name);

  XMLElement * topElement = [self.elements lastObject];
  
  if(topElement != nil)
    [topElement.attributes setObject: [NSNull null] forKey: name];
  }

// Add a string attribute.
- (void) addStringAttribute: (NSString *) name value: (NSString *) value
  {
  if(value == nil)
    return;
    
  if(![self validName: name])
    NSLog(@"Invalid attribute name: %@=%@", name, value);

  if(![self validAttributeValue: value])
    NSLog(@"Invalid attribute value: %@=%@", name, value);

  XMLElement * topElement = [self.elements lastObject];
  
  if(topElement != nil)
    [topElement.attributes setObject: value forKey: name];
  }

// Add an NSObject attribute.
- (void) addAttribute: (NSString *) name value: (NSObject *) value
  {
  [self 
    addStringAttribute: name 
    value: [NSString stringWithFormat: @"%@", value]];
  }

// Add a boolen attribute.
- (void) addBooleanAttribute: (NSString *) name value: (BOOL) value
  {
  [self 
    addStringAttribute: name 
    value: 
      value  
        ? @"true"
        : @"false"];
  }

// Add an integer attribute.
- (void) addIntegerAttribute: (NSString *) name value: (NSInteger) value
  {
  [self 
    addStringAttribute: name 
    value: [NSString stringWithFormat: @"%lld", (long long)value]];
  }

// Add an unsigned integer attribute.
- (void) addUnsignedIntegerAttribute: (NSString *) name 
  value: (NSUInteger) value
  {
  [self 
    addStringAttribute: name 
    value: [NSString stringWithFormat: @"%llu", (unsigned long long)value]];
  }

// Add a long long attribute.
- (void) addLongLongAttribute: (NSString *) name value: (long long) value
  {
  [self 
    addStringAttribute: name 
    value: [NSString stringWithFormat: @"%lld", value]];
  }

// Add a double attribute.
- (void) addDoubleAttribute: (NSString *) name value: (double) value
  {
  [self 
    addStringAttribute: name 
    value: [NSString stringWithFormat: @"%f", value]];
  }

// Add a date attribute.
- (void) addDateAttribute: (NSString *) name value: (NSDate *) value
  {
  [self addStringAttribute: name value: [Utilities dateAsString: value]];
  }

// Add a URL attribute.
- (void) addURLAttribute: (NSString *) name value: (NSURL *) value
  {
  [self addStringAttribute: name value: value.absoluteString];
  }
  
// Add a string to the current element's contents.
- (void) addString: (NSString *) string
  {
  NSMutableString * text = [NSMutableString new];
  
  XMLElement * topElement = [self.elements lastObject];
  
  if(topElement != nil)
    {
    // Move the characters into a buffer.
    unichar * characters = malloc(sizeof(unichar) * (string.length + 1));
    
    [string 
      getCharacters: characters range: NSMakeRange(0, string.length)];
      
    for(int i = 0; i < string.length; ++i)
      switch(characters[i])
        {
        case '<':
          [text appendString: @"&lt;"];
          topElement.empty = NO;
          break;
          
        case '>':
          [text appendString: @"&gt;"];
          topElement.empty = NO;
          break;
          
        case '&':
          [text appendString: @"&amp;"];
          topElement.empty = NO;
          break;
          
        case 10:
        case 13:
          topElement.singleLine = NO;
          
        default:
          [text appendFormat: @"%c", characters[i]];
          topElement.empty = NO;
          break;
        }
      
      
    free(characters);
    
    [topElement.contents appendString: text];
    }
    
  [text release];
  }
  
// Add a CDATA string.
- (void) addCDATA: (NSString *) string
  {
  [self addString: string];
  
  XMLElement * topElement = [self.elements lastObject];
  
  if(topElement != nil)
    topElement.CDATARequired = YES;
  }

// Add a null element.
- (void) addNullElement: (nonnull NSString *) name
  {
  [self startElement: name];
  [self endElement: name];
  }

// Add a string element.
- (void) addStringElement: (NSString *) name value: (NSString *) value
  {
  [self startElement: name];
  [self addString: value];
  [self endElement: name];
  }
  
// Add an NSObject element.
- (void) addElement: (NSString *) name value: (NSObject *) value
  {
  [self 
    addStringElement: name 
    value: [NSString stringWithFormat: @"%@", value]];
  }

// Add a boolen element.
- (void) addBooleanElement: (NSString *) name value: (BOOL) value
  {
  [self 
    addStringElement: name 
    value: 
      value 
        ? @"true" 
        : @"false"];
  }

// Add an integer element.
- (void) addIntegerElement: (NSString *) name value: (NSInteger) value
  {
  [self 
    addStringElement: name 
    value: [NSString stringWithFormat: @"%lld", (long long)value]];
  }

// Add an unsigned integer element.
- (void) addUnsignedIntegerElement: (NSString *) name 
  value: (NSUInteger) value
  {
  [self 
    addStringElement: name 
    value: [NSString stringWithFormat: @"%llu", (unsigned long long)value]];
  }

// Add a long long element.
- (void) addLongLongElement: (NSString *) name value: (long long) value
  {
  [self 
    addStringElement: name 
    value: [NSString stringWithFormat: @"%lld", value]];
  }

// Add a double element.
- (void) addDoubleElement: (NSString *) name value: (double) value
  {
  [self 
    addStringElement: name 
    value: [NSString stringWithFormat: @"%f", value]];
  }

// Add a date element.
- (void) addDateElement: (NSString *) name value: (NSDate *) value
  {
  [self addStringElement: name value: [Utilities dateAsString: value]];
  }

// Add a URL element.
- (void) addURLElement: (NSString *) name value: (NSURL *) value
  {
  [self addStringElement: name value: value.absoluteString];
  }
  
// Finish the specified element, finishing any open elements if necessary.
- (void) endElement: (NSString *) name
  {
  // If I already have an element, I can go ahead and emit it now.
  XMLElement * topElement = [self.elements lastObject];

  while(topElement != nil)
    {
    self.indent -= 1;

    [self.document appendString: [self emitEndTag: topElement]];
    
    [self.elements removeObjectAtIndex: self.elements.count - 1];
    
    topElement = [self.elements lastObject];
    }
  }

// Finish the specified element if it is open.
- (void) endOpenElement: (NSString *) name
  {
  // If I already have an element, I can go ahead and emit it now.
  XMLElement * topElement = [self.elements lastObject];

  if(topElement != nil)
    {
    if([topElement.name isEqualToString: name])
      {
      self.indent -= 1;

      [self.document appendString: [self emitEndTag: topElement]];
      
      [self.elements removeObjectAtIndex: self.elements.count - 1];
      }
    }
  }
  
// MARK: Formatting

// Emit a start tag.
- (NSString *) emitStartTag: (XMLElement *) element 
  autoclose: (BOOL) autoclose
  {
  if(!element.startTagEmitted)
    {
    element.startTagEmitted = YES;
    
    NSMutableString * tag = [self emitIndentString: element];
    
    [tag appendString: @"<\(element.name)"];
    
    for(NSString * name in element.attributes)
      {
      NSString * value = element.attributes[name];
      
      [tag appendFormat: @"%@=\"%@\"", name, value];
      }
      
    // This is an end tag too and end tags always terminate a line.
    if(autoclose)
      [tag appendString: @"/>\n"];
      
    else
      [tag appendString: @">"];
      
    return tag;
    }
    
  return @"";
  }

// Emit contents of a tag.
- (NSString *) emitContents: (XMLElement *) element
  {
  NSMutableString * fragment = [NSMutableString string];
  
  if(element.CDATARequired)
    [fragment appendFormat: @"<![CDATA[%@]]>", element.contents];
    
  else
    [fragment appendString: element.contents];
    
  NSMutableString * empty = [NSMutableString new];
  
  element.contents = empty;
  element.CDATARequired = NO;
  
  [empty release];
  
  return fragment;
  }

// Emit an ending tag.
- (NSString *)  emitEndTag: (XMLElement *) element
  {
  NSMutableString * fragment = nil;
  
  // Emit the start tag if I haven't already done so.
  if(element.startTagEmitted)
    fragment = [self emitIndentString: element];
    
  else
    {
    // If this is an empty node, emit an autoclosing node and return.
    if(element.empty)
      return [self emitStartTag: element  autoclose: YES];
      
    [fragment setString: [self emitStartTag: element autoclose: NO]];
    }
    
  [fragment appendString: element.contents];

  [fragment appendString: @"</\(element.name)>"];
  
  // End tags always terminate a line.
  if(self.pretty)
    [fragment appendString: @"\n"];
    
  return fragment;
  }

// Emit an indent string.
- (NSMutableString *) emitIndentString: (XMLElement *) element
  {
  NSMutableString * s = [NSMutableString string];
  
  for(int i = 0; i < element.indent; ++i)
    [s appendString: @"  "];
    
  return s;
  }

// MARK: Validation

// Validate a name.
- (BOOL) validName: (NSString *) name
  {
  // Move the characters into a buffer.
  unichar * characters = malloc(sizeof(unichar) * (name.length + 1));
  
  [name getCharacters: characters range: NSMakeRange(0, name.length)];

  BOOL valid = YES;
  BOOL first = YES;
  
  for(int i = 0; i < name.length; ++i)
    {
    unichar ch = characters[i];
    
    switch(ch)
      {
      case ':':
      case '_':
      case 0xD8:
        break;
      default:
        if((ch >= 'A') && (ch <= 'Z'))
          break;
        if((ch >= 'a') && (ch <= 'a'))
          break;
        if((ch >= 0xC0) && (ch <= 0xD6))
          break;
        if((ch >= 0xD9) && (ch <= 0xF6))
          break;
        if((ch >= 0xF8) && (ch <= 0x2FF))
          break;
        if((ch >= 0x370) && (ch <= 0x37D))
          break;
        if((ch >= 0x200C) && (ch <= 0x200D))
          break;
        if((ch >= 0x2070) && (ch <= 0x218F))
          break;
        if((ch >= 0x2C00) && (ch <= 0x2FEF))
          break;
        if((ch >= 0x3001) && (ch <= 0xD7FF))
          break;
        if((ch >= 0xF900) && (ch <= 0xFDCF))
          break;
        if((ch >= 0xFDF0) && (ch <= 0xFFFD))
          break;
          
        // I guess unichar is too small for this.
        //if((ch >= 0x10000) && (ch <= 0xEFFFF))
        //  break;
        
        if(first)
          {
          valid = NO;
          break;
          }
        
        if(![self validiateOtherCharacters: ch])
          {
          valid = NO;
          break;
          }
      }

    first = NO;
    }
    
  return valid;
  }

// Validate other characters in a name.
- (BOOL) validiateOtherCharacters: (unichar) ch
  {
  switch(ch)
    {
    case '-':
    case '.':
    case '0':
    case '1':
    case '2':
    case '3':
    case '4':
    case '5':
    case '6':
    case '7':
    case '8':
    case '9':
    case 0xB7:
      break;
    
    default:
      if((ch >= 0x0300) && (ch <= 0x036F))
        break;
      if((ch >= 0x203F) && (ch <= 0x2040))
        break;

    return NO;
    }
    
  return YES;
  }

// Validate an attribute name.
- (BOOL) validAttributeValue: (NSString *) value
  {
  // Move the characters into a buffer.
  unichar * characters = malloc(sizeof(unichar) * (value.length + 1));
  
  [value 
    getCharacters: characters range: NSMakeRange(0, value.length)];

  BOOL valid = YES;
  
  for(int i = 0; i < value.length; ++i)
    switch(characters[i])
      {
      case '<':
        valid = NO;
        break;
        
      case '&':
        valid = NO;
        break;
        
      case '\"':
        valid = NO;
        break;
        
      default:
        break;
      }

  free(characters);
  
  return valid;
  }

@end

