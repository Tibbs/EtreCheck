/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "Safari.h"
#import "Model.h"
#import "Utilities.h"
#import "SubProcess.h"
#import "SafariExtension.h"
#import "NSDictionary+Etresoft.h"

// Wrapper around Safari informatino.
@implementation Safari

// Extensions keyed by identifier.
@synthesize extensions = myExtensions;

// Extensions keyed by name.
@synthesize extensionsByName = myExtensionsByName;

// Extensions identified as adware.
@synthesize adwareExtensions = myAdwareExtensions;

// Extensions that are not loaded.
@synthesize orphanExtensions = myOrphanExtensions;

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self != nil)
    {
    myExtensions = [NSMutableDictionary new];
    myExtensionsByName = [NSMutableDictionary new];
    myAdwareExtensions = [NSMutableSet new];
    myOrphanExtensions = [NSMutableSet new];
    }
    
  return self;
  }

// Destructor.
- (void) dealloc
  {
  [myExtensionsByName release];
  [myExtensions release];
  [myAdwareExtensions release];
  [myOrphanExtensions release];
  
  [super dealloc];
  }

// Load safari information.
- (void) load
  {
  // Load from archive files.
  [self loadArchives];
  
  // Load from apps.
  [self loadModernExtensions];
  
  // Find out which ones are enabled.
  [self loadPropertyList];
  }

// Collect extension archives.
- (void) loadArchives
  {
  NSString * userSafariExtensionsDir =
    [NSHomeDirectory()
      stringByAppendingPathComponent: @"Library/Safari/Extensions"];

  NSArray * args =
    @[
      userSafariExtensionsDir,
      @"-iname",
      @"*.safariextz"];

  SubProcess * subProcess = [[SubProcess alloc] init];
  
  if([subProcess execute: @"/usr/bin/find" arguments: args])
    {
    NSArray * paths = [Utilities formatLines: subProcess.standardOutput];
    
    for(NSString * path in paths)
      {
      SafariExtension * extension = 
        [[SafariExtension alloc] initWithPath: path];
      
      [self.extensions setObject: extension forKey: extension.identifier];
      [self.extensionsByName setObject: extension forKey: extension.name];
      
      [extension release];
      }
    }
    
  [subProcess release];
  }

// Collect modern extensions.
- (void) loadModernExtensions
  {
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  BOOL success =
    [subProcess
      execute:
        @"/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister"
      arguments: @[ @"-dump"]];
    
  if(success)
    {
    NSArray * lines = [Utilities formatLines: subProcess.standardOutput];

    BOOL isExtension = NO;
    NSString * name = nil;
    NSString * path = nil;
    NSString * displayName = nil;
    NSString * identifier = nil;
    
    for(NSString * line in lines)
      {
      NSString * trimmedLine =
        [line
          stringByTrimmingCharactersInSet:
            [NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
      if([trimmedLine isEqualToString: @""])
        continue;

      BOOL check =
        [trimmedLine
          isEqualToString:
            @"--------------------------------------------------------------------------------"];
        
      if(check)
        {
        if(displayName && path && identifier && isExtension)
          {
          SafariExtension * extension = [[SafariExtension alloc] init];
          
          extension.path = path;
          extension.name = displayName;
          extension.identifier = identifier;
          extension.authorName = @"Mac App Store";
          
          [self.extensions 
            setObject: extension forKey: extension.identifier];
          
          [self.extensionsByName 
            setObject: extension forKey: extension.name];

          [extension release];
          }

        isExtension = NO;
        displayName = nil;
        identifier = nil;
        name = nil;
        path = nil;
        }
      else if([trimmedLine hasPrefix: @"protocol:"])
        {
        NSString * value = [trimmedLine substringFromIndex: 9];
        
        NSString * protocol =
          [value
            stringByTrimmingCharactersInSet:
              [NSCharacterSet whitespaceAndNewlineCharacterSet]];
          
        if([protocol hasPrefix: @"com.apple.Safari."])
          isExtension = YES;
        }
      else if([trimmedLine hasPrefix: @"displayName:"])
        {
        NSString * value = [trimmedLine substringFromIndex: 12];
        
        displayName =
          [value
            stringByTrimmingCharactersInSet:
              [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        }
      else if([trimmedLine hasPrefix: @"identifier:"])
        {
        NSString * value = [trimmedLine substringFromIndex: 11];
        
        identifier =
          [value
            stringByTrimmingCharactersInSet:
              [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        }
      else if([trimmedLine hasPrefix: @"path:"])
        {
        NSString * value = [trimmedLine substringFromIndex: 5];
        
        path =
          [value
            stringByTrimmingCharactersInSet:
              [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        }
      }
    }
    
  [subProcess release];
  }

// Find out which extensions are enabled.
- (void) loadPropertyList
  {
  NSString * userSafariExtensionsDir =
    [NSHomeDirectory()
      stringByAppendingPathComponent: @"Library/Safari/Extensions"];

  NSString * extensionPlistPath =
    [userSafariExtensionsDir
      stringByAppendingPathComponent: @"Extensions.plist"];

  NSDictionary * settings =
    [NSDictionary readPropertyList: extensionPlistPath];
  
  if(settings)
    {
    NSArray * installedExtensions =
      [settings objectForKey: @"Installed Extensions"];
    
    for(NSDictionary * installedExtension in installedExtensions)
      {
      if(![installedExtension respondsToSelector: @selector(objectForKey:)])
        continue;
        
      NSNumber * enabled = [installedExtension objectForKey: @"Enabled"];
      
      NSString * filename =
        [installedExtension objectForKey: @"Archive File Name"];
        
      NSString * bundleIdentifier =
        [installedExtension objectForKey: @"Bundle Identifier"];
        
      SafariExtension * extension =
        ([bundleIdentifier length] > 0)
          ? [self.extensions objectForKey: bundleIdentifier]
          : [self.extensionsByName objectForKey: filename];
        
      extension.loaded = YES;
      extension.enabled = enabled.boolValue;
      }
    }
  }
  
@end
