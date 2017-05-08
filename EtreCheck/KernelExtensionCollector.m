//
/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "KernelExtensionCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"
#import "Model.h"
#import "NSArray+Etresoft.h"
#import "NSDictionary+Etresoft.h"
#import "SubProcess.h"

@implementation KernelExtensionCollector

@synthesize extensions = myExtensions;
@synthesize loadedExtensions = myLoadedExtensions;
@synthesize unloadedExtensions = myUnloadedExtensions;
@synthesize unexpectedExtensions = myUnexpectedExtensions;
@synthesize extensionsByLocation = myExtensionsByLocation;

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    myExtensionsByLocation = [NSMutableDictionary new];
    
    self.name = @"kernelextensions";
    self.title = NSLocalizedStringFromTable(self.name, @"Collectors", NULL);
    }
    
  return self;
  }

// Destructor.
- (void) dealloc
  {
  self.unexpectedExtensions = nil;
  self.unloadedExtensions = nil;
  self.loadedExtensions = nil;
  self.extensions = nil;
  [myExtensionsByLocation release];
  
  [super dealloc];
  }

// Perform the collection.
- (void) collect
  {
  [self
    updateStatus: NSLocalizedString(@"Checking kernel extensions", NULL)];

  // Collect all types of extensions.
  [self collectAllExtensions];
    
  // Divvy the extensions up into loaded, unloaded, and unexpected.
  [self categorizeExtensions];
    
  // Format all extensions into an array to be printed.
  NSArray * formattedOutput = [self formatExtensions];
  
  // Now print the output.
  if([formattedOutput count])
    {
    [self.result appendAttributedString: [self buildTitle]];
    
    for(NSAttributedString * output in formattedOutput)
      {
      [self.result appendAttributedString: output];
      [self.result appendString: @"\n"];
      }
    }

  dispatch_semaphore_signal(self.complete);
  }

// Collect all extensions on the system.
- (void) collectAllExtensions
  {
  [self collectKnownExtensions];
  
  NSMutableDictionary * allExtensions = [NSMutableDictionary dictionary];
  
  [allExtensions addEntriesFromDictionary: [self collectExtensions]];
  [allExtensions addEntriesFromDictionary: [self collectSystemExtensions]];
  [allExtensions
    addEntriesFromDictionary: [self collectApplicationSupportExtensions]];
  [allExtensions
    addEntriesFromDictionary:
      [self collectSystemApplicationSupportExtensions]];
  [allExtensions
    addEntriesFromDictionary: [self collectStartupItemExtensions]];
  [allExtensions
    addEntriesFromDictionary: [self collectApplicationExtensions]];
  
  self.extensions = allExtensions;
  }

// Collect known extensions.
- (void) collectKnownExtensions
  {
  NSArray * args =
    @[
      @"-xml",
      @"SPExtensionsDataType"
    ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  if([subProcess execute: @"/usr/sbin/system_profiler" arguments: args])
    {
    NSArray * plist =
      [NSArray readPropertyListData: subProcess.standardOutput];
  
    if([plist count])
      {
      NSArray * foundExtensions =
        [[plist objectAtIndex: 0] objectForKey: @"_items"];
        
      NSMutableDictionary * knownExtensions =
        [NSMutableDictionary dictionary];
      
      for(NSDictionary * foundExtension in foundExtensions)
        {
        NSString * path = [foundExtension objectForKey: @"spext_path"];
        
        if([path length] > 0)
          if([[NSFileManager defaultManager] fileExistsAtPath: path])
            [knownExtensions setObject: foundExtension forKey: path];
        }
      
      [self checkForAppleExtensions: knownExtensions];
      [self checkForUnknownExtensions: knownExtensions];
      }
    }
    
  [subProcess release];
  }

// Check for Apple extensions.
- (void) checkForAppleExtensions: (NSDictionary *) knownExtensions
  {
  // Add the Apple tag from any known extensions.
  for(NSString * label in self.extensions)
    {
    NSDictionary * extension = [self.extensions objectForKey: label];
    
    NSString * path = [extension objectForKey: @"path"];
    
    NSDictionary * knownExtension = [knownExtensions objectForKey: path];
      
    if(knownExtension)
      {
      NSString * obtained_from =
        [knownExtension objectForKey: @"spext_obtained_from"];
      
      if([obtained_from isEqualToString: @"spext_apple"])
        {
        NSMutableDictionary * extension =
          [self.extensions objectForKey: label];
        
        [extension setObject: @"apple" forKey: @"obtained_from"];
        }
      }
    }
  }
  
// Look for any heretofore unknown extensions.
- (void) checkForUnknownExtensions: (NSDictionary *) knownExtensions
  {
  // Collect the paths of all current extensions.
  NSMutableSet * extensionPaths = [NSMutableSet set];
  
  for(NSString * label in self.extensions)
    {
    NSDictionary * extension = [self.extensions objectForKey: label];
    
    NSString * path = [extension objectForKey: @"path"];
    
    if(path)
      [extensionPaths addObject: path];
    }
    
  for(NSString * name in knownExtensions)
    {
    NSDictionary * knownExtension = [knownExtensions objectForKey: name];
    
    NSString * path = [knownExtension objectForKey: @"spext_path"];
    
    // Do I already know about this extension?
    if([extensionPaths containsObject: path])
      continue;
      
    // Add it to the list.
    NSMutableDictionary * bundle = [self parseExtensionBundle: path];
        
    if(bundle)
      {
      NSString * identifier = [bundle objectForKey: @"CFBundleIdentifier"];

      NSString * obtained_from =
        [knownExtension objectForKey: @"spext_obtained_from"];
        
      if([obtained_from isEqualToString: @"spext_apple"])
        [bundle setObject: @"apple" forKey: @"obtained_from"];
        
      [self.extensions setObject: bundle forKey: identifier];
      }
    }
  }

// Collect 3rd party extensions.
- (NSDictionary *) collectExtensions
  {
  NSArray * args =
    @[
      @"/Library/Extensions",
      @"-iname",
      @"*.kext"];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  [subProcess autorelease];
  
  if([subProcess execute: @"/usr/bin/find" arguments: args])
    return [self parseBundles: subProcess.standardOutput];
    
  return [NSDictionary dictionary];
  }

// Collect system extensions.
- (NSDictionary *) collectSystemExtensions
  {
  NSArray * args =
    @[
      @"/System/Library/Extensions",
      @"-iname",
      @"*.kext"];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  [subProcess autorelease];
  
  if([subProcess execute: @"/usr/bin/find" arguments: args])
    return [self parseBundles: subProcess.standardOutput];
    
  return [NSDictionary dictionary];
  }

// Collect application support extensions.
- (NSDictionary *) collectApplicationSupportExtensions
  {
  NSArray * args =
    @[
      @"/Library/Application Support",
      @"-iname",
      @"*.kext"];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  [subProcess autorelease];
  
  if([subProcess execute: @"/usr/bin/find" arguments: args])
    return [self parseBundles: subProcess.standardOutput];
    
  return [NSDictionary dictionary];
  }

// Collect system application support extensions.
- (NSDictionary *) collectSystemApplicationSupportExtensions
  {
  NSArray * args =
    @[
      @"/System/Library/Application Support",
      @"-iname",
      @"*.kext"];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  [subProcess autorelease];
  
  if([subProcess execute: @"/usr/bin/find" arguments: args])
    return [self parseBundles: subProcess.standardOutput];
    
  return [NSDictionary dictionary];
  }

// Collect startup item extensions.
- (NSDictionary *) collectStartupItemExtensions
  {
  NSArray * args =
    @[
      @"/Library/StartupItems",
      @"-iname",
      @"*.kext"];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  [subProcess autorelease];
  
  if([subProcess execute: @"/usr/bin/find" arguments: args])
    return [self parseBundles: subProcess.standardOutput];
    
  return [NSDictionary dictionary];
  }

// Collect application extensions.
- (NSDictionary *) collectApplicationExtensions
  {
  NSMutableDictionary * extensions = [NSMutableDictionary dictionary];
  
  NSDictionary * applications =
    [[Model model] applications];
  
  for(NSString * name in applications)
    {
    NSDictionary * application = [applications objectForKey: name];
    
    [extensions
      addEntriesFromDictionary: [self collectExtensionsIn: application]];
    }
    
  return extensions;
  }

// Collect extensions from a specific application.
- (NSDictionary *) collectExtensionsIn: (NSDictionary *) application
  {
  NSString * bundleID = [application objectForKey: @"CFBundleIdentifier"];

  if(bundleID)
    {
    NSString * obtained_from = [application objectForKey: @"obtained_from"];
    
    if([obtained_from isEqualToString: @"apple"])
      return @{};
     
    // The obtained_from indicator isn't quite good enough.
    if([bundleID hasPrefix: @"com.apple."])
      return @{};
      
    NSString * path = [application objectForKey: @"path"];
    
    if(![path length])
      return @{};
      
    NSArray * args =
      @[
        path,
        @"-iname",
        @"*.kext"];
    
    SubProcess * subProcess = [[SubProcess alloc] init];
    
    [subProcess autorelease];
    
    if([subProcess execute: @"/usr/bin/find" arguments: args])
      return [self parseBundles: subProcess.standardOutput];
    }
    
  return [NSDictionary dictionary];
  }

// Return a dictionary of expanded bundle dictionaries found in a directory.
- (NSDictionary *) parseBundles: (NSData *) data
  {
  NSArray * lines = [Utilities formatLines: data];
  
  NSMutableDictionary * bundles = [NSMutableDictionary dictionary];

  for(NSString * line in lines)
    {
    NSMutableDictionary * bundle = [self parseExtensionBundle: line];
      
    NSString * identifier = [bundle objectForKey: @"CFBundleIdentifier"];

    if(identifier && bundle)
      [bundles setObject: bundle forKey: identifier];
    }
    
  return bundles;
  }

// Parse a single extension bundle.
- (NSMutableDictionary *) parseExtensionBundle: (NSString *) path
  {
  NSString * versionPlist =
    [path stringByAppendingPathComponent: @"Contents/Info.plist"];

  NSDictionary * plist = [NSDictionary readPropertyList: versionPlist];

  // Check for inconsistent path from Apple extensions.
  if(!plist)
    versionPlist = [path stringByAppendingPathComponent: @"Info.plist"];

  plist = [NSDictionary readPropertyList: versionPlist];

  if(plist)
    {
    NSString * identifier = [plist objectForKey: @"CFBundleIdentifier"];
    
    if(identifier)
      {
      NSMutableDictionary * bundle =
        [NSMutableDictionary dictionaryWithDictionary: plist];
      
      // Save the path too.
      [bundle setValue: [self extensionDirectory: path] forKey: @"path"];
      
      return bundle;
      }
    }
    
  return nil;
  }

// Get the path from a bundle and type.
- (NSString *) extensionDirectory: (NSString *) path
  {
  NSArray * parts = [path componentsSeparatedByString: @"/"];

  NSMutableArray * pathParts = [NSMutableArray array];
  
  for(NSString * part in parts)
    {
    [pathParts addObject: part];
    
    if([[part pathExtension] isEqualToString: @"app"])
      return [pathParts componentsJoinedByString: @"/"];
    }
    
  return [path stringByDeletingLastPathComponent];
  }

// Return the next component after a prefix in a path.
- (NSString *) pathWithPrefix: (NSString *) prefix path: (NSString *) path
  {
  NSString * relativePath = [path substringFromIndex: [prefix length]];
  
  NSArray * parts = [relativePath componentsSeparatedByString: @"/"];
  
  return [parts firstObject];
  }

// Categories the extensions into various types.
- (void) categorizeExtensions
  {
  // Find loaded (and unexpecteded loaded) extensions.
  [self findLoadedExtensions];
  
  // The rest must be unloaded.
  [self findUnloadedExtensions];

  // Now organize by path.
  for(NSString * label in self.extensions)
    {
    NSDictionary * bundle = [self.extensions objectForKey: label];
    
    NSString * path = [bundle objectForKey: @"path"];
      
    NSMutableArray * extensions =
      [self.extensionsByLocation objectForKey: path];
      
    if(!extensions)
      {
      extensions = [NSMutableArray array];
      
      [self.extensionsByLocation setObject: extensions forKey: path];
      }
      
    [extensions addObject: label];
    }
  }

// Find loaded extensions.
- (void) findLoadedExtensions
  {
  NSArray * args = @[ @"-l" ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  if([subProcess execute: @"/usr/sbin/kextstat" arguments: args])
    {
    NSArray * lines = [Utilities formatLines: subProcess.standardOutput];

    self.loadedExtensions = [NSMutableDictionary dictionary];
    self.unexpectedExtensions = [NSMutableDictionary dictionary];
    
    for(NSString * line in lines)
      {
      NSString * label = nil;
      NSString * version = nil;

      [self parseKext: line label: & label version: & version];

      if(label && version)
        {
        NSDictionary * bundle = [self.extensions objectForKey: label];
        
        if(bundle)
          [self.loadedExtensions setObject: bundle forKey: label];
          
        else
          {
          bundle =
            [NSDictionary
              dictionaryWithObjectsAndKeys:
                version, @"CFBundleVersion",
                label, @"CFBundleIdentifier",
                nil];
            
          [self.unexpectedExtensions setObject: bundle forKey: label];
          }
        }
      }
    }
    
  [subProcess release];
  }

// Find unloaded extensions.
- (void) findUnloadedExtensions
  {
  self.unloadedExtensions = [NSMutableDictionary dictionary];

  // The rest must be unloaded.
  for(NSString * label in self.extensions)
    {
    NSDictionary * loadedBundle =
      [self.loadedExtensions objectForKey: label];
    
    if(!loadedBundle)
      [self.unloadedExtensions
        setObject: [self.extensions objectForKey: label] forKey: label];
    }
  }

// Parse a single line of kextctl output.
- (void) parseKext: (NSString *) line
  label: (NSString **) label version: (NSString **) version
  {
  NSScanner * scanner = [NSScanner scannerWithString: line];

  for(int i = 0; i < 5; ++i)
    if(![scanner scanUpToString: @" " intoString: NULL])
      return;

  bool found = [scanner scanUpToString: @" (" intoString: label];

  if(!found)
    return;

  [scanner scanString: @"(" intoString: NULL];
  [scanner scanUpToString: @")" intoString: version];
  }

// Should an extension be ignored if unloaded?
- (bool) ignoreUnloadedExtension: (NSString *) label
  {
  if([label hasPrefix: @"com.huawei.driver."])
    return YES;
  else if([label hasPrefix: @"com.hp."])
    return YES;
  else if([label hasPrefix: @"com.epson."])
    return YES;
  else if([label hasPrefix: @"com.lexmark."])
    return YES;
  else if([label hasPrefix: @"jp.co.canon."])
    return YES;
  else if([label hasPrefix: @"com.Areca.ArcMSR"])
    return YES;
  else if([label hasPrefix: @"com.ATTO.driver.ATTO"])
    return YES;
  else if([label hasPrefix: @"com.Accusys.driver.Acxxx"])
    return YES;
  else if([label hasPrefix: @"com.jmicron.JMicronATA"])
    return YES;
  else if([label hasPrefix: @"com.softraid.driver.SoftRAID"])
    return YES;
  else if([label hasPrefix: @"com.promise.driver.stex"])
    return YES;
  else if([label hasPrefix: @"com.highpoint-tech.kext.HighPoint"])
    return YES;
  else if([label hasPrefix: @"com.CalDigit.driver.HDPro"])
    return YES;
  else if([label hasPrefix: @"com.silabs.driver.CP210xVCPDriver"])
    return YES;

  // Snow Leopard.
  else if([label hasPrefix: @"com.Immersion.driver.ImmersionForceFeedback"])
    return YES;
  else if([label hasPrefix: @"com.acard.driver.ACard6"])
    return YES;
  else if([label hasPrefix: @"com.logitech.driver.LogitechForceFeedback"])
    return YES;

  return NO;
  }

// Format non-standard extensions.
- (NSArray *) formatExtensions
  {
  NSMutableArray * extensions = [NSMutableArray array];
    
  NSArray * sortedDirectories =
    [[self.extensionsByLocation allKeys]
      sortedArrayUsingSelector: @selector(compare:)];

  for(NSString * directory in sortedDirectories)
    [extensions
      addObjectsFromArray: [self formatExtensionDirectory: directory]];
    
  return extensions;
  }

// Format a directory of extensions.
- (NSArray *) formatExtensionDirectory: (NSString *) directory
  {
  NSMutableArray * extensions = [NSMutableArray array];
  
  NSArray * sortedExtensions =
    [[self.extensionsByLocation objectForKey: directory]
      sortedArrayUsingSelector: @selector(compare:)];

  for(NSString * label in sortedExtensions)
    {
    NSAttributedString * output = [self formatExtension: label];
    
    // Outpt could be nil if this is an Apple extension.
    if(output)
      [extensions addObject: output];
    }
    
  // If I found any non-nil extensions, insert a header for the directory.
  if([extensions count])
    {
    NSMutableAttributedString * string =
      [[NSMutableAttributedString alloc] initWithString: @""];
    
    // This will add a new line at the end.
    [extensions addObject: [[string copy] autorelease]];
    
    [string
      appendString:
        [NSString
          stringWithFormat: @"        %@", [Utilities cleanPath: directory]]
      attributes:
        @{
          NSFontAttributeName : [[Utilities shared] boldFont],
        }];
    
    [extensions insertObject: string atIndex: 0];
      
    [string release];
    }
    
  return extensions;
  }

// Format an extension for output.
- (NSAttributedString *) formatExtension: (NSString *) label
  {
  NSDictionary * extension = [self.extensions objectForKey: label];
  
  NSString * obtained_from = [extension objectForKey: @"obtained_from"];
  
  if([obtained_from isEqualToString: @"apple"])
    return nil;

  // The obtained_from indicator isn't quite good enough.
  if([label hasPrefix: @"com.apple."])
    return nil;

  NSColor * color = [[Utilities shared] blue];

  NSString * status = NSLocalizedString(@"[loaded]", NULL);
  
  if([self.unloadedExtensions objectForKey: label])
    {
    status = NSLocalizedString(@"[not loaded]", NULL);
    color = [[Utilities shared] gray];

    if([self ignoreUnloadedExtension: label])
      return nil;
    }
    
  return [self formatBundle: label status: status color: color];
  }

// Return a formatted bundle.
- (NSAttributedString *) formatBundle: (NSString * ) label
  status: (NSString *) status color: (NSColor *) color
  {
  NSMutableAttributedString * formattedOutput =
    [[NSMutableAttributedString alloc] init];
    
  NSDictionary * bundle = [self.extensions objectForKey: label];
  
  NSString * version = [bundle objectForKey: @"CFBundleShortVersionString"];
  
  if([version length] == 0)
    version = [bundle objectForKey: @"CFBundleVersion"];

  int age = 0;
  
  NSString * OSVersion = [self getOSVersion: bundle age: & age];
    
  [formattedOutput
    appendString:
      [NSString
        stringWithFormat:
          @"    %@    ", status]
    attributes:
      [NSDictionary
        dictionaryWithObjectsAndKeys:
          color, NSForegroundColorAttributeName, nil]];

  // Fix the version to get past ASC spam filters.
  version =
    [version stringByReplacingOccurrencesOfString: @"91" withString: @"**"];
  
  [formattedOutput
    appendString:
      [NSString
        stringWithFormat: @"%@ (%@%@)", label, version, OSVersion]];
    
  [formattedOutput
    appendAttributedString: [self getSupportLink: bundle]];
    
  return [formattedOutput autorelease];
  }

// Append the modification date.
- (NSString *) modificationDate: (NSString *) path
  {
  NSDate * modificationDate = [Utilities modificationDate: path];
    
  if(modificationDate)
    {
    NSString * modificationDateString =
      [Utilities installDateAsString: modificationDate];
    
    if(modificationDateString)
      return [NSString stringWithFormat: @" - %@", modificationDateString];
    }
    
  return @"";
  }

@end
