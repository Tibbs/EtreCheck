/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "LocalizedString.h"
#import "TTTLocalizedPluralString.h"

@implementation LocalizedString

@synthesize bundle = myBundle;
@synthesize queue = myQueue;

// Return the singeton.
+ (nonnull LocalizedString *) shared
  {
  static LocalizedString * localizedString = nil;
  
  static dispatch_once_t onceToken;
  
  dispatch_once(
    & onceToken,
    ^{
      localizedString = [LocalizedString new];
    });
    
  return localizedString;
  }

// Constructor.
- (instancetype) init
  {
  self = [super init];
  
  if(self != nil)
    {
    myBundle = [NSBundle bundleForClass: [LocalizedString class]];
    
    NSString * name = @"LocalizedStringQ";
    
    myQueue = dispatch_queue_create(name.UTF8String, DISPATCH_QUEUE_SERIAL);
    }
    
  return self;
  }
  
// Destructor.
- (void) dealloc
  {
  [myBundle release];
  
  if(self.queue != nil)
    dispatch_release(self.queue);
  
  [super dealloc];
  }
  
// Get a localized string.
// ECLocalizedString isn't thread safe.
- (nonnull NSString *) localizedString: (nonnull NSString *) key
  {
  return [self localizedString: key fromTable: nil];
  }

// Get a localized plural string.
- (nonnull NSString *) localizedPluralString: (nonnull NSString *) key
  count: (NSUInteger) count
  {
  return [self localizedPluralString: key count: count fromTable: nil];
  }
  
// Get a localized string from a table..
// ECLocalizedStringFromTable isn't thread safe.
- (nonnull NSString *) localizedString: (nonnull NSString *) key 
  fromTable: (nullable NSString *) table
  {
  __block NSString * value = nil;
  
  dispatch_sync(
    self.queue, 
    ^{
      value =
        [self.bundle localizedStringForKey: key value: @"" table: table];
    });
    
  return value;
  }

// Get a localized plural string from a table..
- (nonnull NSString *) localizedPluralString: (nonnull NSString *) key 
  count: (NSUInteger) count fromTable: (nullable NSString *) table
  {
  __block NSString * value = nil;
  
  dispatch_sync(
    self.queue, 
    ^{
      value = 
        [NSString 
          stringWithFormat: 
            [self.bundle 
              localizedStringForKey: 
                TTTLocalizedPluralStringKeyForCountAndSingularNoun(
                  count, key) 
              value: @"" 
              table: table], 
            count];
    });
    
  return value;
  }
  
@end

// Convenience functions.
NSString * _Nonnull ECLocalizedString( NSString * _Nonnull key)
  {
  return [[LocalizedString shared] localizedString: key];
  }
  
// Convenience functions.
NSString * _Nonnull  ECLocalizedPluralString(
  NSUInteger count, NSString * _Nonnull key)
  {
  return [[LocalizedString shared] localizedPluralString: key count: count];
  }

NSString * _Nonnull ECLocalizedStringFromTable(
  NSString * _Nonnull key, NSString * _Nullable table)
  {
  return [[LocalizedString shared] localizedString: key fromTable: table];
  }
  
NSString * _Nonnull ECLocalizedPluralStringFromTable(
  NSUInteger count, NSString * _Nonnull key, NSString * _Nullable table)
  {
  return 
    [[LocalizedString shared] 
      localizedPluralString: key count: count fromTable: table];
  }
