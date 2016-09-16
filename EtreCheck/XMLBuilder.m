/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2015. All rights reserved.
 **********************************************************************/

#import "XMLBuilder.h"
#import "Utilities.h"

// No open element.
@interface NoOpenElement : XMLException

@end

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

NoOpenElement * NoOpenElementException(void);
InvalidElementName * InvalidElementNameException(NSString * name);
InvalidAttributeName * InvalidAttributeNameException(NSString * name);
InvalidAttributeValue * InvalidAttributeValueException(NSString * name);
AttemptToCloseWrongElement *
  AttemptToCloseWrongElementException(NSString * name);

// Encapsulate each element.
@implementation XMLElement

@synthesize name = myName;
@synthesize parent = myParent;
@synthesize attributes = myAttributes;
@synthesize singleLine = mySingleLine;
@synthesize CDATARequired = myCDATARequired;
@synthesize children = myChildren;
@synthesize openChildren = myOpenChildren;

// Constructor with name and indent.
- (instancetype) initWithName: (NSString *) name
  {
  self = [super init];
  
  if(self)
    {
    myName = name;
    myAttributes = [NSMutableDictionary new];
    myChildren = [NSMutableArray new];
    myOpenChildren = [NSMutableArray new];
    }
    
  return self;
  }

// Destructor.
- (void) dealloc
  {
  [myOpenChildren release];
  [myChildren release];
  [myAttributes release];
  
  [super dealloc];
  }

// For heterogeneous children.
- (BOOL) isXMLElement
  {
  return YES;
  }

// Emit an element as an XML fragment.
- (NSString *) XMLFragment: (NSString *) indent
  {
  NSMutableString * XML = [NSMutableString string];
  
  [XML appendFormat: @"%@<%@", indent, self.name];
  
  for(NSString * key in self.attributes)
    {
    NSString * value = [self.attributes objectForKey: key];
    
    [XML appendFormat: @" %@=\"%@\"", key, value];
    }
    
  if(([self.children count] + [self.openChildren count]) > 0)
    {
    [XML appendString: @">"];
    
    NSString * childIndent = @"";
    
    if(!self.singleLine)
      {
      [XML appendString: @"\n"];
      
      childIndent = [indent stringByAppendingString: @"  "];
      }
      
    [XML
      appendString:
        [self XMLFragment: childIndent children: self.children]];
    [XML
      appendString:
        [self XMLFragment: childIndent children: self.openChildren]];
    
    [XML appendFormat: @"%@</%@>\n", indent, self.name];
    }
  else
    [XML appendString: @"/>\n"];
    
  return XML;
  }

// Emit children element as an XML fragment.
- (NSString *) XMLFragment: (NSString *) indent
  children: (NSArray *) children
  {
  NSMutableString * XML = [NSMutableString string];

  for(XMLElement * child in children)
    [XML appendString: [child XMLFragment: indent]];
    
  return XML;
  }

// Get the last currently open child.
- (XMLElement *) openChild
  {
  XMLElement * openElement = [self.openChildren lastObject];
  
  XMLElement * nextOpenElement = openElement;
  
  while(nextOpenElement)
    {
    openElement = nextOpenElement;
    
    nextOpenElement = [nextOpenElement.children lastObject];
    }
    
  return openElement;
  }

@end

// A class for building an XML document.
@implementation XMLBuilder

@synthesize XML = myXML;
@synthesize root = myRoot;

// Pop the stack and return what we have.
- (NSString *) XML
  {
  return [self.root XMLFragment: @""];
  }

// Start a new element.
- (void) startElement: (NSString *) name
  {
  if(![self validName: name])
    @throw InvalidElementNameException(name);
    
  XMLElement * openChild = [self.root openChild];
  
  if(openChild == nil)
    openChild = self.root;
    
  XMLElement * newChild = [[XMLElement alloc] initWithName: name];
  
  newChild.parent = openChild;
  
  [openChild.openChildren addObject: newChild];
  }
  
// Finish the current element.
- (void) endElement: (NSString *) name
  {
  XMLElement * openChild = [self.root openChild];
  
  if(openChild == nil)
    @throw NoOpenElementException();
  
  if(![name isEqualToString: openChild.name])
    @throw AttemptToCloseWrongElementException(name);
    
  XMLElement * parent = openChild.parent;
  
  [parent.children addObject: openChild];
  [parent.openChildren removeLastObject];
  
  if([openChild.children count] == 1)
    {
    id singleChild = [openChild.children lastObject];
    
    if(![singleChild respondsToSelector: @selector(isXMLElement)])
      openChild.singleLine = YES;
    }
  }
  
// Add an element and value with a convenience function.
- (void) addElement: (NSString *) name value: (NSString *) value
  {
  [self startElement: name];
  
  if([value length] > 0)
    [self addString: value];
    
  [self endElement: name];
  }

// Add an element and value with a convenience function.
- (void) addElement: (NSString *) name number: (NSNumber *) value
  {
  if(value == nil)
    [self addElement: name value: nil];
  else
    [self addElement: name value: [value stringValue]];
  }

// Add an element to the current element.
- (void) addElement: (NSString *) name date: (NSDate *) date
  {
  [self addElement: name value: [Utilities dateAsString: date]];
  }

// Add an element and value with a convenience function.
- (void) addElement: (NSString *) name boolValue: (BOOL) value;
  {
  [self addElement: name value: value ? @"true" : @"false"];
  }

// Add an element and value with a convenience function.
- (void) addElement: (NSString *) name intValue: (int) value
  {
  [self addElement: name value: [NSString stringWithFormat: @"%d", value]];
  }

// Add an element and value with a convenience function.
- (void) addElement: (NSString *) name longValue: (long) value
  {
  [self addElement: name value: [NSString stringWithFormat: @"%ld", value]];
  }

// Add an element and value with a convenience function.
- (void) addElement: (NSString *) name longlongValue: (long long) value
  {
  [self
    addElement: name value: [NSString stringWithFormat: @"%lld", value]];
  }

// Add an element and value with a convenience function.
- (void) addElement: (NSString *) name
  unsignedIntValue: (unsigned int) value
  {
  [self addElement: name value: [NSString stringWithFormat: @"%ud", value]];
  }

// Add an element and value with a convenience function.
- (void) addElement: (NSString *) name
  unsignedLongValue: (unsigned long) value
  {
  [self
    addElement: name value: [NSString stringWithFormat: @"%lud", value]];
  }

// Add an element and value with a convenience function.
- (void) addElement: (NSString *) name
  unsignedLonglongValue: (unsigned long long) value
  {
  [self
    addElement: name value: [NSString stringWithFormat: @"%llulld", value]];
  }

// Add an element and value with a convenience function.
- (void) addElement: (NSString *) name integerValue: (NSInteger) value
  {
  [self
    addElement: name
    value: [NSString stringWithFormat: @"%ld", (long)value]];
  }

// Add an element and value with a convenience function.
- (void) addElement: (NSString *) name
  unsignedIntegerValue: (NSUInteger) value
  {
  [self
    addElement: name
    value: [NSString stringWithFormat: @"%ld", (unsigned long)value]];
  }

// Add an element and value with a convenience function.
- (void) addElement: (NSString *) name float: (float) value
  {
  [self addElement: name value: [NSString stringWithFormat: @"%f", value]];
  }

// Add an element and value with a convenience function.
- (void) addElement: (NSString *) name doubleValue: (double) value
  {
  [self addElement: name value: [NSString stringWithFormat: @"%f", value]];
  }

// Add an element and value with a convenience function.
- (void) addElement: (NSString *) name UTF8StringValue: (char *) value
  {
  [self addElement: name value: [NSString stringWithFormat: @"%s", value]];
  }

// Add a string to the current element's contents.
- (void) addString: (NSString *) string
  {
  NSMutableString * text = [NSMutableString new];
  
  XMLElement * openChild = [self.root openChild];
  
  if(openChild == nil)
    @throw NoOpenElementException();

  NSUInteger length = [string length];
  
  unichar * characters =
    (unichar *)malloc(sizeof(unichar) * (length + 1));
  unichar * end = characters + length;
  
  [string getCharacters: characters range: NSMakeRange(0, length)];
  
  for(unichar * ch = characters; ch < end; ++ch)
    {
    switch(*ch)
      {
      case '<':
        [text appendString: @"&lt;"];
        break;
      case '>':
        [text appendString: @"&gt;"];
        break;
      case '&':
        [text appendString: @"&amp;"];
        break;
      case '\n':
      case '\r':
        openChild.multiLine = YES;
      default:
        [text
          appendString: [NSString stringWithCharacters: ch length: 1]];
        break;
      }
    }
  
  [openChild.contents appendString: text];
  
  free(characters);
    
  [text release];
  }

// Add a CDATA string.
- (void) addCDATA: (NSString *) cdata
  {
  [self addString: cdata];
  
  XMLElement * topElement = [self.elements lastObject];
  
  if(topElement != nil)
    topElement.CDATARequired = YES;
  }

// Add an attribute to the current element.
- (void) addAttribute: (NSString *) name value: (NSString *) value
  {
  if(value == nil)
    return;
    
  if(![self validName: name])
    @throw InvalidAttributeNameException(name);

  if(![self validAttributeValue: value])
    @throw InvalidAttributeValueException(value);

  XMLElement * topElement = [self.elements lastObject];
  
  if(topElement != nil)
    topElement.attributes[name] = value;
  }

// Add an attribute to the current element.
- (void) addAttribute: (NSString *) name number: (NSNumber *) value
  {
  [self addAttribute: name value: [value stringValue]];
  }
  
// Add an attribute to the current element.
- (void) addAttribute: (NSString *) name date: (NSDate *) date
  {
  [self addAttribute: name value: [Utilities dateAsString: date]];
  }

// Add an element and value with a convenience function.
- (void) addAttribute: (NSString *) name boolValue: (BOOL) value
  {
  [self addAttribute: name value: value ? @"true" : @"false"];
  }

// Add an element and value with a convenience function.
- (void) addAttribute: (NSString *) name intValue: (int) value
  {
  [self
    addAttribute: name value: [NSString stringWithFormat: @"%d", value]];
  }

// Add an element and value with a convenience function.
- (void) addAttribute: (NSString *) name longValue: (long) value
  {
  [self
    addAttribute: name value: [NSString stringWithFormat: @"%ld", value]];
  }

// Add an element and value with a convenience function.
- (void) addAttribute: (NSString *) name longlongValue: (long long) value
  {
  [self
    addAttribute: name value: [NSString stringWithFormat: @"%lld", value]];
  }

// Add an element and value with a convenience function.
- (void) addAttribute: (NSString *) name
  unsignedIntValue: (unsigned int) value
  {
  [self
    addAttribute: name value: [NSString stringWithFormat: @"%d", value]];
  }

// Add an element and value with a convenience function.
- (void) addAttribute: (NSString *) name
  unsignedLongValue: (unsigned long) value
  {
  [self
    addAttribute: name value: [NSString stringWithFormat: @"%lu", value]];
  }

// Add an element and value with a convenience function.
- (void) addAttribute: (NSString *) name
  unsignedLonglongValue: (unsigned long long) value
  {
  [self
    addAttribute: name value: [NSString stringWithFormat: @"%llu", value]];
  }

// Add an element and value with a convenience function.
- (void) addAttribute: (NSString *) name integerValue: (NSInteger) value
  {
  [self
    addAttribute: name
    value: [NSString stringWithFormat: @"%ld", (long)value]];
  }

// Add an element and value with a convenience function.
- (void) addAttribute: (NSString *) name
  unsignedIntegerValue: (NSUInteger) value
  {
  [self
    addAttribute: name
    value: [NSString stringWithFormat: @"%lu", (unsigned long)value]];
  }

// Add an element and value with a convenience function.
- (void) addAttribute: (NSString *) name float: (float) value
  {
  [self
    addAttribute: name value: [NSString stringWithFormat: @"%f", value]];
  }

// Add an element and value with a convenience function.
- (void) addAttribute: (NSString *) name doubleValue: (double) value
  {
  [self
    addAttribute: name value: [NSString stringWithFormat: @"%f", value]];
  }

// Add an element and value with a convenience function.
- (void) addAttribute: (NSString *) name UTF8StringValue: (char *) value
  {
  [self
    addAttribute: name value: [NSString stringWithFormat: @"%s", value]];
  }

// MARK: Formatting

// Emit a start tag.
- (NSMutableString *) emitStartTag: (XMLElement *) element
  {
  return [self emitStartTag: element autoclose: NO];
  }
  
// Emit a start tag.
- (NSMutableString *) emitStartTag: (XMLElement *) element
  autoclose: (BOOL) autoclose
  {
  if(!element.startTagEmitted)
    {
    element.startTagEmitted = YES;
    
    NSMutableString * tag =
      [NSMutableString stringWithString: [self emitIndentString: element]];
    
    [tag appendFormat: @"<%@", element.name];
    
    for(NSString * name in element.attributes)
      [tag
        appendFormat:
          @" %@=\"%@\"", name, [element.attributes objectForKey: name]];
      
    // This is an end tag too and end tags always terminate a line.
    if(autoclose)
      [tag appendString: @"/>\n"];
      
    else
      [tag appendString: @">"];
      
    return tag;
    }
    
  return [NSMutableString string];
  }
  
// Emit contents of a tag.
- (NSString *) emitContents: (XMLElement *) element
  {
  NSMutableString * fragment = [NSMutableString string];
  
  if(element.CDATARequired)
    [fragment appendFormat: @"<![CDATA[%@]]>", element.contents];
    
  else
    [fragment appendString: element.contents];
    
  [element.contents setString: @""];
  element.CDATARequired = NO;
  
  return fragment;
  }
  
// Emit an ending tag.
- (NSString *) emitEndTag: (XMLElement *) element
  {
  NSMutableString * fragment = [self emitIndentString: element];
  
  // Emit the start tag if I haven't already done so.
  if(!element.startTagEmitted)
    {
    // If this is an empty node, emit an autoclosing note and return.
    if(element.empty)
      return [self emitStartTag: element autoclose: YES];
      
    fragment = [self emitStartTag: element];
    }
    
  [fragment appendString: element.contents];

  [fragment appendFormat: @"</%@>", element.name];
  
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
  BOOL first = YES;
  
  NSUInteger length = [name length];
  
  unichar * characters = (unichar *)malloc(sizeof(unichar) * (length + 1));
  unichar * end = characters + length;
  
  [name getCharacters: characters range: NSMakeRange(0, length)];
  
  for(unichar * ch = characters; ch < end; ++ch)
    {
    if(*ch == ':' || *ch == '_')
      continue;
    if(((*ch >= 'A') && (*ch <= 'Z')) || ((*ch >= 'a') && (*ch <= 'z')))
      continue;
    if((*ch >= L'\u00C0') && (*ch <= L'\u00D6'))
      continue;
    if((*ch == L'\u00D8') || ((*ch >= L'\u00D9') && (*ch <= L'\u00F6')))
      continue;
    if((*ch >= L'\u00F8') && (*ch <= L'\u02FF'))
      continue;
    if((*ch >= L'\u0370') && (*ch <= L'\u037D'))
      continue;
    if((*ch >= L'\u037F') && (*ch <= L'\u1FFF'))
      continue;
    if((*ch >= L'\u200C') && (*ch <= L'\u200D'))
      continue;
    if((*ch >= L'\u2070') && (*ch <= L'\u218F'))
      continue;
    if((*ch >= L'\u2C00') && (*ch <= L'\u2FEF'))
      continue;
    if((*ch >= L'\u3001') && (*ch <= L'\uD7FF'))
      continue;
    if((*ch >= L'\uF900') && (*ch <= L'\uFDCF'))
      continue;
    if((*ch >= L'\uFDF0') && (*ch <= L'\uFFFD'))
      continue;
    //if((*ch >= L'\U00010000') && (*ch <= L'\U000EFFFF'))
    //  continue;
    if(first)
      return NO;
      
    if(![self validiateOtherCharacters: *ch])
      return NO;

    first = NO;
    }

  free(characters);
    
  return YES;
  }
  
// Validate other characters in a name.
- (BOOL) validiateOtherCharacters: (unichar) ch
  {
  if(ch == '-')
    return YES;
    
  if(ch == '.')
    return YES;
    
  if((ch >= '0') && (ch <= '9'))
    return YES;
    
  if(ch == L'\u00B7')
    return YES;
    
  if((ch >= L'\u0300') && (ch <= L'\u036F'))
    return YES;
    
  if((ch >= L'\u203F') && (ch <= L'\u2040'))
    return YES;
  
  return NO;
  }
  
// Validate an attribute name.
- (BOOL) validAttributeValue: (NSString *) name
  {
  NSUInteger length = [name length];
  
  unichar * characters = (unichar *)malloc(sizeof(unichar) * (length + 1));
  unichar * end = characters + length;
  
  [name getCharacters: characters range: NSMakeRange(0, length)];
  
  BOOL result = YES;
  
  for(unichar * ch = characters; ch < end; ++ch)
    {
    if(*ch == '<')
      {
      result = NO;
      break;
      }
      
    if(*ch == '&')
      {
      result = NO;
      break;
      }

    if(*ch == '"')
      {
      result = NO;
      break;
      }
    }

  free(characters);

  return result;
  }

@end

NoOpenElement * NoOpenElementException(void)
  {
  return nil;
  }

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


