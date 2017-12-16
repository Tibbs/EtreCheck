/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014-2017. All rights reserved.
 **********************************************************************/

#import "UnsignedCollector.h"
#import "Model.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"
#import "LaunchdCollector.h"
#import "XMLBuilder.h"
#import "EtreCheckConstants.h"
#import "LocalizedString.h"
#import "Launchd.h"
#import "LaunchdFile.h"
#import "Adware.h"
#import "NSDictionary+Etresoft.h"
#import "NSString+Etresoft.h"

#define kWhitelistKey @"whitelist"
#define kWhitelistPrefixKey @"whitelist_prefix"
#define kAdwareExtensionsKey @"adwareextensions"
#define kBlacklistKey @"blacklist"
#define kBlacklistSuffixKey @"blacklist_suffix"
#define kBlacklistMatchKey @"blacklist_match"

// Collect information about unsigned files.
@implementation UnsignedCollector

// Constructor.
- (id) init
  {
  self = [super initWithName: @"unsigned"];
  
  if(self != nil)
    {
    }
    
  return self;
  }

// Print any unsigned files found.
- (void) performCollect
  {
  [self collectUnsignedFiles];
  
  [self printUnsignedFiles];
  [self exportUnsignedFiles];
  }
  
// Collect unsigned files. 
- (void) collectUnsignedFiles
  {
  Launchd * launchd = [self.model launchd];
  
  // I will have already filtered out launchd files specific to this 
  // context.
  for(NSString * path in [launchd filesByPath])
    {
    LaunchdFile * file = [[launchd filesByPath] objectForKey: path];
    
    if([LaunchdFile isValid: file])
      [self checkUnsigned: file];
    }
  }
  
// Build a database of legitimate prefixes.
- (void) buildLegitimatePrefixes
  {
  // Build a list of whitelist prefixes. 
  /* NSMutableSet * whitelistFiles = [[self.model adware] whitelistFiles];
  NSMutableSet * legitimateStrings = [NSMutableSet new];
  
  for(NSString * file in whitelistFiles)
    {
    NSString * prefix = [Utilities bundleName: file];
    
    if(prefix.length > 0)
      [legitimateStrings addObject: prefix]; 
    } */
  }
  
// Check for an unsigned file.
- (void) checkUnsigned: (LaunchdFile *) file
  {
  if([file.signature isEqualToString: kSignatureApple])
    return;
    
  if([file.signature isEqualToString: kSignatureValid])
    return;
  
  // If it is already adware, skip it here.
  if(file.adware)
    return;
    
  [[[self.model launchd] unsignedFiles] addObject: file];
  }
  
// Print unsigned files.
- (void) printUnsignedFiles
  {
  if([self.model launchd].unsignedFiles.count == 0)
    return;
    
  [self.result appendAttributedString: [self buildTitle]];
  
  for(LaunchdFile * launchdFile in [[self.model launchd] unsignedFiles])
    {
    if([self hideFile: launchdFile])
      continue;
      
    // Print the file.
    [self.result appendString: @"    "];
    [self.result appendString: launchdFile.path];
    [self.result appendString: @" "];

    if([launchdFile.status isEqualToString: kStatusNotLoaded])
      {
      NSAttributedString * enableLink = 
        [self generateEnableLink: launchdFile.path];

      if(enableLink)
        [self.result appendAttributedString: enableLink];
      }
      
    else
      {
      NSAttributedString * disableLink = 
        [self generateDisableLink: launchdFile.path];

      if(disableLink)
        [self.result appendAttributedString: disableLink];
      }
      
    if(launchdFile.executable.length > 0)
      {
      [self.result appendString: @"\n        "];
      [self.result 
        appendString: [self cleanPath: launchdFile.executable]];
      }

    [self.result appendString: @"\n"];
    }
    
  [self.result appendCR];
  }
  
// Should this file be hidden?
- (BOOL) hideFile: (LaunchdFile *) file
  {
  Launchd * launchd = [self.model launchd];
  
  NSDictionary * appleFile = [launchd.appleFiles objectForKey: file.path];
  
  if([NSDictionary isValid: appleFile])
    {
    NSString * expectedSignature = [appleFile objectForKey: kSignature];
    
    if([NSString isValid: expectedSignature])
      if([file.signature isEqualToString: expectedSignature])
        return [self.model ignoreKnownAppleFailures];
    }
    
  return NO;
  }
  
// Export unsigned files.
- (void) exportUnsignedFiles
  {
  if([self.model launchd].unsignedFiles.count == 0)
    return;

  [self.xml startElement: @"launchdfiles"];
  
  for(LaunchdFile * launchdFile in [[self.model launchd] unsignedFiles])

    // Export the XML.
    [self.xml addFragment: launchdFile.xml];
  
  [self.xml endElement: @"launchdfiles"];
  }

// Generate a "disable" link.
- (NSAttributedString *) generateDisableLink: (NSString *) path
  {
  NSMutableAttributedString * urlString =
    [[NSMutableAttributedString alloc] initWithString: @""];
    
  [urlString appendString: @" "];
  
  NSString * encodedPath = 
    [path stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
  
  NSString * url = 
    [NSString 
      stringWithFormat: @"etrecheck://unsigned/disable?%@", encodedPath];

  [urlString
    appendString: ECLocalizedString(@"[Disable]")
    attributes:
      @{
        NSFontAttributeName : [[Utilities shared] boldFont],
        NSLinkAttributeName : url
      }];
    
  return [urlString autorelease];
  }

// Generate an "enable" link.
- (NSAttributedString *) generateEnableLink: (NSString *) path
  {
  NSMutableAttributedString * urlString =
    [[NSMutableAttributedString alloc] initWithString: @""];
    
  [urlString appendString: @" "];
  
  NSString * encodedPath = 
    [path stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
  
  NSString * url = 
    [NSString 
      stringWithFormat: @"etrecheck://unsigned/enable?%@", encodedPath];
  
  [urlString
    appendString: ECLocalizedString(@"[Enable]")
    attributes:
      @{
        NSFontAttributeName : [[Utilities shared] boldFont],
        NSLinkAttributeName : url
      }];
    
  return [urlString autorelease];
  }

@end
