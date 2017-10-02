/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

@interface LocalizedString : NSObject
  {
  NSBundle * myBundle;
  dispatch_queue_t myQueue;
  }
  
// Return the singeton.
+ (nonnull LocalizedString *) shared;

// The framework bundle.
@property (readonly, nonnull) NSBundle * bundle;

// The queue.
@property (readonly, nonnull) dispatch_queue_t queue;

// Get a localized string.
- (nonnull NSString *) localizedString: (nonnull NSString *) key;

// Get a localized plural string.
- (nonnull NSString *) localizedPluralString: (nonnull NSString *) key
  count: (NSUInteger) count;

// Get a localized string from a table..
- (nonnull NSString *) localizedString: (nonnull NSString *) key 
  fromTable: (nullable NSString *) table;

// Get a localized plural string from a table..
- (nonnull NSString *) localizedPluralString: (nonnull NSString *) key 
  count: (NSUInteger) count fromTable: (nullable NSString *) table;

@end

// Convenience functions.
NSString * _Nonnull  ECLocalizedString(NSString * _Nonnull key);
  
// Convenience functions.
NSString * _Nonnull  ECLocalizedPluralString(
  NSUInteger count, NSString * _Nonnull key);

NSString * _Nonnull ECLocalizedStringFromTable(
  NSString * _Nonnull key, NSString * _Nullable table);

NSString * _Nonnull ECLocalizedPluralStringFromTable(
  NSUInteger count, NSString * _Nonnull key, NSString * _Nullable table);
