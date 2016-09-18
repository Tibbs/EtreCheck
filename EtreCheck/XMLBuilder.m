/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2015. All rights reserved.
 **********************************************************************/

#import "XMLBuilder.h"

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

// An XML node.
@implementation XMLNode

@synthesize parent = myParent;

// Emit a node as an XML fragment.
- (NSString *) XMLFragment
  {
  // This will never be called. It is just a placeholder for derived
  // children.
  return @"";
  }

@end

// An XML text node.
@implementation XMLTextNode

@synthesize text = myText;
@synthesize leadingWhitespace = myLeadingWhitespace;
@synthesize trailingWhitespace = myTrailingWhitespace;
@synthesize multiLine = myMultiLine;

// Constructor.
- (instancetype) initWithText: (NSString *) text
  {
  self = [super init];
  
  if(self != nil)
    {
    myText = [text copy];
    
    NSRange range =
      [myText
        rangeOfCharacterFromSet:
          [NSCharacterSet whitespaceAndNewlineCharacterSet]];
      
    if(range.location == 0)
      myLeadingWhitespace = YES;
    
    range =
      [myText
        rangeOfCharacterFromSet:
          [NSCharacterSet whitespaceAndNewlineCharacterSet]
        options: NSBackwardsSearch];

    if(range.location != NSNotFound)
      if(([myText length] - range.location) == range.length)
        myTrailingWhitespace = YES;

    range =
      [myText
        rangeOfCharacterFromSet: [NSCharacterSet newlineCharacterSet]];
    
    if(range.location != NSNotFound)
      myMultiLine = YES;
      
    return self;
    }
    
  return nil;
  }

// Destructor.
- (void) dealloc
  {
  [myText release];
  
  [super dealloc];
  }

// For heterogeneous children.
- (BOOL) isXMLTextNode
  {
  return YES;
  }

// Emit a text node as an XML fragment. The indent is not used for
// a text node.
- (NSString *) XMLFragment
  {
  // If the text is has leading or trailing whitespace, put it in a CDATA.
  if(self.leadingWhitespace || self.trailingWhitespace)
    return [self XMLFragmentAsCDATA: self.text];
    
  // Try to escape it.
  NSString * escaped = [self XMLFragmentEscaped: self.text];
  
  // If I couldn't, or shouldn't, escape it, do a CDATA instead.
  if(!escaped)
    return [self XMLFragmentAsCDATA: self.text];
  
  // Whether I escaped anything or not, return the escaped version.
  return escaped;
  }

// Emit text as CDATA.
- (NSString *) XMLFragmentAsCDATA: (NSString *) text
  {
  // First see if the text has has the CDATA ending tag. If so, that will
  // need to be split out.
  NSRange range = [text rangeOfString: @"]]>"];
  
  NSString * first = text;
  NSString * rest = nil;
  
  if(range.location != NSNotFound)
    {
    first = [text substringToIndex: range.location + 1];
    rest = [text substringFromIndex: range.location + 1];
    }
    
  return
    [NSString
      stringWithFormat:
        @"<![CDATA[%@]]>%@",
        first,
        rest ? [self XMLFragmentAsCDATA: rest] : @""];
  }

// Escape text.
- (NSString *) XMLFragmentEscaped: (NSString *) text
  {
  // Create a new string.
  NSMutableString * escaped = [NSMutableString string];
  
  NSUInteger length = [text length];
  
  // Allocate space for the characters.
  unichar * characters = (unichar *)malloc(sizeof(unichar) * (length + 1));
  unichar * end = characters + length;
  
  // Extract the characters.
  [text getCharacters: characters range: NSMakeRange(0, length)];
  
  // Keep track of escaping bloat. If it gets too big, bail and do CDATA.
  NSUInteger bloat = 0;
  
  for(unichar * ch = characters; ch < end; ++ch)
    {
    switch(*ch)
      {
      case '\'':
        [escaped appendString: @"&apos"];
        bloat += 4;
        break;
        
      case '"':
        [escaped appendString: @"&quot"];
        bloat += 4;
        break;

      case '<':
        [escaped appendString: @"&lt"];
        bloat += 2;
        break;

      case '>':
        [escaped appendString: @"&gt"];
        bloat += 2;
        break;

      case '&':
        [escaped appendString: @"&amp"];
        bloat += 3;
        break;

      default:
        [escaped appendFormat: @"%c", *ch];
        break;
      }
    
    // Bail and do CDATA instead.
    if(bloat > 12)
      break;
    }
    
  free(characters);
  
  // Bail.
  if(bloat > 12)
    return nil;
    
  return escaped;
  }

@end

// Encapsulate each element.
@implementation XMLElement

@synthesize name = myName;
@synthesize attributes = myAttributes;
@synthesize children = myChildren;
@synthesize openChildren = myOpenChildren;

// Constructor with name.
- (instancetype) initWithName: (NSString *) name
  {
  self = [super init];
  
  if(self != nil)
    {
    myName = [name copy];
    myAttributes = [NSMutableDictionary new];
    myChildren = [NSMutableArray new];
    myOpenChildren = [NSMutableArray new];
    
    return self;
    }
    
  return nil;
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
- (NSString *) XMLFragment
  {
  NSMutableString * XML = [NSMutableString string];
  
  // Emit the start tag but room for attributes.
  [XML appendFormat: @"<%@", self.name];
  
  // Add any attributes.
  for(NSString * key in self.attributes)
    {
    NSString * value = [self.attributes objectForKey: key];
    
    [XML appendFormat: @" %@=\"%@\"", key, value];
    }
  
  // Don't close the opening tag yet. If I don't have any children, I'll
  // just want to make a self-closing tag.
  
  // Emit children - closed or open.
  if(([self.children count] + [self.openChildren count]) > 0)
    {
    // Finish the opening tag.
    [XML appendString: @">"];
    
    // Add children.
    [XML appendString: [self XMLFragments: self.children]];
    
    // Add open children.
    [XML appendString: [self XMLFragments: self.openChildren]];
    
    // Add the closing tag.
    [XML appendFormat: @"</%@>", self.name];
    }
    
  // I don't have any children, so turn the opening tag into a self-closing
  // tag.
  else
    [XML appendString: @"/>"];
    
  return XML;
  }

// Emit children element as an XML fragment.
- (NSString *) XMLFragments: (NSArray *) children
  {
  NSMutableString * XML = [NSMutableString string];

  for(XMLNode * child in children)
    [XML appendString: [child XMLFragment]];
    
  return XML;
  }

// Get the last currently open child.
- (XMLElement *) openChild
  {
  // Walk down through the open children and find the last one.
  XMLElement * openElement = [self.openChildren lastObject];
  
  XMLElement * nextOpenElement = openElement;
  
  while(nextOpenElement)
    {
    openElement = nextOpenElement;
    
    nextOpenElement = [nextOpenElement.openChildren lastObject];
    }
    
  return openElement;
  }

@end

// A root element.
@implementation XMLRootElement

// Constructor.
- (instancetype) init
  {
  self = [super initWithName: nil];
  
  if(self != nil)
    {
    return self;
    }
    
  return nil;
  }

// Destructor.
- (void) dealloc
  {
  [myOpenChildren release];
  [myChildren release];
  [myAttributes release];
  
  [super dealloc];
  }

// Emit an element as an XML fragment.
- (NSString *) XMLFragment
  {
  NSMutableString * XML = [NSMutableString string];
  
  [XML appendString: @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>"];
  
  // Add children.
  [XML appendString: [self XMLFragments: self.children]];
  
  // Add open children.
  [XML appendString: [self XMLFragments: self.openChildren]];
    
  return XML;
  }

@end

// A class for building an XML document.
@implementation XMLBuilder

@synthesize XML = myXML;
@synthesize dateFormatter = myDateFormatter;
@synthesize root = myRoot;

// Constructor.
- (instancetype) init
  {
  self = [super init];
  
  if(self != nil)
    {
    myRoot = [XMLRootElement new];
    
    return self;
    }
    
  return nil;
  }

// Destructor.
- (void) dealloc
  {
  [myRoot release];
  
  [super dealloc];
  }

// Return the current state of the builder as XML.
- (NSString *) XML
  {
  return [self.root XMLFragment];
  }

// Return the date formatter, creating one, if necessary.
- (NSDateFormatter *) dateFormatter
  {
  if(!myDateFormatter)
    {
    myDateFormatter = [[NSDateFormatter alloc] init];
    
    [myDateFormatter setDateFormat: @"yyyy-MM-dd HH:mm:ss Z"];
    [myDateFormatter setTimeZone: [NSTimeZone localTimeZone]];
    [myDateFormatter
      setLocale: [NSLocale localeWithLocaleIdentifier: @"en_US"]];
    }
    
  return myDateFormatter;
  }

// Start a new element.
- (void) startElement: (NSString *) name
  {
  // Validate the name.
  if(![self validName: name])
    @throw InvalidElementNameException(name);
    
  // Add the new element onto the end of the last open child.
  XMLElement * openChild = [self.root openChild];
  
  // If there is no open child, use root.
  if(openChild == nil)
    openChild = self.root;
    
  // Create the element.
  XMLElement * newChild = [[XMLElement alloc] initWithName: name];
  
  // Connect it to the parent.
  newChild.parent = openChild;
  
  [openChild.openChildren addObject: newChild];
  }
  
// Finish the current element.
- (void) endElement: (NSString *) name
  {
  // Find the currently open child.
  XMLElement * openChild = [self.root openChild];
  
  // There should be at least one.
  if(openChild == nil)
    @throw NoOpenElementException();
  
  // And it should be the element beingn closed.
  if(![name isEqualToString: openChild.name])
    @throw AttemptToCloseWrongElementException(name);
    
  // Move the element being closed from its parent's open list to its
  // parent's closed list.
  XMLElement * parent = openChild.parent;
  
  [parent.children addObject: openChild];
  [parent.openChildren removeLastObject];
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
  [self addElement: name value: [self.dateFormatter stringFromDate: date]];
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
  // Find the currently open child.
  XMLElement * openChild = [self.root openChild];
  
  // Make sure there is an open child.
  if(openChild == nil)
    @throw NoOpenElementException();

  XMLTextNode * textNode = [[XMLTextNode alloc] initWithText: string];
    
  [openChild.children addObject: textNode];
  
  [textNode release];
  }

// Add an attribute to the current element.
- (void) addAttribute: (NSString *) name value: (NSString *) value
  {
  // Require a value.
  if(value == nil)
    return;
    
  // Make sure the name is valid.
  if(![self validName: name])
    @throw InvalidAttributeNameException(name);

  // Make sure the value is valid.
  if(![self validAttributeValue: value])
    @throw InvalidAttributeValueException(value);

  // Find the currently open child.
  XMLElement * openChild = [self.root openChild];

  // Make sure there is an open child.
  if(openChild == nil)
    @throw NoOpenElementException();

  // Set the value.
  [openChild.attributes setObject: value forKey: name];
  }

// Add an attribute to the current element.
- (void) addAttribute: (NSString *) name number: (NSNumber *) value
  {
  [self addAttribute: name value: [value stringValue]];
  }
  
// Add an attribute to the current element.
- (void) addAttribute: (NSString *) name date: (NSDate *) date
  {
  [self
    addAttribute: name value: [self.dateFormatter stringFromDate: date]];
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


