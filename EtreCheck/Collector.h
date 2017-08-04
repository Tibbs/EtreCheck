/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014-2017. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

@class XMLBuilder;

// Base class for all collector activities. Also has values like current
// OS version that may be needed by all collectors.
@interface Collector : NSObject
  {
  NSString * myName;
  NSString * myTitle;
  NSMutableAttributedString * myResult;
  NSNumberFormatter * myFormatter;
  dispatch_semaphore_t myComplete;
  XMLBuilder * myModel;
  }

// The name of this collector.
@property (retain) NSString * name;

// The title for this collector.
@property (retain) NSString * title;

// Keep track of the results of this collector.
@property (retain) NSMutableAttributedString * result;

// Allow people to know when a collection is complete.
@property (assign) dispatch_semaphore_t complete;
@property (readonly) bool done;

@property (readonly) XMLBuilder * model;

// Constructor.
- (instancetype) initWithName: (NSString *) name;

// Perform the collection.
- (void) collect;

// Simulate a collection.
- (void) simulate;

// Perform the collection.
- (void) performCollect;

// Update status.
- (void) updateStatus: (NSString *) status;

// Construct a title with a bold, blue font using a given anchor into
// the online help.
- (NSAttributedString *) buildTitle;
  
// Convert a program name and optional bundle ID into a DNS-style URL.
- (NSAttributedString *) getSupportURL: (NSString *) name
  bundleID: (NSString *) path;

// Get a support link from a bundle.
- (NSAttributedString *) getSupportLink: (NSDictionary *) bundle;

// Extract the (possible) host from a bundle ID.
- (NSString *) convertBundleIdToHost: (NSString *) bundleID;

// Try to determine the OS version associated with a bundle.
- (NSString *) getOSVersion: (NSDictionary *) info age: (int *) age;

// Find the maximum of two version number strings.
- (NSString *) maxVersion: (NSArray *) versions;

// Generate a "remove adware" link.
- (NSAttributedString *) generateRemoveAdwareLink;

@end
