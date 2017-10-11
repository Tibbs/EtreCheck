/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "PrintableItem.h"

// A wrapper around a launchd task.
@interface LaunchdTask : PrintableItem
  {
  // Path to the config script.
  NSString * myPath;
  
  // The launchd label.
  NSString * myLabel;
  
  // The executable or script.
  NSString * myExecutable;
  
  // The arguments.
  NSArray * myArguments;
  }

// Path to the config script.
@property (strong, nullable) NSString * path;

// The launchd label.
@property (readonly, nullable) NSString * label;

// The executable or script.
@property (readonly, nullable) NSString * executable;

// The arguments.
@property (readonly, nullable) NSArray * arguments;

// Constructor with NSDictionary (via ServiceManagement).
- (nullable instancetype) initWithDictionary: (nonnull NSDictionary *) dict;

// Constructor with label and NSData (via launchctl).
- (nullable instancetype) initWithLabel: (nonnull NSString *) label
  data: (nonnull NSData *) data;

@end
