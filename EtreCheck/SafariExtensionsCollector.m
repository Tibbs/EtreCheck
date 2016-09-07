/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "SafariExtensionsCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Model.h"
#import "Utilities.h"
#import "SubProcess.h"

#define kIdentifier @"identifier"
#define kHumanReadableName @"humanreadablename"
#define kFileName @"filename"
#define kArchivePath @"archivepath"
#define kCachePath @"cachepath"
#define kAuthor @"Author"
#define kWebsite @"Website"

// Collect Safari extensions.
@implementation SafariExtensionsCollector

@synthesize extensions = myExtensions;

// Constructor.
- (id) init
  {
  self = [super initWithName: @"safariextensions"];
  
  if(self)
    {
    myExtensions = [NSMutableDictionary new];

    return self;
    }
    
  return nil;
  }

// Destructor.
- (void) dealloc
  {
  self.extensions = nil;
  
  [super dealloc];
  }

// Perform the collection.
- (void) collect
  {
  [self
    updateStatus: NSLocalizedString(@"Checking Safari extensions", NULL)];

  [self collectArchives];
  [self collectCaches];

  // Print the extensions.
  if([self.extensions count])
    {
    [self.result appendAttributedString: [self buildTitle]];

    // There could be a situation where cached-only, non-adware extensions
    // show up as valid extensions but aren't printed.
    int count = 0;
    
    for(NSString * name in self.extensions)
      if([self printExtension: [self.extensions objectForKey: name]])
        ++count;
    
    if(!count)
      [self.result appendString: NSLocalizedString(@"    None\n", NULL)];
    
    [self.result appendCR];
    }

  dispatch_semaphore_signal(self.complete);
  }

// Collect extension archives.
- (void) collectArchives
  {
  // TODO: Does not work in sandbox.
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
      NSString * name = [self extensionName: path];
        
      NSDictionary * plist = [self readSafariExtensionPropertyList: path];

      NSMutableDictionary * extension =
        [self createExtensionsFromPlist: plist name: name path: path];
        
      [extension setObject: path forKey: kArchivePath];
      }
    }
    
  [subProcess release];
  }

// Collect extension caches.
- (void) collectCaches
  {
  // TODO: Does not work in sandbox.
  NSString * userSafariExtensionsDir =
    [NSHomeDirectory()
      stringByAppendingPathComponent:
        @"Library/Caches/com.apple.Safari/Extensions"];

  NSArray * args =
    @[
      userSafariExtensionsDir,
      @"-iname",
      @"*.safariextension"];

  SubProcess * subProcess = [[SubProcess alloc] init];
  
  if([subProcess execute: @"/usr/bin/find" arguments: args])
    {
    NSArray * paths = [Utilities formatLines: subProcess.standardOutput];

    for(NSString * path in paths)
      {
      NSString * name = [self extensionName: path];
        
      NSDictionary * plist = [self findExtensionPlist: path];

      NSMutableDictionary * extension =
        [self createExtensionsFromPlist: plist name: name path: path];
        
      [extension setObject: path forKey: kCachePath];
      }
    }
    
  [subProcess release];
  }

// Get the extension name, less the uniquifier.
- (NSString *) extensionName: (NSString *) path
  {
  if(!path)
    return nil;
    
  NSString * name =
    [[path lastPathComponent] stringByDeletingPathExtension];
    
  NSMutableArray * parts =
    [NSMutableArray
      arrayWithArray: [name componentsSeparatedByString: @"-"]];
    
  if([parts count] > 1)
    if([[parts lastObject] integerValue] > 1)
      [parts removeLastObject];
    
  return [parts componentsJoinedByString: @"-"];
  }

// Create an extension dictionary from a plist.
- (NSMutableDictionary *) createExtensionsFromPlist: (NSDictionary *) plist
  name: (NSString *) name path: (NSString *) path
  {
  NSString * humanReadableName =
    [plist objectForKey: @"CFBundleDisplayName"];
  
  if(!humanReadableName)
    humanReadableName = name;
    
  NSString * identifier = [plist objectForKey: @"CFBundleIdentifier"];
  
  if(!identifier)
    identifier = name;
    
  NSMutableDictionary * extension = [self.extensions objectForKey: name];
  
  if(!extension)
    {
    extension = [NSMutableDictionary dictionary];
    
    [self.extensions setObject: extension forKey: name];
    }
    
  [extension setObject: humanReadableName forKey: kHumanReadableName];
  [extension setObject: identifier forKey: kIdentifier];
  [extension setObject: name forKey: kFileName];
  
  NSString * author = [plist objectForKey: kAuthor];

  if([author length] > 0)
    [extension setObject: author forKey: kAuthor];
    
  NSString * website = [plist objectForKey: kWebsite];

  if([website length] > 0)
    [extension setObject: website forKey: kWebsite];
  
  if(([author length] == 0) && ([website length] == 0))
    [[[Model model] unknownFiles] addObject: path];

  return extension;
  }

// Print a Safari extension.
- (bool) printExtension: (NSDictionary *) extension
  {
  NSString * humanReadableName =
    [extension objectForKey: kHumanReadableName];
  
  NSString * archivePath = [extension objectForKey: kArchivePath];
  NSString * cachePath = [extension objectForKey: kCachePath];
  
  bool adware = NO;
  
  if([[Model model] isAdwareExtension: humanReadableName path: archivePath])
    adware = YES;
  
  if([[Model model] isAdwareExtension: humanReadableName path: cachePath])
    adware = YES;

  bool adwareNameArchive =
    [[Model model]
      isAdwareExtension: [extension objectForKey: kFileName ]
      path: archivePath];
   
  bool adwareNameCache =
    [[Model model]
      isAdwareExtension: [extension objectForKey: kFileName ]
      path: cachePath];

  if(adwareNameArchive || adwareNameCache)
    adware = true;
    
  // Ignore a cached extension unless it is adware.
  if(([archivePath length] > 0) || adware)
    {
    [self printExtensionDetails: extension];
    
    if(([archivePath length] == 0) && ([cachePath length] > 0))
      [self.result appendString: NSLocalizedString(@" (cache only)", NULL)];
      
    [self appendModificationDate: extension];
    
    if(adware)
      {
      [self.result appendString: @" "];
      
      // Add this adware extension under the "extension" category so only it
      // will be printed.
      NSMutableDictionary * info = [NSMutableDictionary new];
      
      [info setObject: @"extension" forKey: kAdwareType];
      
      if(archivePath)
        [[[Model model] adwareFiles]
          setObject: info forKey: archivePath];
      
      if(cachePath)
        [[[Model model] adwareFiles]
          setObject: info forKey: cachePath];

      [info release];
      
      [[Model model] setAdwareFound: YES];

      [self.result
        appendString: NSLocalizedString(@"Adware!", NULL)
        attributes:
          @{
            NSForegroundColorAttributeName : [[Utilities shared] red],
            NSFontAttributeName : [[Utilities shared] boldFont]
          }];
        
      NSAttributedString * removeLink = [self generateRemoveAdwareLink];

      if(removeLink)
        {
        [self.result appendString: @" "];
        
        [self.result appendAttributedString: removeLink];
        }
      }

    [self.result appendString: @"\n"];
    
    return YES;
    }
    
  return NO;
  }

// Print extension details
- (void) printExtensionDetails: (NSDictionary *) extension
  {
  NSString * humanReadableName =
    [extension objectForKey: kHumanReadableName];

  NSString * author = [extension objectForKey: kAuthor];

  NSString * website = [extension objectForKey: kWebsite];

  [self.result
    appendString:
      [NSString stringWithFormat: @"    %@", humanReadableName]];
    
  if([author length] > 0)
    [self.result
      appendString:
        [NSString stringWithFormat: @" - %@", author]];
  
  if([website length] > 0)
    {
    [self.result appendString: @" - "];
    
    [self.result
      appendString: website
      attributes:
        @{
          NSFontAttributeName : [[Utilities shared] boldFont],
          NSForegroundColorAttributeName : [[Utilities shared] blue],
          NSLinkAttributeName : website
        }];
    }
  }

// Append the modification date.
- (void) appendModificationDate: (NSDictionary *) extension
  {
  NSDate * modificationDate =
    [Utilities modificationDate: [extension objectForKey: kArchivePath]];
    
  if(!modificationDate)
    modificationDate =
      [Utilities modificationDate: [extension objectForKey: kCachePath]];

  if(modificationDate)
    {
    NSString * modificationDateString =
      [Utilities dateAsString: modificationDate format: @"yyyy-MM-dd"];
    
    if(modificationDateString)
      [self.result
        appendString:
          [NSString stringWithFormat: @" (%@)", modificationDateString]];
    }
  }

// Read the extension plist dictionary.
- (NSDictionary *) extensionInfoPList: (NSString *) extensionName
  {
  // TODO:  Does not work in sandbox?
  NSString * userSafariExtensionsDir =
    [NSHomeDirectory()
      stringByAppendingPathComponent: @"Library/Safari/Extensions"];

  NSString * extensionPath =
    [userSafariExtensionsDir stringByAppendingPathComponent: extensionName];
  
  return
    [self
      readSafariExtensionPropertyList:
        [extensionPath stringByAppendingPathExtension: @"safariextz"]];
  }

// Read a property list from a Safari extension.
- (id) readSafariExtensionPropertyList: (NSString *) path
  {
  NSString * tempDirectory =
    [self extractExtensionArchive: [path stringByResolvingSymlinksInPath]];

  NSDictionary * plist = [self findExtensionPlist: tempDirectory];
    
  [[NSFileManager defaultManager]
    removeItemAtPath: tempDirectory error: NULL];
    
  return plist;
  }

- (NSString *) extractExtensionArchive: (NSString *) path
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

- (NSDictionary *) findExtensionPlist: (NSString *) directory
  {
  NSArray * args =
    @[
      directory,
      @"-name",
      @"Info.plist"
    ];
    
  NSDictionary * plist = nil;
    
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  [subProcess autorelease];
  
  if([subProcess execute: @"/usr/bin/find" arguments: args])
    {
    NSString * infoPlistPathString =
      [[NSString alloc]
        initWithData: subProcess.standardOutput
        encoding: NSUTF8StringEncoding];
    
    NSString * infoPlistPath =
      [infoPlistPathString stringByTrimmingCharactersInSet:
          [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    subProcess = [[SubProcess alloc] init];
    
    if([subProcess execute: @"/bin/cat" arguments: @[infoPlistPath]])
      {
      if(subProcess.standardOutput)
        {
        NSError * error;
        NSPropertyListFormat format;
        
        plist =
          [NSPropertyListSerialization
            propertyListWithData: subProcess.standardOutput
            options: NSPropertyListImmutable
            format: & format
            error: & error];
        }
      }
      
    [infoPlistPathString release];
    
    [subProcess release];
    }
        
  return plist;
  }

@end
