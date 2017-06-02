/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

@interface CollectorModel : NSObject
  {
  NSMutableDictionary * myDictionary;
  }

// Get a BOOL value for a key.
- (BOOL) boolValueForKey: (NSString *) key;

// Get an NSInteger value for a key.
- (NSInteger) integerForKey: (NSString *) key;

// Get an NSUInteger value for a key.
- (NSUInteger) unsignedIntegerForKey: (NSString *) key;

// Get a long long value for a key.
- (long long) longlongForKey: (NSString *) key;

// Get a double value for a key.
- (double) doubleForKey: (NSString *) key;

// Get an NSString value for a key.
- (NSString *) stringForKey: (NSString *) key;

// Get an NSData value for a key.
- (NSData *) dataForKey: (NSString *) key;

// Get an NSDate value for a key.
- (NSDate *) dateForKey: (NSString *) key;

// Get an NSURL value for a key.
- (NSURL *) urlForKey: (NSString *) key;

// Get an NSObject value for a key.
- (NSObject *) valueForKey: (id<NSCopying>) key;

// Get an NSNumber value for a key.
- (NSNumber *) numberForKey: (NSString *) key;

// Get an NSObject value using array subscripting.
- (NSObject *) valueForKeyedSubscript: (id<NSCopying>) key;

// Bind an NSNull value to a key.
- (void) setNullForKey: (NSString *) key;

// Bind a BOOL value to a key.
- (void) setBoolean: (BOOL) value forKey: (NSString *) key;

// Bind an NSInteger to a key.
- (void) setInteger: (NSInteger) value forKey: (NSString *) key;

// Bind an NSUInteger value to key.
- (void) setUnsignedInteger: (NSUInteger) value forKey: (NSString *) key;

// Bind a long long value to a key.
- (void) setLongLong: (long long) value forKey: (NSString *) key;

// Bind a double value to a key.
- (void) setDouble: (double) value forKey: (NSString *) key;

// Bind an NSString value to a key.
- (void) setString: (NSString *) value forKey: (NSString *) key;

// Bind an NSData value to a key
- (void) setData: (NSData *) value forKey: (NSString *) key;

// Bind an NSDate value to a key.
- (void) setDate: (NSDate *) value forKey: (NSString *) key;

// Bind an NSURL value to a key.
- (void) setURL: (NSURL *) value forKey: (NSString *) key;

// Bind an object value to a key.
- (void) setObject: (id) object forKey: (id<NSCopying>) key;

// Bind an NSNumber value to a key.
- (void) setNumber: (NSNumber *) value forKey: (NSString *) key;

// Use array subscripting to bind an object value to a key.
- (void) setObject: (id) object forKeyedSubscript: (id<NSCopying>) key;

@end
