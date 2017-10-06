/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "LaunchdFile.h"
#import "OSVersion.h"
#import "SubProcess.h"
#import "EtreCheckConstants.h"
#import "NSDictionary+Etresoft.h"

// A wrapper around a launchd task.
@interface LaunchdTask ()

// Parse a dictionary.
- (void) parseDictionary: (NSDictionary *) dict;

@end

// A wrapper around a launchd config file.
@implementation LaunchdFile

// The config script contents.
@synthesize plist = myPlist;

// Is the config script valid?
@synthesize configScriptValid = myConfigScriptValid;

// The launchd context.
@synthesize context = myContext;

// Loaded tasks.
@synthesize loadedTasks = myLoadedTasks;

// Constructor with path.
- (nullable instancetype) initWithPath: (nonnull NSString *) path
  {
  if(path.length > 0)
    {
    self = [super init];
    
    if(self != nil)
      {
      myLoadedTasks = [NSMutableArray new];
      
      [self parseFromPath: path];

      [self findContext];  
      }
    }
    
  return self;
  }
  
// Destructor.
- (void) dealloc
  {
  [myContext release];
  [myPlist release];
  [myLoadedTasks release];
  
  [super dealloc];
  }
    
// Parse from a path.
- (void) parseFromPath: (nonnull NSString *) path 
  {
  self.path = [path stringByAbbreviatingWithTildeInPath];
  myPlist = [[NSDictionary readPropertyList: path] retain];
  
  if(self.plist.count > 0)
    [super parseDictionary: self.plist];
    
  myConfigScriptValid = (self.label.length > 0);
  }

// Load a launchd task.
- (void) load
  {
  SubProcess * launchctl = [[SubProcess alloc] init];
  
  NSArray * arguments = 
    [[NSArray alloc] initWithObjects: @"load", @"-wF", self.path, nil];
    
  [launchctl execute: @"/bin/launchctl" arguments: arguments];
    
  [arguments release];
  [launchctl release];
  }

// Unload a launchd task.
- (void) unload
  {
  SubProcess * launchctl = [[SubProcess alloc] init];
  
  NSArray * arguments = 
    [[NSArray alloc] initWithObjects: @"unload", @"-wF", self.path, nil];
    
  [launchctl execute: @"/bin/launchctl" arguments: arguments];
    
  [arguments release];
  [launchctl release];
  }

#pragma mark - Context

// Find the context based on the path.
- (void) findContext
  {
  if([self.path hasPrefix: @"/System/Library/"])
    myContext = kLaunchdAppleContext;
  else if([self.path hasPrefix: @"/Library/"])
    myContext = kLaunchdSystemContext;
  else if([self.path hasPrefix: @"~/Library/"])
    myContext = kLaunchdUserContext;
  else
    {
    NSString * libraryPath = 
      [NSHomeDirectory() stringByAppendingPathComponent: @"Library"];
      
    if([self.path hasPrefix: libraryPath])
      myContext = kLaunchdUserContext;
    else 
      myContext = kLaunchdUnknownContext;
    }
  }
  
@end
