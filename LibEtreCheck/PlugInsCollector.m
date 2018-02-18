/***********************************************************************
 ** Etresoft, Inc.
 ** John Daniel
 ** Copyright (c) 2014-2018. All rights reserved.
 **********************************************************************/

#import "PlugInsCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Model.h"
#import "Utilities.h"
#import "NSDictionary+Etresoft.h"
#import "SubProcess.h"
#import "XMLBuilder.h"
#import "LocalizedString.h"
#import "OSVersion.h"
#import "NSString+Etresoft.h"
#import "NSDictionary+Etresoft.h"
#import "NSDate+Etresoft.h"

// Base class that knows how to handle plug-ins of various types.
@implementation PlugInsCollector

// Parse plugins
- (void) parsePlugins: (NSString *) path
  {
  if(![NSString isValid: path])
    return;
    
  // Find all the plug-in bundles in the given path.
  NSDictionary * bundles = [self parseFiles: path];
  
  if(self.simulating && ([bundles count] == 0))
    {
    NSString * pluginPath = 
      [path stringByAppendingPathComponent: @"Simulated.plugin"];
      
    NSString * name = [pluginPath lastPathComponent];
    
    bundles = 
      [NSDictionary 
        dictionaryWithObject: 
          [NSDictionary 
            dictionaryWithObjectsAndKeys:
            [self cleanPath: pluginPath], @"path", 
            @"1.0", @"CFBundleShortVersionString", 
            nil] 
        forKey: name];
    }
    
  if([bundles count])
    {
    [self.result appendAttributedString: [self buildTitle]];

    for(NSString * filename in bundles)
      {
      NSDictionary * plugin = [bundles objectForKey: filename];

      if(![NSDictionary isValid: plugin])
        continue;
        
      NSString * name = [filename stringByDeletingPathExtension];

      NSString * version =
        [plugin objectForKey: @"CFBundleShortVersionString"];

      if(!version)
        version = ECLocalizedString(@"Unknown");
        
      // Fix the version to get past ASC spam filters.
      version =
        [version
          stringByReplacingOccurrencesOfString: @"91" withString: @"**"];

      NSDate * modificationDate = [plugin objectForKey: @"date"];
      NSString * modificationDateString = @"";
        
      if([NSDate isValid: modificationDate])
        {
        modificationDateString =
          [Utilities installDateAsString: modificationDate];
        
        modificationDateString =
          [NSString stringWithFormat: @" (%@)", modificationDateString];
        }
        
      [self.xml startElement: @"plugin"];
      
      [self.xml addElement: @"name" value: name];
      [self.xml addElement: @"version" value: version];
      [self.xml addElement: @"installdate" date: modificationDate];
      
      [self.xml endElement: @"plugin"];
      
      [self.result
        appendString:
          [NSString
            stringWithFormat:
              ECLocalizedString(@"    %@: %@%@"),
              name, version, modificationDateString]];
 
      // Some plug-ins are special.
      if([name isEqualToString: @"JavaAppletPlugin"])
        [self.result
          appendAttributedString: [self getJavaSupportLink: plugin]];
      
      else if([name isEqualToString: @"Flash Player"])
        [self.result
          appendAttributedString: [self getFlashSupportLink: plugin]];
      
      else if([name isEqualToString: @"Flash Player-10.6"])
        [self.result
          appendAttributedString: [self getFlashSupportLink: plugin]];
      
      else
        [self.result
          appendAttributedString: [self getSupportLink: plugin]];
      
      [self.result appendString: @"\n"];
      }

    [self.result appendString: @"\n"];
    }
  }

// Find all the plug-in bundles in the given path.
- (NSDictionary *) parseFiles: (NSString *) path
  {
  NSArray * args = 
    @[path, @"-iname", @"*.plugin", @"-or", @"-iname", @"*.plugin"];
  
  NSMutableDictionary * bundles = [NSMutableDictionary dictionary];

  SubProcess * subProcess = [[SubProcess alloc] init];
  
  NSString * key = 
    [path stringByReplacingOccurrencesOfString: @"/" withString: @"_"];
  
  [subProcess loadDebugOutput: [self.model debugInputPath: key]];      
  [subProcess saveDebugOutput: [self.model debugOutputPath: key]];

  if([subProcess execute: @"/usr/bin/find" arguments: args])
    {
    NSArray * paths = [Utilities formatLines: subProcess.standardOutput];
    
    for(NSString * path in paths)
      {
      NSString * filename = [path lastPathComponent];

      NSString * versionPlist =
        [path stringByAppendingPathComponent: @"Contents/Info.plist"];

      NSDictionary * plist = [NSDictionary readPropertyList: versionPlist];

      if(!plist)
        plist =
          @{
            @"CFBundleShortVersionString" :
              ECLocalizedString(@"Unknown")
            };

      NSMutableDictionary * bundle =
        [NSMutableDictionary dictionaryWithDictionary: plist];
      
      NSDate * modificationDate = [Utilities modificationDate: path];

      if(modificationDate != nil)
        [bundle setObject: modificationDate forKey: @"date"];
      
      [bundle setObject: [self cleanPath: path] forKey: @"path"];
      
      [bundles setObject: bundle forKey: filename];
      }
    }
    
  [subProcess release];
  
  return bundles;
  }

// Construct a Java support link.
- (NSAttributedString *) getJavaSupportLink: (NSDictionary *) plugin
  {
  NSMutableAttributedString * string =
    [[NSMutableAttributedString alloc] initWithString: @""];

  NSString * url =
    ECLocalizedString(
      @"https://www.java.com/en/download/installed.jsp");
  
  if([[OSVersion shared] major] < 11)
    url = @"https://support.apple.com/kb/dl1572";

  [string appendString: @" "];

  [string
    appendString: ECLocalizedString(@"Check version")
    attributes:
      @{
        NSFontAttributeName : [[Utilities shared] boldFont],
        NSForegroundColorAttributeName : [[Utilities shared] gray],
        NSLinkAttributeName : url
      }];
   
  return [string autorelease];
  }

// Construct a Flash support link.
- (NSAttributedString *) getFlashSupportLink: (NSDictionary *) plugin
  {
  NSString * version =
    [plugin objectForKey: @"CFBundleShortVersionString"];

  NSString * currentVersion = [self currentFlashVersion];
  
  if(!currentVersion)
    return
      [[[NSMutableAttributedString alloc]
        initWithString: ECLocalizedString(@" Cannot contact Adobe")
        attributes:
          [NSDictionary
            dictionaryWithObjectsAndKeys:
              [NSColor redColor], NSForegroundColorAttributeName, nil]]
        autorelease];
    
  NSComparisonResult result =
    [Utilities compareVersion: version withVersion: currentVersion];
  
  if(result == NSOrderedAscending)
    return [self outdatedFlash];
  else
    return [self getSupportLink: plugin];
  }

// Get the current Flash version.
- (NSString *) currentFlashVersion
  {
  NSString * version = nil;
  
  NSURL * url =
    [NSURL URLWithString: @"https://www.adobe.com/software/flash/about/"];
  
  NSData * data = [NSData dataWithContentsOfURL: url];
  
  if(data)
    {
    NSString * content =
      [[NSString alloc]
        initWithData: data encoding: NSUTF8StringEncoding];
    
    // Make sure this is valid.
    if([NSString isValid: content])
      {
      NSScanner * scanner = [NSScanner scannerWithString: content];
    
      [scanner scanUpToString: @"Macintosh" intoString: NULL];
      [scanner scanUpToString: @"<td>" intoString: NULL];
      [scanner scanString: @"<td>" intoString: NULL];
      [scanner scanUpToString: @"<td>" intoString: NULL];
      [scanner scanString: @"<td>" intoString: NULL];

      NSString * currentVersion = nil;
      
      bool scanned =
        [scanner scanUpToString: @"</td>" intoString: & currentVersion];
      
      if(scanned)
        version = currentVersion;
      }
      
    [content release];
    }
    
  return version;
  }

// Return an outdated Flash version.
- (NSAttributedString *) outdatedFlash
  {
  NSMutableAttributedString * string =
    [[NSMutableAttributedString alloc] initWithString: @""];
  
  NSAttributedString * outdated =
    [[NSAttributedString alloc]
      initWithString: ECLocalizedString(@"Outdated!")
      attributes:
        [NSDictionary
          dictionaryWithObjectsAndKeys:
            [NSColor redColor], NSForegroundColorAttributeName, nil]];

  [string appendString: @" "];
  [string appendAttributedString: outdated];
  [string appendString: @" "];
  
  [string
    appendString: ECLocalizedString(@"Update")
    attributes:
      @{
        NSFontAttributeName : [[Utilities shared] boldFont],
        NSForegroundColorAttributeName : [[Utilities shared] red],
        NSLinkAttributeName : @"https://get.adobe.com/flashplayer/"
      }];
  
  [outdated release];
  
  return [string autorelease];
  }

// Construct an adware link.
- (NSAttributedString *) getAdwareLink: (NSDictionary *) plugin
  {
  NSMutableAttributedString * extra =
    [[NSMutableAttributedString alloc] init];

  [extra appendString: @" "];

  [extra
    appendString: ECLocalizedString(@"Adware!")
    attributes:
      @{
        NSForegroundColorAttributeName : [[Utilities shared] red],
        NSFontAttributeName : [[Utilities shared] boldFont]
      }];      

  NSAttributedString * removeLink = [self generateRemoveAdwareLink];

  if(removeLink)
    {
    [extra appendString: @" "];

    [extra appendAttributedString: removeLink];
    }
    
  return [extra autorelease];
  }

// Parse user plugins
- (void) parseUserPlugins: (NSString *) type path: (NSString *) path
  {
  [self
    parsePlugins: [NSHomeDirectory() stringByAppendingPathComponent: path]];
  }

@end
