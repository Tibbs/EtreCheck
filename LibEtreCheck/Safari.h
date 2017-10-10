/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

// Wrapper around Safari information.
@interface Safari : NSObject
  {
  NSMutableDictionary * myExtensions;
  NSMutableDictionary * myExtensionsByName;
  }

// Key is extension idenifier.
@property (retain) NSMutableDictionary * extensions;

// Key is extension name.
@property (retain) NSMutableDictionary * extensionsByName;

// Load safari information.
- (void) load;

@end
