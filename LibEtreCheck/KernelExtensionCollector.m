/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014-2017. All rights reserved.
 **********************************************************************/

#import "KernelExtensionCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"
#import "Model.h"
#import "NSArray+Etresoft.h"
#import "NSDictionary+Etresoft.h"
#import "NSMutableArray+Etresoft.h"
#import "NSMutableDictionary+Etresoft.h"
#import "NSString+Etresoft.h"
#import "SubProcess.h"
#import "XMLBuilder.h"
#import "LocalizedString.h"

@implementation KernelExtensionCollector

@synthesize extensions = myExtensions;
@synthesize loadedExtensions = myLoadedExtensions;
@synthesize unloadedExtensions = myUnloadedExtensions;
@synthesize unexpectedExtensions = myUnexpectedExtensions;
@synthesize extensionsByLocation = myExtensionsByLocation;

// Constructor.
- (id) init
  {
  self = [super initWithName: @"kernelextensions"];
  
  if(self != nil)
    {
    myExtensionsByLocation = [NSMutableDictionary new];
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
- (void) performCollect
  {
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
  NSString * key = @"SPExtensionsDataType";
  
  NSArray * args =
    @[
      @"-xml",
      key
    ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  [subProcess loadDebugOutput: [self.model debugInputPath: key]];      
  [subProcess saveDebugOutput: [self.model debugOutputPath: key]];

  if([subProcess execute: @"/usr/sbin/system_profiler" arguments: args])
    {
    NSArray * plist =
      [NSArray readPropertyListData: subProcess.standardOutput];
  
    if([NSArray isValid: plist])
      {
      NSDictionary * results = [plist objectAtIndex: 0];
      
      if([NSDictionary isValid: results])
        {
        NSArray * foundExtensions = [results objectForKey: @"_items"];
        
        NSMutableDictionary * knownExtensions =
          [NSMutableDictionary dictionary];
      
        if([NSArray isValid: foundExtensions])
          if([NSDictionary isValid: knownExtensions])
            {
            for(NSDictionary * foundExtension in foundExtensions)
              if([NSDictionary isValid: foundExtension])
                {
                NSString * path = 
                  [foundExtension objectForKey: @"spext_path"];
                
                if([NSString isValid: path])
                  {
                  BOOL exists = 
                    [[NSFileManager defaultManager] fileExistsAtPath: path];
                    
                  if(exists)
                    [knownExtensions 
                      setObject: foundExtension forKey: path];
                  }
                }
            
            [self checkForAppleExtensions: knownExtensions];
            [self checkForUnknownExtensions: knownExtensions];
            }
        }
      }
    }
    
  [subProcess release];
  }

// Check for Apple extensions.
- (void) checkForAppleExtensions: (NSDictionary *) knownExtensions
  {
  if(![NSDictionary isValid: knownExtensions])
    return;
    
  // Add the Apple tag from any known extensions.
  for(NSString * label in self.extensions)
    {
    NSDictionary * extension = [self.extensions objectForKey: label];
    
    if([NSDictionary isValid: extension])
      {
      NSString * path = [extension objectForKey: @"path"];
      
      if([NSString isValid: path])
        {
        NSDictionary * knownExtension = 
          [knownExtensions objectForKey: path];
          
        if([NSDictionary isValid: knownExtension])
          {
          NSString * obtained_from =
            [knownExtension objectForKey: @"spext_obtained_from"];
          
          if([NSString isValid: obtained_from])
            if([obtained_from isEqualToString: @"spext_apple"])
              {
              NSMutableDictionary * extension =
                [self.extensions objectForKey: label];
              
              if([NSMutableDictionary isValid: extension])
                [extension setObject: @"apple" forKey: @"obtained_from"];
              }
          }
        }
      }
    }
  }
  
// Look for any heretofore unknown extensions.
- (void) checkForUnknownExtensions: (NSDictionary *) knownExtensions
  {
  if(![NSDictionary isValid: knownExtensions])
    return;
    
  // Collect the paths of all current extensions.
  NSMutableSet * extensionPaths = [NSMutableSet set];
  
  for(NSString * label in self.extensions)
    {
    NSDictionary * extension = [self.extensions objectForKey: label];
    
    if([NSDictionary isValid: extension])
      {
      NSString * path = [extension objectForKey: @"path"];
    
      if([NSString isValid: path])
        [extensionPaths addObject: path];
      }
    }
    
  for(NSString * name in knownExtensions)
    {
    NSDictionary * knownExtension = [knownExtensions objectForKey: name];
    
    if(![NSDictionary isValid: knownExtension])
      continue;
      
    NSString * path = [knownExtension objectForKey: @"spext_path"];
    
    if([NSString isValid: path])
      // Do I already know about this extension?
      if([extensionPaths containsObject: path])
        continue;
      
    // Add it to the list.
    NSMutableDictionary * bundle = [self parseExtensionBundle: path];
        
    if([NSMutableDictionary isValid: bundle])
      {
      NSString * identifier = [bundle objectForKey: @"CFBundleIdentifier"];

      NSString * obtained_from =
        [knownExtension objectForKey: @"spext_obtained_from"];
        
      if([NSString isValid: obtained_from])
        if([obtained_from isEqualToString: @"spext_apple"])
          [bundle setObject: @"apple" forKey: @"obtained_from"];
        
      [self.extensions setObject: bundle forKey: identifier];
      }
    }
  }

// Collect 3rd party extensions.
- (NSDictionary *) collectExtensions
  {
  NSDictionary * result = [NSDictionary dictionary];
  
  NSArray * args =
    @[
      @"/Library/Extensions",
      @"-iname",
      @"*.kext"];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  NSString * key = @"kext_list";
  
  [subProcess loadDebugOutput: [self.model debugInputPath: key]];      
  [subProcess saveDebugOutput: [self.model debugOutputPath: key]];
  
  if([subProcess execute: @"/usr/bin/find" arguments: args])
    result = [self parseBundles: subProcess.standardOutput];
    
  [subProcess release];
  
  return result;
  }

// Collect system extensions.
- (NSDictionary *) collectSystemExtensions
  {
  NSDictionary * result = [NSDictionary dictionary];
  
  NSArray * args =
    @[
      @"/System/Library/Extensions",
      @"-iname",
      @"*.kext"];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  NSString * key = @"system_kext_list";
  
  [subProcess loadDebugOutput: [self.model debugInputPath: key]];      
  [subProcess saveDebugOutput: [self.model debugOutputPath: key]];
  
  if([subProcess execute: @"/usr/bin/find" arguments: args])
    result = [self parseBundles: subProcess.standardOutput];
    
  [subProcess release];
  
  return result;
  }

// Collect application support extensions.
- (NSDictionary *) collectApplicationSupportExtensions
  {
  NSDictionary * result = [NSDictionary dictionary];
  
  NSArray * args =
    @[
      @"/Library/Application Support",
      @"-iname",
      @"*.kext"];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  NSString * key = @"app_support_kext_list";
  
  [subProcess loadDebugOutput: [self.model debugInputPath: key]];      
  [subProcess saveDebugOutput: [self.model debugOutputPath: key]];
  
  if([subProcess execute: @"/usr/bin/find" arguments: args])
    result = [self parseBundles: subProcess.standardOutput];
    
  [subProcess release];
  
  return result;
  }

// Collect system application support extensions.
- (NSDictionary *) collectSystemApplicationSupportExtensions
  {
  NSDictionary * result = [NSDictionary dictionary];
  
  NSArray * args =
    @[
      @"/System/Library/Application Support",
      @"-iname",
      @"*.kext"];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  NSString * key = @"system_app_support_kext_list";
  
  [subProcess loadDebugOutput: [self.model debugInputPath: key]];      
  [subProcess saveDebugOutput: [self.model debugOutputPath: key]];
  
  if([subProcess execute: @"/usr/bin/find" arguments: args])
    result = [self parseBundles: subProcess.standardOutput];
    
  [subProcess release];
  
  return result;
  }

// Collect startup item extensions.
- (NSDictionary *) collectStartupItemExtensions
  {
  NSDictionary * result = [NSDictionary dictionary];
  
  NSArray * args =
    @[
      @"/Library/StartupItems",
      @"-iname",
      @"*.kext"];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  NSString * key = @"startupitems_kext_list";
  
  [subProcess loadDebugOutput: [self.model debugInputPath: key]];      
  [subProcess saveDebugOutput: [self.model debugOutputPath: key]];
  
  if([subProcess execute: @"/usr/bin/find" arguments: args])
    result = [self parseBundles: subProcess.standardOutput];
    
  [subProcess release];
  
  return result;
  }

// Collect application extensions.
- (NSDictionary *) collectApplicationExtensions
  {
  NSMutableDictionary * extensions = [NSMutableDictionary dictionary];
  
  if(![NSMutableDictionary isValid: extensions])
    return nil;
    
  NSDictionary * applications = [self.model applications];
  
  if(![NSDictionary isValid: applications])
     return nil;
     
  for(NSString * name in applications)
    {
    NSDictionary * application = [applications objectForKey: name];
    
    if([NSDictionary isValid: applications])
      {
      NSDictionary * applicationExtensions = 
        [self collectExtensionsIn: application];
        
      if([NSDictionary isValid: applicationExtensions])
        [extensions addEntriesFromDictionary: applicationExtensions];
      }
    }
    
  return extensions;
  }

// Collect extensions from a specific application.
- (NSDictionary *) collectExtensionsIn: (NSDictionary *) application
  {
  NSDictionary * extensions = @{};
  
  if(![NSDictionary isValid: application])
    return extensions;
  
  NSString * bundleID = [application objectForKey: @"CFBundleIdentifier"];

  if([NSString isValid: bundleID])
    {
    NSString * obtained_from = [application objectForKey: @"obtained_from"];
    
    if([NSString isValid: obtained_from])
      {
      if([obtained_from isEqualToString: @"apple"])
        return extensions;
       
      // The obtained_from indicator isn't quite good enough.
      if([bundleID hasPrefix: @"com.apple."])
        return extensions;
        
      NSString * path = [application objectForKey: @"path"];
      
      if(![NSString isValid: path])
        return extensions;
        
      NSArray * args =
        @[
          path,
          @"-iname",
          @"*.kext"];
      
      SubProcess * subProcess = [[SubProcess alloc] init];
      
      if([subProcess execute: @"/usr/bin/find" arguments: args])
        extensions = [self parseBundles: subProcess.standardOutput];
        
      [subProcess release];
      
      if(extensions.count > 0)
        [self.model.kernelApps addObject: path];
      }
    }
    
  return extensions;
  }

// Return a dictionary of expanded bundle dictionaries found in a directory.
- (NSDictionary *) parseBundles: (NSData *) data
  {
  NSArray * lines = [Utilities formatLines: data];
  
  NSMutableDictionary * bundles = [NSMutableDictionary dictionary];

  for(NSString * line in lines)
    {
    NSMutableDictionary * bundle = [self parseExtensionBundle: line];
      
    if([NSMutableDictionary isValid: bundle])
      {
      NSString * identifier = [bundle objectForKey: @"CFBundleIdentifier"];

      if([NSString isValid: identifier])
        [bundles setObject: bundle forKey: identifier];
      }
    }
    
  return bundles;
  }

// Parse a single extension bundle.
- (NSMutableDictionary *) parseExtensionBundle: (NSString *) path
  {
  NSString * versionPlist =
    [path stringByAppendingPathComponent: @"Contents/Info.plist"];

  if(![NSString isValid: versionPlist])
    return nil;
    
  NSDictionary * plist = [NSDictionary readPropertyList: versionPlist];

  // Check for inconsistent path from Apple extensions.
  if(![NSDictionary isValid: plist])
    {
    versionPlist = [path stringByAppendingPathComponent: @"Info.plist"];

    if(![NSString isValid: versionPlist])
      return nil;
    
    plist = [NSDictionary readPropertyList: versionPlist];
    }
    
  if([NSDictionary isValid: plist])
    {
    NSString * identifier = [plist objectForKey: @"CFBundleIdentifier"];
    
    if([NSString isValid: identifier])
      {
      NSMutableDictionary * bundle =
        [NSMutableDictionary dictionaryWithDictionary: plist];
      
      if([NSMutableDictionary isValid: bundle])
        {
        NSString * extensionDirectory = [self extensionDirectory: path];
        NSString * name = [path lastPathComponent];
        
        if([NSString isValid: extensionDirectory])
          if([NSString isValid: name])
            {
            // Save the path too.
            [bundle setValue: extensionDirectory forKey: @"path"];
            [bundle setValue: name forKey: @"filename"];
      
            return bundle;
            }
        }
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
    
    if([NSDictionary isValid: bundle])
      {
      NSString * path = [bundle objectForKey: @"path"];
        
      if([NSString isValid: path])
        {
        NSMutableArray * extensions =
          [self.extensionsByLocation objectForKey: path];
          
        if(![NSMutableArray isValid: extensions])
          {
          extensions = [NSMutableArray array];
          
          if([NSMutableArray isValid: extensions])
            [self.extensionsByLocation setObject: extensions forKey: path];
          }
          
        [extensions addObject: label];
        }
      }
    }
  }

// Find loaded extensions.
- (void) findLoadedExtensions
  {
  NSMutableDictionary * loadedExtensions = [NSMutableDictionary new];
  
  if(loadedExtensions == nil)
    return;
    
  NSMutableDictionary * unexpectedExtensions = 
    [NSMutableDictionary new];
  
  if(unexpectedExtensions == nil)
    {
    [loadedExtensions release];
    
    return;
    }
    
  self.loadedExtensions = loadedExtensions;
  self.unexpectedExtensions = unexpectedExtensions;

  [loadedExtensions release];
  [unexpectedExtensions release];
  
  NSArray * args = @[ @"-l" ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  [subProcess loadDebugOutput: [self.model debugInputPath: @"kextstat"]];      
  [subProcess saveDebugOutput: [self.model debugOutputPath: @"kextstat"]];

  if([subProcess execute: @"/usr/sbin/kextstat" arguments: args])
    {
    NSArray * lines = [Utilities formatLines: subProcess.standardOutput];

    for(NSString * line in lines)
      {
      NSString * label = nil;
      NSString * version = nil;

      [self parseKext: line label: & label version: & version];

      if((label != nil) && (version != nil))
        if([NSString isValid: label] && [NSString isValid: version])
          {
          NSDictionary * bundle = [self.extensions objectForKey: label];
          
          if([NSDictionary isValid: bundle])
            [self.loadedExtensions setObject: bundle forKey: label];
            
          else
            {
            bundle =
              [NSDictionary
                dictionaryWithObjectsAndKeys:
                  version, @"CFBundleVersion",
                  label, @"CFBundleIdentifier",
                  nil];
              
            if([NSDictionary isValid: bundle])
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
  NSMutableDictionary * unloadedExtensions = [NSMutableDictionary new];

  if(unloadedExtensions == nil)
    return;
    
  self.unloadedExtensions = unloadedExtensions;

  [unloadedExtensions release];
  
  // The rest must be unloaded.
  for(NSString * label in self.extensions)
    {
    NSDictionary * loadedBundle =
      [self.loadedExtensions objectForKey: label];
    
    if(![NSDictionary isValid: loadedBundle])
      {
      NSMutableDictionary * bundle = [self.extensions objectForKey: label];
      
      if([NSMutableDictionary isValid: bundle])
        [self.unloadedExtensions setObject: bundle forKey: label];
      }
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
  
  if(![NSString isValid: directory])
    return extensions;
    
  NSString * cleanPath = [self cleanPath: directory];
  
  if(![NSString isValid: cleanPath])
    return extensions;

  XMLBuilder * extensionsXML = [XMLBuilder new];
  
  if(extensionsXML == nil)
    return extensions;    

  [extensionsXML startElement: @"directory"];
  
  [extensionsXML addElement: @"cleanpath" value: cleanPath];
  [extensionsXML addElement: @"path" value: directory];
  
  NSString * bundlePath = [Utilities resolveBundlePath: directory];
  
  if([bundlePath hasSuffix: @".app"]) 
    [extensionsXML 
      addElement: @"name" value: [bundlePath lastPathComponent]];
    
  [extensionsXML startElement: @"extensions"];

  NSArray * directoryExtensions = 
    [self.extensionsByLocation objectForKey: directory];
  
  if([NSArray isValid: directoryExtensions])
    {
    NSArray * sortedExtensions =
      [directoryExtensions sortedArrayUsingSelector: @selector(compare:)];

    if([NSArray isValid: sortedExtensions])
      for(NSString * label in sortedExtensions)
        {
        NSAttributedString * output = 
          [self formatExtension: label xmlBuilder: extensionsXML];
        
        // Outpt could be nil if this is an Apple extension.
        if(output != nil)
          [extensions addObject: output];
        }
    }
    
  [extensionsXML endElement: @"extensions"];

  // If I found any non-nil extensions, insert a header for the directory.
  if(extensions.count > 0)
    {
    NSMutableAttributedString * string =
      [[NSMutableAttributedString alloc] initWithString: @""];
    
    NSMutableAttributedString * newline =
      [[NSMutableAttributedString alloc] initWithString: @""];

    if((string != nil) && (newline != nil))
      {
      // This will add a new line at the end.
      [extensions addObject: newline];
      
      NSString * pathline = 
        [[NSString alloc] initWithFormat: @"        %@", cleanPath];
        
      if([NSString isValid: pathline])
        [string
          appendString: pathline
          attributes:
            @{
              NSFontAttributeName : [[Utilities shared] boldFont],
            }];
      
      [pathline release];
      
      [extensions insertObject: string atIndex: 0];
      }
      
    [newline release];
    [string release];
    }
    
  [extensionsXML endElement: @"directory"];
  
  if(extensions.count > 0)
    [self.xml addFragment: extensionsXML.root];
    
  [extensionsXML release];
  
  return extensions;
  }

// Format an extension for output.
- (NSAttributedString *) formatExtension: (NSString *) label 
  xmlBuilder: (XMLBuilder *) xmlBuilder
  {
  if(![NSString isValid: label])
    return nil;
    
  NSDictionary * extension = [self.extensions objectForKey: label];
  
  if(![NSDictionary isValid: extension])
    return nil;
    
  NSString * obtained_from = [extension objectForKey: @"obtained_from"];
  
  if([obtained_from isEqualToString: @"apple"])
    return nil;

  // The obtained_from indicator isn't quite good enough.
  if([label hasPrefix: @"com.apple."])
    return nil;

  NSColor * color = [[Utilities shared] blue];

  NSString * status = @"loaded";
  
  if([self.unloadedExtensions objectForKey: label])
    {
    status = @"notloaded";
    color = [[Utilities shared] gray];

    if([self ignoreUnloadedExtension: label])
      return nil;
    }
    
  return 
    [self 
      formatBundle: label 
      status: status 
      color: color 
      xmlBuilder: xmlBuilder];
  }

// Return a formatted bundle.
- (NSAttributedString *) formatBundle: (NSString * ) label
  status: (NSString *) status 
  color: (NSColor *) color
  xmlBuilder: (XMLBuilder *) xmlBuilder
  {
  NSMutableAttributedString * formattedOutput =
    [[NSMutableAttributedString alloc] init];
    
  [formattedOutput autorelease];
  
  NSDictionary * bundle = [self.extensions objectForKey: label];
  
  if(![NSDictionary isValid: bundle])
    return formattedOutput;
    
  NSString * version = [bundle objectForKey: @"CFBundleShortVersionString"];
  
  if(![NSString isValid: version])
    version = [bundle objectForKey: @"CFBundleVersion"];

  if(![NSString isValid: version])
    return formattedOutput;

  if(![NSString isValid: label])
    return formattedOutput;

  if(![NSString isValid: status])
    return formattedOutput;

  if(color == nil)
    return formattedOutput;
    
  if(xmlBuilder == nil)
    return formattedOutput;
    
  int age = 0;
  
  NSString * OSVersion = [self getOSVersion: bundle age: & age];
    
  [formattedOutput
    appendString: [NSString stringWithFormat: @"    [%@]    ", status]
    attributes:
      [NSDictionary
        dictionaryWithObjectsAndKeys:
          color, NSForegroundColorAttributeName, 
          [[Utilities shared] boldFont], NSFontAttributeName,
          nil]];

  NSString * filename = [bundle objectForKey: @"filename"];
  
  if(![NSString isValid: filename])
    return formattedOutput;

  // Fix the version to get past ASC spam filters.
  version =
    [version stringByReplacingOccurrencesOfString: @"91" withString: @"**"];
  
  [xmlBuilder startElement: @"extension"];
  
  [xmlBuilder addElement: @"bundleid" value: label];
  [xmlBuilder addElement: @"filename" value: filename];
  [xmlBuilder addElement: @"status" value: status];
  [xmlBuilder addElement: @"version" value: version];
  [xmlBuilder addElement: @"osversion" value: OSVersion];  
  
  [xmlBuilder endElement: @"extension"];
  
  NSMutableString * versionString = [NSMutableString new];
  
  if([NSMutableString isValid: versionString])
    {
    [versionString appendString: version];
    
    if([NSString isValid: OSVersion])
      [versionString appendFormat: @" - %@", OSVersion];
    
    [formattedOutput
      appendString:
        [NSString
          stringWithFormat: 
            @"%@ (%@ - %@)", filename, label, versionString]];
          
    NSAttributedString * link = [self getSupportLink: bundle];
    
    if(link != nil)
      [formattedOutput appendAttributedString: link];
    }
  
  [versionString release];
      
  return formattedOutput;
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
