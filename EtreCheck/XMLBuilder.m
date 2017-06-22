/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2015-2017. All rights reserved.
 **********************************************************************/

#import "XMLBuilder.h"

// Invalid element name.
@interface InvalidElementName : XMLException

@end

// Invalid attribute name.
@interface InvalidAttributeName : XMLException

@end

// Invalid attribute value.
@interface InvalidAttributeValue : XMLException

@end

// Attempting to close the wrong element.
@interface AttemptToCloseWrongElement : NSException

@end

InvalidElementName * InvalidElementNameException(NSString * name);
InvalidAttributeName * InvalidAttributeNameException(NSString * name);
InvalidAttributeValue * InvalidAttributeValueException(NSString * name);
AttemptToCloseWrongElement *
  AttemptToCloseWrongElementException(NSString * name);

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
  
  if(self)
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
    @throw InvalidElementNameException(name);
    
  // If I already have an element, I can go ahead and emit it now.
  XMLElement * topElement = [self.elements lastObject];
  
  if(topElement != nil)
    {
    [self.document appendString: [self emitStartTag: topElement]];
    
    // Emit any contents that I have.
    [self.document appendString: [self emitContents: topElement]];
    
    if(!topElement.parent)
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
  
// Add an attribute to the current element.
- (void) addAttribute: (NSString *) name value: (NSObject *) value
  {
  if(value == nil)
    return;
    
  if(![self validName: name])
    @throw InvalidAttributeNameException(name);

  NSString * attributeStringValue = [value stringValue];
  
  if(![self validAttributeValue: attributeStringValue])
    @throw InvalidAttributeValueException(attributeStringValue);

  XMLElement * topElement = [self.elements lastObject];
  
  if(topElement != nil)
    [topElement.attributes setObject: attributeStringValue forKey: name];
  }
  
// Add a string to the current element's contents.
- (void) addString: (NSString *) string
  {
  NSString * text = @"";
  
  XMLElement * topElement = [self.elements lastObject];
  
  if(topElement != nil)
    {
    for ch in string.characters
      {
      switch(ch)
        {
        case "<":
          text += "&lt;"
          topElement.empty = false
          break
        case ">":
          text += "&gt;"
          topElement.empty = false
          break
        case "&":
          text += "&amp;"
          topElement.empty = false
          break
        case "\n":
          fallthrough
        case "\r":
          topElement.singleLine = false
          fallthrough
        default:
          text.append(ch)
          topElement.empty = false
          break
        }
      }
    
    topElement.contents += text
    }
  }
  
  // Add a CDATA string.
  func addCDATA(cdata: String)
    {
    addString(cdata)
    
    if let topElement = elements.last
      {
      topElement.CDATARequired = true
      }
    }
  
  // Finish the current element.
  func endElement(name: String) throws
    {
    // If I already have an element, I can go ahead and emit it now.
    if let topElement = elements.last
      {
      if name != topElement.name
        {
        throw Exception.AttemptToCloseWrongElement(name: name)
        }
      
      indent -= 1

      document += emitEndTag(topElement)
      
      elements.removeLast()
      }
    }
  
  // Add an element and value with a conveneience function.
  func addElement<T>(name: String, value: T?) throws
    {
    if let elementValue = value
      {
      try startElement(name)
      addString("\(elementValue)")
      try endElement(name)
      }
    }
  
  // MARK: Formatting
  
  // Emit a start tag.
  func emitStartTag(element: Element, autoclose: Bool = false) -> String
    {
    if !element.startTagEmitted
      {
      element.startTagEmitted = true
      
      var tag = emitIndentString(element)
      
      tag += "<\(element.name)"
      
      for (name, value) in element.attributes
        {
        tag += " \(name)=\"\(value)\""
        }
        
      // This is an end tag too and end tags always terminate a line.
      if autoclose
        {
        tag += "/>\n"
        }
      else
        {
        tag += ">"
        }
        
      return tag
      }
      
    return ""
    }
  
  // Emit contents of a tag.
  func emitContents(element: Element) -> String
    {
    var fragment = ""
    
    if element.CDATARequired
      {
      fragment += "<![CDATA[\(element.contents)]]>"
      }
    else
      {
      fragment += element.contents
      }
      
    element.contents = ""
    element.CDATARequired = false
    
    return fragment
    }
  
  // Emit an ending tag.
  func emitEndTag(element: Element) -> String
    {
    var fragment = emitIndentString(element)
    
    // Emit the start tag if I haven't already done so.
    if !element.startTagEmitted
      {
      // If this is an empty node, emit an autoclosing note and return.
      if element.empty
        {
        fragment = emitStartTag(element, autoclose: true)
        
        return fragment
        }
        
      fragment = emitStartTag(element)
      }
      
    fragment += element.contents

    fragment += "</\(element.name)>"
    
    // End tags always terminate a line.
    if pretty
      {
      fragment += "\n"
      }
      
    return fragment
    }
  
  // Emit an indent string.
  func emitIndentString(element: Element) -> String
    {
    var s = ""
    
    for _ in 0..<element.indent
      {
      s += "  "
      }
      
    return s
    }
  
  // MARK: Validation
  
  // Validate a name.
  func validName(name: String) -> Bool
    {
    var first = true
    
    for ch in name.characters
      {
      switch(ch)
        {
        case ":", "_":
          break
        case "A"..."Z", "a"..."z" :
          break
        case "\u{C0}"..."\u{D6}":
          break
        case "\u{D8}", "\u{D9}"..."\u{F6}":
          break
        case "\u{F8}"..."\u{2FF}":
          break
        case "\u{370}"..."\u{37D}":
          break
        case "\u{37F}"..."\u{1FFF}":
          break
        case "\u{200C}"..."\u{200D}":
          break
        case "\u{2070}"..."\u{218F}":
          break
        case "\u{2C00}"..."\u{2FEF}":
          break
        case "\u{3001}"..."\u{D7FF}":
          break
        case "\u{F900}"..."\u{FDCF}":
          break
        case "\u{FDF0}"..."\u{FFFD}":
          break
        case "\u{10000}"..."\u{EFFFF}":
          break
        default:
          if first
            {
            return false
            }
          
          if !validiateOtherCharacters(ch)
            {
            return false
            }
        }

      first = false
      }
      
    return true
    }
  
  // Validate other characters in a name.
  func validiateOtherCharacters(ch: Character) -> Bool
    {
    switch(ch)
      {
      case "-":
        break
      case "." :
        break
      case "0"..."9" :
        break
      case "\u{B7}":
        break
      case "\u{0300}"..."\u{036F}":
        break
      case "\u{203F}"..."\u{2040}":
        break
      default:
        return false
      }
      
    return true
    }
  
  // Validate an attribute name.
  func validAttributeValue(name: String) -> Bool
    {
    for ch in name.characters
      {
      switch(ch)
        {
        case "<":
          return false
        case "&":
          return false
        case "\"":
          return false
        default:
          break
        }
      }

    return true
    }
  }

@end

InvalidElementName * InvalidElementNameException(NSString * name)
  {
  return nil;
  }

InvalidAttributeName * InvalidAttributeNameException(NSString * name)
  {
  return nil;
  }

InvalidAttributeValue * InvalidAttributeValueException(NSString * name)
  {
  return nil;
  }

AttemptToCloseWrongElement *
  AttemptToCloseWrongElementException(NSString * name)
  {
  return nil;
  }
