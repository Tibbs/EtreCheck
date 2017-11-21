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
  
  // Score unsigned files.
  [self calculateSafetyScores];
  
  [self printUnsignedFiles];
  [self exportUnsignedFiles];
  }
  
// Collect unsigned files. 
- (void) collectUnsignedFiles
  {
  Launchd * launchd = [[Model model] launchd];
  
  // I will have already filtered out launchd files specific to this 
  // context.
  for(NSString * path in [launchd filesByPath])
    {
    LaunchdFile * file = [[launchd filesByPath] objectForKey: path];
    
    if(file != nil)
      [self checkUnsigned: file];
    }
  }
  
// Calculate safety scores for all unsigned files.
- (void) calculateSafetyScores
  {
  // Build a list of whitelist prefixes. 
  NSMutableSet * whitelistFiles = [[[Model model] adware] whitelistFiles];
  NSMutableSet * legitimateStrings = [NSMutableSet new];
  
  for(NSString * file in whitelistFiles)
    {
    NSString * prefix = [Utilities bundleName: file];
    
    if(prefix.length > 0)
      [legitimateStrings addObject: prefix];
    }

  for(LaunchdFile * file in [[[Model model] launchd] unsignedFiles])
    {
    NSDictionary * appleFile = 
      [[[[Model model] launchd] appleFiles] objectForKey: file.path];
      
    if(appleFile != nil)
      {
      NSString * signature = [appleFile objectForKey: @"signature"];
      
      if([file.signature isEqualToString: signature])
        {
        file.safetyScore = 100;
        continue;
        }
      }
      
    // If this is a full whitelist match, add 60.
    if([whitelistFiles containsObject: file.path.lastPathComponent])
      file.safetyScore = file.safetyScore += 60;
    
    // If this is a prefix match only, add 40.
    else
      {
      NSString * prefix = 
        [Utilities bundleName: file.path.lastPathComponent];
    
      if(prefix.length > 0)
        if([legitimateStrings containsObject: prefix])
          file.safetyScore = file.safetyScore += 40;
      }
    
    // If there are lots of command-line arguments, decrease the safety
    // score by 10.
    int argumentSize = 0;
      
    for(NSString * argument in file.arguments)  
      argumentSize += argument.length;
      
    if(argumentSize > 40)
      file.safetyScore = file.safetyScore -= 20;
    }
      
  [legitimateStrings release];
  }
  
// Check for an unsigned file.
- (void) checkUnsigned: (LaunchdFile *) file
  {
  if([file.signature isEqualToString: kSignatureApple])
    return;
    
  if([file.signature isEqualToString: kSignatureValid])
    return;
  
  [[[[Model model] launchd] unsignedFiles] addObject: file];
  }
  
// Print unsigned files.
- (void) printUnsignedFiles
  {
  if([[Model model] launchd].unsignedFiles.count == 0)
    return;
    
  [self.result appendAttributedString: [self buildTitle]];
  
  for(LaunchdFile * launchdFile in [[[Model model] launchd] unsignedFiles])
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
        appendString: [Utilities cleanPath: launchdFile.executable]];
      }

    [self.result appendString: @"\n"];
    }
    
  [self.result appendCR];
  }
  
// Should this file be hidden?
- (BOOL) hideFile: (LaunchdFile *) file
  {
  Launchd * launchd = [[Model model] launchd];
  
  NSDictionary * appleFile = [launchd.appleFiles objectForKey: file.path];
  
  if(appleFile != nil)
    {
    NSString * expectedSignature = [appleFile objectForKey: kSignature];
    
    if(expectedSignature != nil)
      if([file.signature isEqualToString: expectedSignature])
        return [[Model model] ignoreKnownAppleFailures];
    }
    
  return NO;
  }
  
// Export unsigned files.
- (void) exportUnsignedFiles
  {
  if([[Model model] launchd].unsignedFiles.count == 0)
    return;

  [self.model startElement: @"launchdfiles"];
  
  for(LaunchdFile * launchdFile in [[[Model model] launchd] unsignedFiles])

    // Export the XML.
    [self.model addFragment: launchdFile.xml];
  
  [self.model endElement: @"launchdfiles"];
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
