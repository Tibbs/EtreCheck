/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

@interface Actions : NSObject

// Turn on Gatekeeper.
+ (void) enableGatekeeper;

// Restart the machine.
+ (BOOL) restart;

// Trash files.
+ (void) trashFiles: (NSArray *) files;

// Reveal a file in the Finder.
+ (void) revealFile: (NSString *) file;

@end
