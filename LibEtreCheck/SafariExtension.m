/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "SafariExtension.h"
#import "SubProcess.h"
#import "Utilities.h"

// Wrapper around a Safari extension.
@implementation SafariExtension

// Source path.
@synthesize path = myPath;

// Name.
@synthesize name = myName;

// Display name.
@synthesize displayName = myDisplayName;

// Identifier.
@synthesize identifier = myIdentifier;

// Loaded status.
@synthesize loaded = myLoaded;

// Enabled status.
@synthesize enabled = myEnabled;

// Developer name.
@synthesize developerName = myDeveloperName;

// Developer web site.
@synthesize developerWebSite = myDeveloperWebSite;

// Constructor with path to extension.
- (nullable instancetype) initWithPath: (nonnull NSString *) path
  {
  if(path.length > 0)
    {
    NSDictionary * dict = [SafariExtension readFromPath: path];
    
    if(dict != nil)
      {
      self = [super init];
      
      self.path = path;
      
      [self parseName];
      
      [self parseDictionary: dict];
      
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
  self.identifier = nil;
  self.developerName = nil;
  self.developerWebSite = nil;
  
  [super dealloc];
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
  
  self.identifier = [dict objectForKey: @"CFBundleIdentifier"];
  
  if(self.identifier == nil)
    self.identifier = self.name;
    
  self.loaded = NO;
  
  self.developerName = [dict objectForKey: @"Author"];
  self.developerWebSite = [dict objectForKey: @"Website"];
  }

@end
