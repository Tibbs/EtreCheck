/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "PlugInsCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Model.h"
#import "Utilities.h"
#import "NSDictionary+Etresoft.h"
#import "SubProcess.h"

// Base class that knows how to handle plug-ins of various types.
@implementation PlugInsCollector

// Parse plugins
- (void) parsePlugins: (NSString *) path
  {
  // Find all the plug-in bundles in the given path.
  NSDictionary * bundles = [self parseFiles: path];
  
  if([bundles count])
    {
    [self.result appendAttributedString: [self buildTitle]];

    for(NSString * filename in bundles)
      {
      NSDictionary * plugin = [bundles objectForKey: filename];

      NSString * path = [plugin objectForKey: @"path"];
      
      NSString * name = [filename stringByDeletingPathExtension];

      NSString * version =
        [plugin objectForKey: @"CFBundleShortVersionString"];

      if(!version)
        version = NSLocalizedString(@"Unknown", NULL);
        
      // Fix the version to get past ASC spam filters.
      version =
        [version
          stringByReplacingOccurrencesOfString: @"91" withString: @"**"];

      int age = 0;
      
      NSString * OSVersion = [self getOSVersion: plugin age: & age];
      
      NSString * date = [self modificationDate: path];
      
      [self.result
        appendString:
          [NSString
            stringWithFormat:
              NSLocalizedString(@"    %@: %@%@%@", NULL),
              name, version, OSVersion, date]];
 
      // Some plug-ins are special.
      if([name isEqualToString: @"JavaAppletPlugin"])
        [self.result
          appendAttributedString: [self getJavaSupportLink: plugin]];
      else if([name isEqualToString: @"Flash Player"])
        [self.result
          appendAttributedString: [self getFlashSupportLink: plugin]];
      else if([[Model model] checkForAdware: path info: nil])
        [self.result
          appendAttributedString: [self getAdwareLink: plugin]];
      else
        [self.result
          appendAttributedString: [self getSupportLink: plugin]];
      
      [self.result appendString: @"\n"];
      }

    [self.result appendString: @"\n"];
    }
  }

// Append the modification date.
- (NSString *) modificationDate: (NSString *) path
  {
  NSDate * modificationDate = [Utilities modificationDate: path];
    
  if(modificationDate)
    {
    NSString * modificationDateString =
      [Utilities dateAsString: modificationDate format: @"yyyy-MM-dd"];
    
    if(modificationDateString)
      return [NSString stringWithFormat: @" (%@)", modificationDateString];
    }
    
  return @"";
  }

// Find all the plug-in bundles in the given path.
- (NSDictionary *) parseFiles: (NSString *) path
  {
  NSArray * args = @[ path, @"-iname", @"*.plugin" ];
  
  NSMutableDictionary * bundles = [NSMutableDictionary dictionary];

  SubProcess * subProcess = [[SubProcess alloc] init];
  
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
              NSLocalizedString(@"Unknown", NULL)
            };

      NSMutableDictionary * bundle =
        [NSMutableDictionary dictionaryWithDictionary: plist];
      
      [bundle setObject: path forKey: @"path"];
      
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
    NSLocalizedString(
      @"https://www.java.com/en/download/installed.jsp", NULL);
  
  if([[Model model] majorOSVersion] < 11)
    url = NSLocalizedString(@"https://support.apple.com/kb/dl1572", NULL);

  [string appendString: @" "];

  [string
    appendString: NSLocalizedString(@"Check version", NULL)
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
        initWithString: NSLocalizedString(@" Cannot contact Adobe", NULL)
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
        initWithData: data encoding:NSUTF8StringEncoding];
    
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
      initWithString: NSLocalizedString(@"Outdated!", NULL)
      attributes:
        [NSDictionary
          dictionaryWithObjectsAndKeys:
            [NSColor redColor], NSForegroundColorAttributeName, nil]];

  [string appendString: @" "];
  [string appendAttributedString: outdated];
  [string appendString: @" "];
  
  [string
    appendString: NSLocalizedString(@"Update", NULL)
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
    appendString: NSLocalizedString(@"Adware!", NULL)
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
