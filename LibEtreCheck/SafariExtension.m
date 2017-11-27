/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "SafariExtension.h"
#import "SubProcess.h"
#import "Utilities.h"
#import "XMLBuilder.h"
#import "OSVersion.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "EtreCheckConstants.h"
#import "LocalizedString.h"

// Wrapper around a Safari extension.
@implementation SafariExtension

// Source path.
@synthesize path = myPath;

// Name.
@synthesize name = myName;

// Display name.
@synthesize displayName = myDisplayName;

// Bundle identifier.
@synthesize bundleIdentifier = myBundleIdentifier;

// Loaded status.
@synthesize loaded = myLoaded;

// Enabled status.
@synthesize enabled = myEnabled;

// Developer web site.
@synthesize developerWebSite = myDeveloperWebSite;

// I will need a unique, XML-safe identifier for each launchd file.
@synthesize identifier = myIdentifier;

// Return a unique number.
+ (int) uniqueIdentifier
  {
  static int counter = 0;
  
  dispatch_sync(
    dispatch_get_main_queue(), 
    ^{
      ++counter;
    });
    
  return counter;
  }

// Constructor with path to extension.
- (nullable instancetype) initWithPath: (nonnull NSString *) path
  {
  if(path.length > 0)
    {
    NSDictionary * dict = [SafariExtension readFromPath: path];
    
    if(dict != nil)
      {
      self = [super init];
      
      self.modificationDate = [Utilities modificationDate: path];

      self.path = path;
      
      [self parseName];
      
      [self parseDictionary: dict];
      
      myIdentifier = 
        [[NSString alloc] 
          initWithFormat: 
            @"safariextension%d", [SafariExtension uniqueIdentifier]];
      
      return self;
      }
    }
    
  return nil;
  }
  
// Destructor.
- (void) dealloc
  {
  self.path = nil;
  self.name = nil;
  self.displayName = nil;
  self.bundleIdentifier = nil;
  self.developerWebSite = nil;
  [myIdentifier release];
  
  [super dealloc];
  }
  
// Is this a Safari extension?
- (BOOL) isSafariExtension
  {
  return YES;
  }
  
// Extract a Safari extension from a path.
+ (NSDictionary *) readFromPath: (NSString *) path
  {
  NSString * tempDirectory =
    [self extractExtensionArchive: [path stringByResolvingSymlinksInPath]];

  NSDictionary * plist = [self findExtensionPlist: tempDirectory];
    
  [[NSFileManager defaultManager]
    removeItemAtPath: tempDirectory error: NULL];
    
  return plist;
  }

+ (NSString *) extractExtensionArchive: (NSString *) path
  {
  NSString * resolvedPath = [path stringByResolvingSymlinksInPath];
  
  NSString * tempDirectory = [Utilities createTemporaryDirectory];
  
  [[NSFileManager defaultManager]
    createDirectoryAtPath: tempDirectory
    withIntermediateDirectories: YES
    attributes: nil
    error: NULL];
  
  NSArray * args =
    @[
      @"-zxf",
      resolvedPath,
      @"-C",
      tempDirectory
    ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  [subProcess execute: @"/usr/bin/xar" arguments: args];
    
  [subProcess release];
  
  return tempDirectory;
  }
  
+ (NSDictionary *) findExtensionPlist: (NSString *) directory
  {
  NSArray * args =
    @[
      directory,
      @"-name",
      @"Info.plist"
    ];
    
  NSDictionary * plist = nil;
    
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  if([subProcess execute: @"/usr/bin/find" arguments: args])
    {
    NSString * infoPlistPathString =
      [[NSString alloc]
        initWithData: subProcess.standardOutput
        encoding: NSUTF8StringEncoding];
    
    NSString * infoPlistPath =
      [infoPlistPathString stringByTrimmingCharactersInSet:
          [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    [infoPlistPathString release];
  
    NSData * data = [[NSData alloc] initWithContentsOfFile: infoPlistPath];
    
    if(data.length > 0)
      {
      NSError * error;
      NSPropertyListFormat format;
      
      plist =
        [NSPropertyListSerialization
          propertyListWithData: data
          options: NSPropertyListImmutable
          format: & format
          error: & error];
      }
      
    [data release];
    }
    
  [subProcess release];
      
  return plist;
  }

// Get the extension name, less the uniquifier.
- (void) parseName
  {
  NSString * name =
    [[self.path lastPathComponent] stringByDeletingPathExtension];
    
  NSMutableArray * parts =
    [NSMutableArray
      arrayWithArray: [name componentsSeparatedByString: @"-"]];
    
  if([parts count] > 1)
    if([[parts lastObject] integerValue] > 1)
      [parts removeLastObject];
    
  self.name = 
    [[parts componentsJoinedByString: @"-"] 
      stringByAppendingPathExtension: @"safariextz"];
  }

// Create an extension dictionary from a plist.
- (void) parseDictionary: (NSDictionary *) dict
  {
  self.displayName = [dict objectForKey: @"CFBundleDisplayName"];
  
  self.bundleIdentifier = [dict objectForKey: @"CFBundleIdentifier"];
  
  if(self.bundleIdentifier == nil)
    self.bundleIdentifier = self.name;
    
  self.loaded = NO;
  
  self.authorName = [dict objectForKey: @"Author"];
  self.developerWebSite = [dict objectForKey: @"Website"];
  }

// Build the attributedString value.
- (void) buildAttributedStringValue: 
  (NSMutableAttributedString *) attributedString
  {
  // Print the status.
  [self appendStatus: attributedString];
  
  // Print the name.
  [attributedString appendString: self.displayName];
  
  // Print the signature.
  [self appendSignature: attributedString];
  
  // Add the modification date.
  [self appendModificationDate: attributedString];
  }
  
// Format a status string.
- (void) appendStatus: (NSMutableAttributedString *) attributedString
  {
  if([[OSVersion shared] major] == kYosemite)
    [attributedString appendString: @"    "];
  else
    {
    NSString * statusString = nil;
    
    NSColor * color = nil;
    
    if(!self.loaded)
      {
      statusString = ECLocalizedString(@"not loaded");
      color = [[Utilities shared] gray];
      }
    else if(self.enabled)
      {
      statusString = ECLocalizedString(@"enabled");
      color = [[Utilities shared] green];
      }
    else 
      {
      statusString = ECLocalizedString(@"disabled");
      color = [[Utilities shared] gray];
      }
    
    [attributedString
      appendString: 
        [NSString stringWithFormat: @"    [%@]    ", statusString]
      attributes:
        @{
          NSForegroundColorAttributeName : color,
          NSFontAttributeName : [[Utilities shared] boldFont]
        }];
    }
  }

// Print extension details
- (void) appendSignature: (NSMutableAttributedString *) attributedString
  {
  if(self.authorName.length > 0)
    [attributedString
      appendString:
        [NSString stringWithFormat: @" - %@", self.authorName]];
  
  if(self.developerWebSite.length > 0)
    {
    [attributedString appendString: @" - "];
    
    [attributedString
      appendString: self.developerWebSite
      attributes:
        @{
          NSFontAttributeName : [[Utilities shared] boldFont],
          NSForegroundColorAttributeName : [[Utilities shared] blue],
          NSLinkAttributeName : self.developerWebSite
        }];
    }
  }

// Append the modification date.
- (void) appendModificationDate: 
  (NSMutableAttributedString *) attributedString
  {
  if(self.modificationDate)
    {
    NSString * modificationDateString =
      [Utilities installDateAsString: self.modificationDate];
    
    if(modificationDateString.length > 0)
      [attributedString
        appendString:
          [NSString stringWithFormat: @" (%@)", modificationDateString]];
    }
  }

// Build the XML value.
- (void) buildXMLValue: (XMLBuilder *) xml
  {
  [xml startElement: @"extension"];

  [xml addElement: @"identifier" value: self.identifier];
  [xml addElement: @"name" value: self.name];
  [xml addElement: @"displayname" value: self.displayName];
  [xml addElement: @"developer" value: self.authorName];
  [xml addElement: @"url" value: self.developerWebSite];
  
  [xml addElement: @"installdate" date: self.modificationDate];
  
  if(!self.loaded)
    [xml addElement: @"status" value: @"notloaded"];
    
  else if(self.enabled)
    [xml addElement: @"status" value: @"enabled"];
    
  else 
    [xml addElement: @"status" value: @"disabled"];

  [xml endElement: @"extension"];
  }
  
@end
