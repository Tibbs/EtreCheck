/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014-2017. All rights reserved.
 **********************************************************************/

#import "CollectorModel.h"
#import "Utilities.h"
#import "NumberFormatter.h"

@interface CollectorModel ()
  {
  NSMutableDictionary * myDictionary;
  }

@property (readonly) NSMutableDictionary * dictionary;

@end

@implementation CollectorModel

@synthesize dictionary = myDictionary;

// Constructor.
- (instancetype) init
  {
  self = [super init];
  
  if(self != nil)
    {
    myDictionary = [NSMutableDictionary new];
    }
    
  return self;
  }

// Destructor.
- (void) dealloc
  {
  [myDictionary release];
  
  [super dealloc];
  }

// Get a void value for a key.
- (BOOL) boolValueForKey: (NSString *) key
  {
  NSNumber * number = [self.dictionary objectForKey: key];
  
  if([number respondsToSelector: @selector(boolValue)])
    return [number boolValue];
    
  return NO;
  }

// Get an NSInteger value for a key.
- (NSInteger) integerForKey: (NSString *) key
  {
  NSNumber * number = [self.dictionary objectForKey: key];
  
  if([number respondsToSelector: @selector(integerValue)])
    return [number integerValue];
    
  return 0;
  }

// Get an NSUInteger value for a key.
- (NSUInteger) unsignedIntegerForKey: (NSString *) key
  {
  NSNumber * number = [self.dictionary objectForKey: key];
  
  if([number respondsToSelector: @selector(unsignedIntegerValue)])
    return [number unsignedIntegerValue];
    
  return 0;
  }

// Get a long long value for a key.
- (long long) longlongForKey: (NSString *) key
  {
  NSNumber * number = [self.dictionary objectForKey: key];
  
  if([number respondsToSelector: @selector(longLongValue)])
    return [number longLongValue];
    
  return 0;
  }

// Get a double value for a key.
- (double) doubleForKey: (NSString *) key
  {
  NSNumber * number = [self.dictionary objectForKey: key];
  
  if([number respondsToSelector: @selector(doubleValue)])
    return [number doubleValue];
    
  return 0;
  }

// Get an NSString value for a key.
- (NSString *) stringForKey: (NSString *) key
  {
  NSString * value = [self.dictionary objectForKey: key];
  
  if([value respondsToSelector: @selector(UTF8String)])
    return value;
    
  return nil;
  }

// Get an NSData value for a key.
- (NSData *) dataForKey: (NSString *) key
  {
  NSData * data = [self.dictionary objectForKey: key];
  
  if([data respondsToSelector: @selector(bytes)])
    return data;
    
  return nil;
  }

// Get an NSDate value for a key.
- (NSDate *) dateForKey: (NSString *) key
  {
  NSDate * date = [self.dictionary objectForKey: key];
  
  if([date respondsToSelector: @selector(isEqualToDate:)])
    return date;
    
  return nil;
  }

// Get an NSURL value for a key.
- (NSURL *) urlForKey: (NSString *) key
  {
  NSURL * url = [self.dictionary objectForKey: key];
  
  if([url respondsToSelector: @selector(host)])
    return url;
    
  return nil;
  }

// Get an NSObject value for a key.
- (NSObject *) valueForKey: (id<NSCopying>) key
  {
  return [self.dictionary objectForKey: key];
  }

// Get an NSNumber value for a key.
- (NSNumber *) numberForKey: (NSString *) key
  {
  NSNumber * number = [self.dictionary objectForKey: key];
  
  if([number respondsToSelector: @selector(longLongValue)])
    return number;
    
  return nil;
  }

// Get an NSObject value using array subscripting.
- (NSObject *) valueForKeyedSubscript: (id<NSCopying>) key
  {
  return [self.dictionary objectForKey: key];
  }

// Bind an NSNull value to a key.
- (void) setNullForKey: (NSString *) key
  {
  self.dictionary[key] = [NSNull null];
  }

// Bind a void value to a key.
- (void) setBoolean: (BOOL) value forKey: (NSString *) key
  {
  self.dictionary[key] = [NSNumber numberWithBool: value];
  }

// Bind an NSInteger to a key.
- (void) setInteger: (NSInteger) value forKey: (NSString *) key
  {
  self.dictionary[key] = [NSNumber numberWithInteger: value];
  }

// Bind an NSUInteger value to key.
- (void) setUnsignedInteger: (NSUInteger) value forKey: (NSString *) key
  {
  self.dictionary[key] = [NSNumber numberWithUnsignedInteger: value];
  }

// Bind a long long value to a key.
- (void) setLongLong: (long long) value forKey: (NSString *) key
  {
  self.dictionary[key] = [NSNumber numberWithLongLong: value];
  }

// Bind a double value to a key.
- (void) setDouble: (double) value forKey: (NSString *) key
  {
  self.dictionary[key] = [NSNumber numberWithDouble: value];
  }

// Bind an NSString value to a key.
- (void) setString: (NSString *) value forKey: (NSString *) key
  {
  if([value respondsToSelector: @selector(UTF8String)])
    self.dictionary[key] = value;
  }

// Bind an NSData value to a key
- (void) setData: (NSData *) value forKey: (NSString *) key
  {
  if([value respondsToSelector: @selector(bytes)])
    self.dictionary[key] = value;
  else if([value respondsToSelector: @selector(UTF8String)])
    {
    NSData * data =
      [(NSString *)value dataUsingEncoding: NSUTF8StringEncoding];
    
    if(data != nil)
      self.dictionary[key] = data;
    }
  }

// Bind an NSDate value to a key.
- (void) setDate: (NSDate *) value forKey: (NSString *) key
  {
  if([value respondsToSelector: @selector(isEqualToString:)])
    self.dictionary[key] = value;
  else if([value respondsToSelector: @selector(UTF8String)])
    {
    NSDate * date = [Utilities stringAsDate: (NSString *) value];
    
    if(date == nil)
      date =
        [Utilities
          stringAsDate: (NSString *) value format: @"yyyy-MM-dd-HHmmss"];
    
    if(date == nil)
      date =
        [Utilities
          stringAsDate: (NSString *) value
          format: @"MMM d, yyyy, hh:mm:ss a"];
      
    if(date == nil)
      date =
        [Utilities
          stringAsDate: (NSString *) value
          format: @"MMM d HH:mm:ss"];
      
    if(date != nil)
      self.dictionary[key] = date;
    }
  }

// Bind an NSURL value to a key.
- (void) setURL: (NSURL *) value forKey: (NSString *) key
  {
  if([value respondsToSelector: @selector(host)])
    self.dictionary[key] = value;
  else if([value respondsToSelector: @selector(UTF8String)])
    {
    NSURL * url = [NSURL URLWithString: (NSString *)value];
    
    if(url != nil)
      self.dictionary[key] = url;
    }
  }

// Bind an object value to a key.
- (void) setObject: (id) object forKey: (id<NSCopying>) key
  {
  if(object != nil)
    self.dictionary[key] = object;
  }

// Bind an NSNumber value to a key.
- (void) setNumber: (NSNumber *) value
  forKey: (NSString *) key
  {
  if([value respondsToSelector: @selector(longLongValue)])
    self.dictionary[key] = value;
  else if([value respondsToSelector: @selector(UTF8String)])
    {
    NSNumber * number =
      [[NumberFormatter sharedNumberFormatter]
        convertFromString: (NSString *)value];
    
    if(number != nil)
      self.dictionary[key] = number;
    }
  }

// Use array subscripting to bind an object value to a key.
- (void) setObject: (id) object forKeyedSubscript: (id<NSCopying>) key
  {
  if(object != nil)
    self.dictionary[key] = object;
  }

@end
