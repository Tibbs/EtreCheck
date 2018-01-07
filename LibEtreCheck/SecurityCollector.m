/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014-2017. All rights reserved.
 **********************************************************************/

#import "SecurityCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Model.h"
#import "Utilities.h"
#import "SubProcess.h"
#import "XMLBuilder.h"
#import "LocalizedString.h"
#import "EtreCheckConstants.h"
#import "OSVersion.h"
#import "NSDictionary+Etresoft.h"
#import "NSString+Etresoft.h"
#import "NSArray+Etresoft.h"

#define kRootlessPrefix @"System Integrity Protection status:"

// Collect Gatekeeper status.
@implementation SecurityCollector

// Names of Apple security packages.
@synthesize AppleSecurityPackageNames = myAppleSecurityPackageNames;

// System Integrity Protection status.
@synthesize SIPStatus = mySIPStatus;

// XProtect version.
@synthesize installedXProtectVersion = myInstalledXProtectVersion;

// Gatekeeper version.
@synthesize installedGatekeeperVersion = myInstalledGatekeeperVersion;

// MRT version.
@synthesize installedMRTVersion = myInstalledMRTVersion;

// Current XProtect version.
@synthesize currentXProtectVersion = myCurrentXProtectVersion;

// Current Gatekeeper version.
@synthesize currentGatekeeperVersion = myCurrentGatekeeperVersion;

// Current MRT version.
@synthesize currentMRTVersion = myCurrentMRTVersion;

// Are security versions outdated?
@synthesize outdated = myOutdated;

// Constructor.
- (id) init
  {
  self = [super initWithName: @"security"];
  
  if(self != nil)
    {
    myAppleSecurityPackageNames = 
      [[NSSet alloc] 
        initWithObjects:
          @"XProtectPlistConfigData", 
          @"MRTConfigData", 
          @"GatekeeperConfigData",
          nil];
    }
    
  return self;
  }

// Destructor.
- (void) dealloc
  {
  [myAppleSecurityPackageNames release];
  self.SIPStatus = nil;
  self.installedXProtectVersion = nil;
  self.installedGatekeeperVersion = nil;
  self.installedMRTVersion = nil;
  self.currentXProtectVersion = nil;
  self.currentGatekeeperVersion = nil;
  self.currentMRTVersion = nil;
  
  [super dealloc];
  }
  
// Perform the collection.
- (void) performCollect
  {
  [self.result appendAttributedString: [self buildTitle]];

  [self collectCurrentVersions];
  [self collectInstalledVersions];
  
  [self printGatekeeperSetting];
  [self checkSIP];
  [self printVersions];

  [self.result appendCR];
  }

// Collect current versions.
- (void) collectCurrentVersions
  {
  NSMutableString * updateCode = [NSMutableString new];
  
  switch([[OSVersion shared] major])
    {
    case kHighSierra:
      [updateCode appendString: @"-10.13"];
    case kSierra:
      [updateCode appendString: @"-10.12"];
    case kElCapitan:
      [updateCode appendString: @"-10.11"];
    case kYosemite:
      [updateCode appendString: @"-10.10"];
    case kMavericks:
      [updateCode appendString: @"-10.9"];
    case kMountainLion:
      [updateCode appendString: @"-mountainlion"];
    default:
      [updateCode appendString: @"-lion-snowleopard-leopard.merged-1"];
    }
    
  NSString * urlString =
    [[NSString alloc] 
      initWithFormat: 
        @"%@%@%@",
        @"https://swscan.apple.com/content/catalogs/others/index",
        updateCode,
        @".sucatalog.gz"];
    
  [updateCode release];
  
  NSURL * url = [[NSURL alloc] initWithString: urlString];
  
  [urlString release];
  
  NSData * data = [NSData dataWithContentsOfURL: url];
  
  NSDictionary * plist = [NSDictionary readPropertyListData: data];
  
  if([NSDictionary isValid: plist])
    {
    NSNumber * version = [plist objectForKey: @"CatalogVersion"];
    
    if(version.intValue == 2)
      {
      NSDictionary * products = [plist objectForKey: @"Products"];
      
      if([NSDictionary isValid: products])
        [self parseProducts: products];
      }
    }
  
  [url release];
  } 
  
// Parse update products.
- (void) parseProducts: (NSDictionary *) products
  {
  for(NSString * key in products)
    {
    NSDictionary * product = [products objectForKey: key];
    
    if([NSDictionary isValid: product])
      [self parseProduct: product];
    }
  }
  
// Parse an update product.
- (void) parseProduct: (NSDictionary *) product
  {
  NSString * metadataURL = [product objectForKey: @"ServerMetadataURL"];
  
  if([NSString isValid: metadataURL])
    {
    NSString * key = 
      [[metadataURL lastPathComponent] stringByDeletingPathExtension];
      
    if([self.AppleSecurityPackageNames containsObject: key])
      {
      NSArray * packages = [product objectForKey: @"Packages"];

      if([NSArray isValid: packages])
        for(NSDictionary * package in packages)
          if([NSDictionary isValid: package])
            {
            NSString * urlString = [package objectForKey: @"MetadataURL"];

            if(![NSString isValid: urlString])
              continue;
              
            NSURL * url = [[NSURL alloc] initWithString: urlString];
            
            NSData * data = [NSData dataWithContentsOfURL: url];
      
            [url release];
      
            NSString * version = [self parseVersion: data];
            
            if([NSString isValid: version])
              {
              if([key isEqualToString: @"XProtectPlistConfigData"])
                {
                BOOL later = 
                  [Utilities 
                    isVersion: version 
                    laterThanVersion: self.currentXProtectVersion];
                
                if((self.currentXProtectVersion == nil) || later)
                  self.currentXProtectVersion = version;
                }
                
              else if([key isEqualToString: @"MRTConfigData"])
                {
                BOOL later = 
                  [Utilities 
                    isVersion: version 
                    laterThanVersion: self.currentMRTVersion];
                
                if((self.currentMRTVersion == nil) || later)
                  self.currentMRTVersion = version;
                }
                
              else if([key isEqualToString: @"GatekeeperConfigData"])
                {
                BOOL later = 
                  [Utilities 
                    isVersion: version 
                    laterThanVersion: self.currentGatekeeperVersion];
                
                if((self.currentGatekeeperVersion == nil) || later)
                  self.currentGatekeeperVersion = version;
                }
              }
            }
      }
    }
  } 

// Parse a version from XML metadata.
- (NSString *) parseVersion: (NSData *) data
  {
  NSString * version = nil;
  
  // This data is XML. I should parse it as such. But I don't trust Apple's
  // NSXMLDocument and the library I do trust is not accessible here. When
  // I consolidate everything one day, I'll fix this. But not today.
  
  NSString * xml = 
    [[NSString alloc] initWithData: data encoding:NSUTF8StringEncoding];
  
  NSScanner * scanner = [[NSScanner alloc] initWithString: xml];
  
  BOOL success = 
    [scanner 
      scanUpToString: @"CFBundleShortVersionString=\"" intoString: NULL];
      
  if(success)
    {
    success = 
      [scanner 
        scanString: @"CFBundleShortVersionString=\"" intoString: NULL];
    
    if(success)
      [scanner scanUpToString: @"\"" intoString: & version];
    }
    
  [scanner release];
  [xml release];
  
  return version;
  }
  
// Collect installed updates.
- (void) collectInstalledVersions
  {
  self.installedXProtectVersion =
    [self 
      collectInstalledVersion: 
        @"/System/Library/CoreServices/XProtect.bundle/Contents/Info.plist"];
        
  self.installedMRTVersion =
    [self 
      collectInstalledVersion: 
        @"/System/Library/CoreServices/MRT.app/Contents/Info.plist"];
  
  self.installedGatekeeperVersion =
    [self 
      collectInstalledVersion: 
        @"/private/var/db/gkopaque.bundle/Contents/Info.plist"];
  }
  
// Collect an installed version from a plist file.
- (NSString *) collectInstalledVersion: (NSString *) path
  {
  NSDictionary * plist = [NSDictionary readPropertyList: path];
  
  if([NSDictionary isValid: plist])
    return [plist objectForKey: @"CFBundleShortVersionString"];
    
  return nil;
  }
  
// Print the Gatekeeper setting.
- (void) printGatekeeperSetting
  {
  [self.xml startElement: @"gatekeeper"];
  
  [self.xml 
    addElement: @"installedversion" value: self.installedGatekeeperVersion];
  
  [self.xml 
    addElement: @"currentversion" value: self.currentGatekeeperVersion];

  BOOL later = 
    [Utilities 
      isVersion: self.currentGatekeeperVersion 
      laterThanVersion: self.installedGatekeeperVersion];
  
  if(later)
    self.outdated = YES;

  GatekeeperSetting setting = [self collectGatekeeperSetting];
  
  switch(setting)
    {
    case kMacAppStore:
      [self.xml 
        addElement: @"status" 
        value: ECLocalizedString(@"Mac App Store")];
      
      [self.result
        appendString:
          [NSString
            stringWithFormat:
              @"    %@\n", ECLocalizedString(@"Mac App Store")]];
      break;
    case kDeveloperID:
      [self.xml 
        addElement: @"status" 
        value: 
          ECLocalizedString(
            @"Mac App Store and identified developers")];

      [self.result
        appendString:
          [NSString
            stringWithFormat:
              @"    %@\n",
              ECLocalizedString(
                @"Mac App Store and identified developers")]];
      break;
    case kDisabled:
      [self.xml 
        addElement: @"status" 
        value: ECLocalizedString(@"Anywhere")];

      [self.result
        appendString:
          [NSString
            stringWithFormat:
              @"    %@ ", ECLocalizedString(@"Anywhere")]
        attributes:
          [NSDictionary
            dictionaryWithObjectsAndKeys:
              [NSColor redColor], NSForegroundColorAttributeName, nil]];
      [self.result appendAttributedString: [self buildFixLink]];
      [self.result appendString: @"\n"];
      break;
      
    case kNoGatekeeper:
      [self.result
        appendString:
          ECLocalizedString(@"gatekeeperneedsmountainlion")
        attributes:
          [NSDictionary
            dictionaryWithObjectsAndKeys:
              [NSColor redColor], NSForegroundColorAttributeName, nil]];
    
      break;
    
    case kSettingUnknown:
    default:
      [self.xml 
        addElement: @"status" 
        value: ECLocalizedString(@"Unknown")];

      [self.result
        appendString:
          [NSString
            stringWithFormat:
              @"    %@\n", ECLocalizedString(@"Unknown!")]
        attributes:
          [NSDictionary
            dictionaryWithObjectsAndKeys:
              [NSColor redColor], NSForegroundColorAttributeName, nil]];
      break;
    }

  [self.xml endElement: @"gatekeeper"];
  }

// Collect the Gatekeeper setting.
- (GatekeeperSetting) collectGatekeeperSetting
  {
  // Only check gatekeeper on Mountain Lion or later.
  if([[OSVersion shared] major] < kMountainLion)
    return kNoGatekeeper;
    
  bool gatekeeperExists =
    [[NSFileManager defaultManager] fileExistsAtPath: @"/usr/sbin/spctl"];
  
  if(!gatekeeperExists)
    return kNoGatekeeper;

  NSArray * args =
    @[
      @"--status",
      @"--verbose"
    ];
  
  GatekeeperSetting setting = kSettingUnknown;
    
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  NSString * key = @"gatekeeper";
  
  [subProcess loadDebugOutput: [self.model debugInputPath: key]];      
  [subProcess saveDebugOutput: [self.model debugOutputPath: key]];

  if([subProcess execute: @"/usr/sbin/spctl" arguments: args])
    {
    NSArray * lines = [Utilities formatLines: subProcess.standardOutput];

    for(NSString * line in lines)
      {
      NSString * trimmedLine =
        [line
          stringByTrimmingCharactersInSet:
            [NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
      if([trimmedLine isEqualToString: @""])
        continue;

      if(self.simulating)
        trimmedLine = @"assessments disabled";
        
      if([trimmedLine isEqualToString: @"assessments disabled"])
        setting = kDisabled;
      else if([trimmedLine isEqualToString: @"developer id enabled"])
        setting = kDeveloperID;
      else if([trimmedLine isEqualToString: @"developer id disabled"])
        setting = kMacAppStore;
      }
    }
    
  [subProcess release];
  
  // Perhaps I am on Mountain Lion and need to check the old debug
  // command line argument.
  if(setting == kSettingUnknown)
    setting = [self collectMountainLionGatekeeperSetting];
    
  return setting;
  }

// Collect the Mountain Lion Gatekeeper setting.
- (GatekeeperSetting) collectMountainLionGatekeeperSetting
  {
  GatekeeperSetting setting = kSettingUnknown;
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  NSString * key = @"gatekeeper";
  
  [subProcess loadDebugOutput: [self.model debugInputPath: key]];      
  [subProcess saveDebugOutput: [self.model debugOutputPath: key]];

  BOOL result =
    [subProcess
      execute: @"/usr/sbin/spctl" arguments: @[@"--test-devid-status"]];
    
  if(result)
    {
    NSArray * lines = [Utilities formatLines: subProcess.standardOutput];

    for(NSString * line in lines)
      {
      NSString * trimmedLine =
        [line
          stringByTrimmingCharactersInSet:
            [NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
      if([trimmedLine isEqualToString: @""])
        continue;

      if([trimmedLine isEqualToString: @"devid enabled"])
        setting = kDeveloperID;
      else if([trimmedLine isEqualToString: @"devid disabled"])
        setting = kMacAppStore;
      }
    }
    
  [subProcess release];
    
  return setting;
  }

// Create an open URL for a file.
- (NSAttributedString *) buildFixLink
  {
  NSMutableAttributedString * urlString =
    [[NSMutableAttributedString alloc] initWithString: @""];
    
  [urlString
    appendString: ECLocalizedString(@"[Fix Gatekeeper security]")
    attributes:
      @{
        NSFontAttributeName : [[Utilities shared] boldFont],
        NSForegroundColorAttributeName : [NSColor redColor],
        NSLinkAttributeName : @"etrecheck://enablegatekeeper/"
      }];
  
  return [urlString autorelease];
  }

// Check SIP status.
- (void) checkSIP
  {
  if([[OSVersion shared] major] >= kElCapitan)
    {
    NSString * status = [self checkRootlessStatus];
  
    if(self.simulating)
      status = @"Simulated";
      
    [self.xml addElement: @"SIP" value: status];
    
    if([status isEqualToString: @"enabled"])
      [self.model setSIP: YES];
    }
  }

// Check System Integrity Protection.
- (NSString *) checkRootlessStatus
  {
  bool csrutilExists =
    [[NSFileManager defaultManager] fileExistsAtPath: @"/usr/bin/csrutil"];
    
  if(!csrutilExists)
    return ECLocalizedString(@"/usr/bin/csrutil missing");
    
  // Now consolidate destination information.
  NSArray * args =
    @[
      @"status",
    ];
  
  NSString * result = ECLocalizedString(@"missing");
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  [subProcess loadDebugOutput: [self.model debugInputPath: @"csrutil"]];      
  [subProcess saveDebugOutput: [self.model debugOutputPath: @"csrutil"]];

  if([subProcess execute: @"/usr/bin/csrutil" arguments: args])
    {
    NSString * status =
      [[NSString alloc]
        initWithData: subProcess.standardOutput
        encoding: NSUTF8StringEncoding];
    
    NSScanner * scanner = [NSScanner scannerWithString: status];
    
    if([scanner scanString: kRootlessPrefix intoString: NULL])
      [scanner scanUpToString: @"." intoString: & result];
      
    if(![result length])
      result =
        [NSString
          stringWithFormat:
            ECLocalizedString(@"/usr/bin/csrutil returned \"%@\""), status];
    
    [status release];
    }
    
  [subProcess release];
  
  return result;
  }

// Print versions of other data.
- (void) printVersions
  {
  [self.xml startElement: @"xprotect"];
  
  [self.xml 
    addElement: @"installedversion" value: self.installedXProtectVersion];
  
  [self.xml 
    addElement: @"currentversion" value: self.currentXProtectVersion];
  
  BOOL later = 
    [Utilities 
      isVersion: self.currentXProtectVersion 
      laterThanVersion: self.installedXProtectVersion];
  
  if(later)
    self.outdated = YES;
    
  [self.xml endElement: @"xprotect"];

  [self.xml startElement: @"mrt"];

  [self.xml 
    addElement: @"installedversion" value: self.installedMRTVersion];
  
  [self.xml addElement: @"currentversion" value: self.currentMRTVersion];

  later = 
    [Utilities 
      isVersion: self.currentMRTVersion 
      laterThanVersion: self.installedMRTVersion];
  
  if(later)
    self.outdated = YES;

  [self.xml endElement: @"mrt"];
  
  [self.xml addElement: @"outdated" boolValue: self.outdated];
  }
  
@end
