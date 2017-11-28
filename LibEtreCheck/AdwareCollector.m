/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014-2017. All rights reserved.
 **********************************************************************/

#import "AdwareCollector.h"
#import "Model.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"
#import "LaunchdCollector.h"
#import "XMLBuilder.h"
#import "NSDictionary+Etresoft.h"
#import "LocalizedString.h"
#import "LaunchdFile.h"
#import "Launchd.h"
#import "EtreCheckConstants.h"
#import "Safari.h"
#import "SafariExtension.h"
#import "Adware.h"

#define kWhitelistKey @"whitelist"
#define kWhitelistPrefixKey @"whitelist_prefix"
#define kAdwareExtensionsKey @"adwareextensions"
#define kBlacklistKey @"blacklist"
#define kBlacklistSuffixKey @"blacklist_suffix"
#define kBlacklistMatchKey @"blacklist_match"

#define kAdwareTrioDaemon @"daemon"
#define kAdwareTrioAgent @"agent"
#define kAdwareTrioHelper @"helper"

// Collect information about adware.
@implementation AdwareCollector

// Constructor.
- (id) init
  {
  self = [super initWithName: @"adware"];
  
  if(self != nil)
    {
    }
    
  return self;
  }

// Print any adware found.
- (void) performCollect
  {
  [self loadAdwareSignatures];
  [self loadWhitelistSignatures];
  [self buildDatabases];

  [self collectLaunchdAdware];
  
  [self collectSafariExtensionAdware];
  
  [self printAdware];
  [self exportAdware];
  }
  
// Load signatures from an obfuscated list of signatures.
- (void) loadAdwareSignatures
  {
  NSBundle * bundle = [NSBundle bundleForClass: [self class]];

  NSString * signaturePath =
    [bundle pathForResource: @"adware" ofType: @"plist"];
    
  NSData * partialData = [NSData dataWithContentsOfFile: signaturePath];
  
  if(partialData)
    {
    NSMutableData * plistGzipData = [NSMutableData data];
    
    char buf[] = { 0x1F, 0x8B, 0x08 };
    
    [plistGzipData appendBytes: buf length: 3];
    [plistGzipData appendData: partialData];
    
    NSString * tempDir = [Utilities createTemporaryDirectory];
    
    NSString * tempFile =
      [tempDir stringByAppendingPathComponent: @"out.bin"];
    
    [plistGzipData writeToFile: tempFile atomically: YES];
    
    NSData * plistData = [Utilities ungzip: plistGzipData];
    
    [[NSFileManager defaultManager] removeItemAtPath: tempDir error: NULL];
    
    NSDictionary * plist = [NSDictionary readPropertyListData: plistData];
  
    if(plist != nil)
      {
      [self
        addSignatures: [plist objectForKey: kAdwareExtensionsKey]
          forKey: kAdwareExtensionsKey];
      
      [self
        addSignatures: [plist objectForKey: @"blacklist"]
        forKey: kBlacklistKey];

      [self
        addSignatures: [plist objectForKey: @"blacklist_suffix"]
        forKey: kBlacklistSuffixKey];

      [self
        addSignatures: [plist objectForKey: @"blacklist_match"]
        forKey: kBlacklistMatchKey];
      }
    }
  }

// Load signatures from a list of whitelist signatures.
- (void) loadWhitelistSignatures
  {
  NSBundle * bundle = [NSBundle bundleForClass: [self class]];

  NSString * signaturePath =
    [bundle pathForResource: @"whitelist" ofType: @"plist"];
    
  NSData * plistData = [NSData dataWithContentsOfFile: signaturePath];
  
  NSDictionary * plist = [NSDictionary readPropertyListData: plistData];
  
  if(plist != nil)
    {
    [self
      addSignatures: [plist objectForKey: kWhitelistKey]
        forKey: kWhitelistKey];
    
    [self
      addSignatures: [plist objectForKey: kWhitelistPrefixKey]
        forKey: kWhitelistPrefixKey];
    }
  }

// Add signatures that match a given key.
- (void) addSignatures: (NSArray *) signatures forKey: (NSString *) key
  {
  Adware * adware = [self.model adware];

  if(signatures)
    {
    if([key isEqualToString: kWhitelistKey])
      [adware appendToWhitelist: signatures];

    else if([key isEqualToString: kWhitelistPrefixKey])
      [adware appendToWhitelistPrefixes: signatures];

    if([key isEqualToString: kAdwareExtensionsKey])
      [adware appendToAdwareExtensions: signatures];
      
    else if([key isEqualToString: kBlacklistKey])
      [adware appendToBlacklist: signatures];
      
    else if([key isEqualToString: kBlacklistSuffixKey])
      [adware appendToBlacklistSuffixes: signatures];

    else if([key isEqualToString: kBlacklistMatchKey])
      [adware appendToBlacklistMatches: signatures];
    }
  }

// Expand adware signatures.
- (NSArray *) expandSignatures: (NSArray *) signatures
  {
  NSMutableArray * expandedSignatures = [NSMutableArray array];
  
  for(NSString * signature in signatures)
    [expandedSignatures
      addObject: [signature stringByExpandingTildeInPath]];
    
  return expandedSignatures;
  }

// Build additional internal databases.
- (void) buildDatabases
  {
  Adware * adware = [self.model adware];

  for(NSString * file in [adware whitelistFiles])
    {
    NSString * prefix = [Utilities bundleName: file];
    
    if([prefix length] > 0)
      [[adware legitimateStrings] addObject: prefix];
    }
  }

// Collect launchd adware.
- (void) collectLaunchdAdware
  {
  Launchd * launchd = [self.model launchd];
  
  // I will have already filtered out launchd files specific to this 
  // context.
  for(NSString * path in [launchd filesByPath])
    {
    LaunchdFile * file = [[launchd filesByPath] objectForKey: path];
    
    if(file != nil)
      [self checkAdware: file];
    }
  }
  
// Collect the adware status of a launchd file.
- (void) checkAdware: (LaunchdFile *) file 
  {
  bool adware = NO;

  // Check for a known adware suffix.
  if([self isAdwareSuffix: file])
    adware = true;
    
  // Check for hidden data.
  else if([self isHiddenAdware: file])
    adware = true;
    
  // Check for a known adware pattern.
  else if([self isAdwarePattern: file])
    adware = true;
    
  // Check for a known adware file.
  else if([self isAdwareMatch: [file.path lastPathComponent]])
    adware = true;
    
  // Check for a known adware pattern of matching files.
  else if([self isAdwareTrio: file])
    adware = true;
  
  file.adware = adware;
  
  if(adware)
    [[[self.model launchd] adwareFiles] addObject: file];
  }

// Is this an adware suffix file?
- (bool) isAdwareSuffix: (LaunchdFile *) file
  {
  for(NSString * suffix in [[self.model adware] blacklistSuffixes])
    if([file.path hasSuffix: suffix])
      return true;
    
  return false;
  }

// Is this hidden adware plist config file?
- (bool) isHiddenAdware: (LaunchdFile *) file
  {
  // If the config file is valid, then it can't be hidden.
  if(file.configScriptValid)
    return false;
    
  // I would expect a not loaded status from an invalid script.
  if([file.status isEqualToString: kStatusNotLoaded])
    return false;
    
  // How did it get loaded then?
  return true;
  }

// Do the plist file contents look like adware?
- (bool) isAdwarePattern: (LaunchdFile *) file
  {
  // First check for /etc/*.sh files.
  if([file.executable hasPrefix: @"/etc/"])
    if([file.executable hasSuffix: @".sh"])
      return true;
    
  // Now check for /Library/*.
  if([file.executable hasPrefix: @"/Library/"])
    {
    NSString * dirname = 
      [file.executable stringByDeletingLastPathComponent];
  
    if([dirname isEqualToString: @"/Library"])
      if([[file.executable pathExtension] length] == 0)
        return true;
        
    // Now check for /Library/*/*.
    NSString * name = [file.executable lastPathComponent];
    NSString * parent = [dirname lastPathComponent];
    
    if([name isEqualToString: parent])
      if([[file.executable pathExtension] length] == 0)
        return true;
    }
    
  // Now check arguments.
  if([file.arguments count] >= 5)
    {
    NSString * arg1 =
      [[[file.arguments firstObject] lowercaseString] lastPathComponent];
    
    NSString * commandString =
      [NSString
        stringWithFormat:
          @"%@ %@ %@ %@ %@",
          arg1,
          [[file.arguments objectAtIndex: 1] lowercaseString],
          [[file.arguments objectAtIndex: 2] lowercaseString],
          [[file.arguments objectAtIndex: 3] lowercaseString],
          [[file.arguments objectAtIndex: 4] lowercaseString]];
    
    if([commandString hasPrefix: @"installer -evnt agnt -oprid "])
      return true;
    }
    
  // Here is another pattern.
  NSString * app = [file.executable lastPathComponent];
  
  if([app hasPrefix: @"App"] && ([app length] == 5))
    if([file.arguments count] >= 2)
      {
      NSString * trigger = [file.arguments objectAtIndex: 1];
      
      if([trigger isEqualToString: @"-trigger"])
        return true;
      }

  // This is good enough for now.
  return false;
  }

// Is this an adware match file?
- (bool) isAdwareMatch: (NSString *) name
  {
  // Check full matches.
  for(NSString * match in [[self.model adware] blacklistFiles])
    if([name isEqualToString: match])
      return true;
    
  // Check partial matches.
  for(NSString * match in [[self.model adware] blacklistMatches])
    {
    NSRange range = [name rangeOfString: match];
    
    if(range.location != NSNotFound)
      return true;
    }
    
  return false;
  }

// Is this an adware trio of daemon/agent/helper?
- (bool) isAdwareTrio: (LaunchdFile *) file
  {
  NSString * prefix = nil;
  
  NSString * type = [self checkAdwareTrio: file.path prefix: & prefix];
  
  if(type == nil)
    return false;
    
  bool hasDaemon = [type isEqualToString: kAdwareTrioDaemon];
  bool hasAgent = [type isEqualToString: kAdwareTrioAgent];
  bool hasHelper = [type isEqualToString: kAdwareTrioHelper];
      
  Launchd * launchd = [self.model launchd];

  for(NSString * path in [launchd filesByPath])
    {
    NSString * trioPrefix = nil;
    NSString * trioType = [self checkAdwareTrio: path prefix: & prefix];
    
    if(trioType == nil)
      continue;
      
    if([trioPrefix isEqualToString: prefix])
      if(![trioType isEqualToString: type])
        {
        if([trioType isEqualToString: kAdwareTrioDaemon])
          hasDaemon = true;
          
        if([trioType isEqualToString: kAdwareTrioAgent])
          hasAgent = true;
          
        if([trioType isEqualToString: kAdwareTrioHelper])
          hasHelper = true;
        }
        
    if(hasDaemon && hasAgent && hasHelper)
      break;
    }
    
  return (hasDaemon && hasAgent && hasHelper);
  }

// Extract the potential trio type
- (NSString *) checkAdwareTrio: (NSString *) path 
  prefix: (NSString **) prefix
  {
  NSString * name = [path lastPathComponent];
  
  if([name hasSuffix: @".daemon.plist"])
    {
    if(*prefix)
      *prefix = [name substringToIndex: [name length] - 13];
    
    return kAdwareTrioDaemon;
    }
    
  if([name hasSuffix: @".agent.plist"])
    {
    if(*prefix)
      *prefix = [name substringToIndex: [name length] - 12];
    
    return kAdwareTrioAgent;
    }
    
  if([name hasSuffix: @".helper.plist"])
    {
    if(*prefix)
      *prefix = [name substringToIndex: [name length] - 13];
      
    return kAdwareTrioHelper;
    }

  return nil;
  }

// Collect Safari extension adware.
- (void) collectSafariExtensionAdware
  {
  Safari * safari = [self.model safari];
  
  for(NSString * path in safari.extensions)
    {
    SafariExtension * extension = [safari.extensions objectForKey: path];
    
    bool adware = false;
    
    if([self isAdwareMatch: extension.name])
      adware = true;
      
    if([self isAdwareMatch: extension.displayName])
      adware = true;
      
    if(adware)
      [[[self.model safari] adwareExtensions] addObject: extension];
    }
  }

// Print adware.
- (void) printAdware
  {
  int adwareCount = 0;
  
  adwareCount = [self printAdwareLaunchdFiles];
  adwareCount = [self printAdwareSafariExtensions: adwareCount];
  
  if(adwareCount > 0)
    {
    NSString * message = 
      ECLocalizedPluralString(adwareCount, @"adware file");

    [self.result appendString: @"    "];
    [self.result
      appendString: message
      attributes:
        @{
          NSFontAttributeName : [[Utilities shared] boldFont],
          NSForegroundColorAttributeName : [[Utilities shared] red],
        }];

    NSAttributedString * removeLink = [self generateRemoveAdwareLink];

    if(removeLink)
      {
      [self.result appendAttributedString: removeLink];
      [self.result appendString: @"\n"];
      }
    
    [self.result appendCR];
    }
  }
  
// Print adware files.
- (int) printAdwareLaunchdFiles
  {
  int adwareCount = 0;
  
  for(LaunchdFile * launchdFile in [self.model launchd].adwareFiles)
    {
    if(adwareCount++ == 0)
      [self.result appendAttributedString: [self buildTitle]];
      
    // Print the file.
    [self.result appendAttributedString: launchdFile.attributedStringValue];

    if(launchdFile.executable.length > 0)
      {
      [self.result appendString: @"\n        "];
      [self.result 
        appendString: [self cleanPath: launchdFile.executable]];
      }
    
    [self.result appendString: @"\n"];
    }
    
  return adwareCount;
  }
  
// Print adware files.
- (int) printAdwareSafariExtensions: (int) adwareCount
  {    
  Safari * safari = [self.model safari];
  
  for(SafariExtension * extension in safari.adwareExtensions)
    {
    if(adwareCount++ == 0)
      [self.result appendAttributedString: [self buildTitle]];

    // Print the extension.
    [self.result appendAttributedString: extension.attributedStringValue];
    [self.result appendString: @"\n"];
    }
        
  return adwareCount;
  }

// Export adware.
- (void) exportAdware
  {
  [self exportAdwareLaunchdFiles];
  [self exportAdwareSafariExtensions];
  }

// Print adware files.
- (void) exportAdwareLaunchdFiles
  {
  if([self.model launchd].adwareFiles.count == 0)
    return;
    
  [self.xml startElement: @"launchdfiles"];
  
  for(LaunchdFile * launchdFile in [self.model launchd].adwareFiles)

    // Export the XML.
    [self.xml addFragment: launchdFile.xml];

  [self.xml endElement: @"launchdfiles"];
  }
  
// Print adware files.
- (void) exportAdwareSafariExtensions
  {    
  Safari * safari = [self.model safari];
  
  if(safari.adwareExtensions.count == 0)
    return;
    
  [self.xml startElement: @"safariextensions"];

  for(SafariExtension * extension in safari.adwareExtensions)

    // Export the XML.
    [self.xml addFragment: extension.xml];

  [self.xml endElement: @"safariextensions"];
  }

@end
