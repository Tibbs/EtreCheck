/***********************************************************************
 ** Etresoft, Inc.
 ** John Daniel
 ** Copyright (c) 2014-2018. All rights reserved.
 **********************************************************************/

#import "Utilities.h"
#import "Model.h"
#import "NSMutableAttributedString+Etresoft.h"
#import <CoreServices/CoreServices.h>
#import "NSDate+Etresoft.h"
#import "NSString+Etresoft.h"
#import <CommonCrypto/CommonDigest.h>
#import "LaunchdCollector.h"
#import "SubProcess.h"
#import "CRC32.h"
#import "EtreCheckConstants.h"
#import "LocalizedString.h"
#import <sqlite3.h>
#import <unistd.h>
#import "OSVersion.h"
#import <sys/attr.h>
#import <sys/stat.h>

// Assorted utilities.
@implementation Utilities

// Create some dynamic properties for the singleton.
@synthesize boldFont = myBoldFont;
@synthesize italicFont = myItalicFont;
@synthesize boldItalicFont = myBoldItalicFont;
@synthesize normalFont = myNormalFont;
@synthesize largerFont = myLargerFont;
@synthesize veryLargeFont = myVeryLargeFont;

@synthesize green = myGreen;
@synthesize blue = myBlue;
@synthesize red = myRed;
@synthesize gray = myGray;

@synthesize unknownMachineIcon = myUnknownMachineIcon;
@synthesize machineNotFoundIcon = myMachineNotFoundIcon;
@synthesize genericApplicationIcon = myGenericApplicationIcon;
@synthesize EtreCheckIcon = myEtreCheckIcon;
@synthesize FinderIcon = myFinderIcon;

@synthesize EnglishBundle = myEnglishBundle;

// Signature checking is expensive.
@synthesize signatureCache = mySignatureCache;

// Date formatters are expensive.
@synthesize dateFormatters = myDateFormatters;

// Return the singeton of shared values.
+ (Utilities *) shared
  {
  static Utilities * utilities = nil;
  
  static dispatch_once_t onceToken;
  
  dispatch_once(
    & onceToken,
    ^{
      utilities = [Utilities new];
    });
    
  return utilities;
  }

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    [self loadFonts];
    [self loadColours];
    [self loadIcons];
    [self loadEnglishStrings];
    
    mySignatureCache = [NSMutableDictionary new];
    myDateFormatters = [NSMutableDictionary new];
    }
    
  return self;
  }

// Destructor.
- (void) dealloc
  {
  [myDateFormatters release];
  [mySignatureCache release];
  [myEnglishBundle release];
  
  [myVeryLargeFont release];
  [myLargerFont release];
  [myNormalFont release];
  [myBoldFont release];
  [myItalicFont release];
  [myBoldItalicFont release];

  [myGreen release];
  [myBlue release];
  [myGray release];
  [myRed release];
  
  [myFinderIcon release];
  [myEtreCheckIcon release];
  [myGenericApplicationIcon release];
  [myUnknownMachineIcon release];
  [myMachineNotFoundIcon release];
  
  return [super dealloc];
  }

// Load fonts.
- (void) loadFonts
  {
  myNormalFont = [[NSFont labelFontOfSize: 12.0] retain];
  myLargerFont = [[NSFont labelFontOfSize: 14.0] retain];
  myVeryLargeFont = [[NSFont labelFontOfSize: 18.0] retain];
  
  myBoldFont =
    [[NSFontManager sharedFontManager]
      convertFont: myNormalFont
      toHaveTrait: NSBoldFontMask];
    
  myItalicFont =
    [[NSFontManager sharedFontManager]
      convertFont: myNormalFont
      toHaveTrait: NSItalicFontMask];

  myBoldItalicFont =
    [NSFont fontWithName: @"Helvetica-BoldOblique" size: 12.0];
    
  [myBoldFont retain];
  [myItalicFont retain];
  [myBoldItalicFont retain];
  }

// Load colours.
- (void) loadColours
  {
  myGreen =
    [NSColor
      colorWithCalibratedRed: 0.2f green: 0.5f blue: 0.2f alpha: 1.0f];
    
  myBlue =
    [NSColor
      colorWithCalibratedRed: 0.0f green: 0.0f blue: 0.6f alpha: 1.0f];

  myGray =
    [NSColor
      colorWithCalibratedRed: 0.4f green: 0.4f blue: 0.4f alpha: 1.0f];

  myRed = [NSColor redColor];
  
  [myGreen retain];
  [myBlue retain];
  [myGray retain];
  [myRed retain];
  }

// Load icons.
- (void) loadIcons
  {
  NSString * resourceDirectory =
    @"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/";
    
  myUnknownMachineIcon =
    [[NSImage alloc]
      initWithContentsOfFile:
        [resourceDirectory
          stringByAppendingPathComponent: @"GenericQuestionMarkIcon.icns"]];

  myMachineNotFoundIcon =
    [[NSImage alloc]
      initWithContentsOfFile:
        [resourceDirectory
          stringByAppendingPathComponent: @"public.generic-pc.icns"]];

  myGenericApplicationIcon =
    [[NSImage alloc]
      initWithContentsOfFile:
        [resourceDirectory
          stringByAppendingPathComponent: @"GenericApplicationIcon.icns"]];
  
  myEtreCheckIcon = [NSImage imageNamed: @"AppIcon"];
  
  [myEtreCheckIcon setSize: NSMakeSize(128, 128)];
  
  myFinderIcon =
    [[NSImage alloc]
      initWithContentsOfFile:
        [resourceDirectory
          stringByAppendingPathComponent: @"FinderIcon.icns"]];
  }

// Load English strings.
- (void) loadEnglishStrings
  {
  NSString * EnglishBundlePath =
    [[NSBundle mainBundle]
      pathForResource: @"Localizable"
      ofType: @"strings"
      inDirectory: nil
      forLocalization: @"en"];


  myEnglishBundle =
    [[NSBundle alloc]
      initWithPath: [EnglishBundlePath stringByDeletingLastPathComponent]];
  }

// Format text into an array of trimmed lines separated by newlines.
+ (NSArray *) formatLines: (NSData *) data
  {
  NSMutableArray * result = [NSMutableArray array];
  
  if(!data)
    return result;
    
  NSString * text =
    [[NSString alloc]
      initWithBytes: [data bytes]
      length: [data length]
      encoding: NSUTF8StringEncoding];
      
  NSArray * lines = [text componentsSeparatedByString: @"\n"];
  
  [text release];
  
  for(NSString * line in lines)
    {
    NSString * trimmedLine =
      [line
        stringByTrimmingCharactersInSet:
          [NSCharacterSet whitespaceAndNewlineCharacterSet]];
          
    if([trimmedLine isEqualToString: @""])
      continue;
      
    [result addObject: trimmedLine];
    }
    
  return result;
  }
  
// Uncompress some data.
+ (NSData *) ungzip: (NSData *) gzipData
  {
  // Create pipes for handling communication.
  NSPipe * inputPipe = [NSPipe new];
  NSPipe * outputPipe = [NSPipe new];
  
  // Create the task itself.
  NSTask * task = [NSTask new];
  
  // Send all task output to the pipe.
  [task setStandardInput: inputPipe];
  [task setStandardOutput: outputPipe];
  
  [task setLaunchPath: @"/usr/bin/gunzip"];

  [task setCurrentDirectoryPath: @"/"];
  
  NSData * result = nil;
  
  @try
    {
    [task launch];
    
    dispatch_async(
      dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
      ^{
        [[[task standardInput] fileHandleForWriting] writeData: gzipData];
        [[[task standardInput] fileHandleForWriting] closeFile];
      });
    
    result =
      [[[task standardOutput] fileHandleForReading] readDataToEndOfFile];
    }
  @catch(NSException * exception)
    {
    }
  @catch(...)
    {
    }
  @finally
    {
    [task release];
    [outputPipe release];
    [inputPipe release];
    }
    
  return result;
  }

// Build a secure URL string.
+ (NSString *) buildSecureURLString: (NSString *) url
  {
  NSString * path = url;
  
  if([path hasPrefix: @"http://"])
    path = [url substringFromIndex: 7];
  else if([path hasPrefix: @"https://"])
    path = [url substringFromIndex: 8];
  
  if([[OSVersion shared] major] <= kMavericks)
    return [@"http://" stringByAppendingString: path];
    
  return [@"https://" stringByAppendingString: path];
  }

// Build a URL.
+ (NSAttributedString *) buildURL: (NSString *) url
  title: (NSString *) title
  {
  NSMutableAttributedString * urlString =
    [[NSMutableAttributedString alloc] initWithString: @""];
    
  [urlString
    appendString: title
    attributes:
      @{
        NSFontAttributeName : [[Utilities shared] boldFont],
        NSForegroundColorAttributeName : [[Utilities shared] blue],
        NSLinkAttributeName : url
      }];
  
  return [urlString autorelease];
  }

// Look for attributes from a file that might depend on the PATH.
+ (NSDictionary *) lookForFileAttributes: (NSString *) path
  {
  NSDictionary * attributes =
    [[NSFileManager defaultManager]
      attributesOfItemAtPath: path error: NULL];
    
  if(attributes)
    return attributes;
    
  NSDictionary * environment = [[NSProcessInfo processInfo] environment];
  
  NSString * PATH = [environment objectForKey: @"PATH"];
  
  if([NSString isValid: PATH])
    {
    NSArray * pathParts = [PATH componentsSeparatedByString: @":"];
    
    for(NSString * dir in pathParts)
      {
      NSString * searchPath = [dir stringByAppendingPathComponent: path];
      
      attributes =
        [[NSFileManager defaultManager]
          attributesOfItemAtPath: searchPath error: NULL];
      
      if(attributes)
        return attributes;
      }
    }
    
  return nil;
  }

// Scan a string from top output.
+ (double) scanTopMemory: (NSScanner *) scanner
  {
  double memValue;
  
  bool found = [scanner scanDouble: & memValue];

  if(!found)
    return 0;

  NSString * units;
  
  found =
    [scanner
      scanCharactersFromSet:
        [NSCharacterSet characterSetWithCharactersInString: @"BKMGT"]
      intoString: & units];

  if(found)
    {
    if([units isEqualToString: @"K"])
      memValue *= 1024;
    else if([units isEqualToString: @"M"])
      memValue *= 1024 * 1024;
    else if([units isEqualToString: @"G"])
      memValue *= 1024 * 1024 * 1024;
    else if([units isEqualToString: @"T"])
      memValue *= 1024 * 1024 * 1024 * 1024;
    }
    
  [scanner scanString: @"+" intoString: NULL];
  
  return memValue;
  }

// Try to get the marketing name directly from Apple.
+ (NSString *) askAppleForMarketingName: (NSString *) serialCode
  language: (NSString *) language type: (NSString *) type
  {
  NSString * marketingName = @"";
  
  if([serialCode length])
    {
    NSURL * url =
      [NSURL
        URLWithString:
          [Utilities
            AppleSupportSPQueryURL: serialCode
            language: language
            type: type]];
    
    marketingName = [Utilities askAppleForMarketingName: url];
    }
    
  return marketingName;
  }

// Try to get the marketing name directly from Apple.
+ (NSString *) askAppleForMarketingName: (NSURL *) url
  {
  NSString * marketingName = @"";
  
  if(url)
    {
    NSError * error = nil;
    
    NSXMLDocument * document =
      [[NSXMLDocument alloc]
        initWithContentsOfURL: url options: 0 error: & error];
    
    if(document)
      {
      NSArray * nodes =
        [document nodesForXPath: @"root/configCode" error: & error];

      if(nodes && [nodes count])
        {
        NSXMLNode * configCodeNode = [nodes objectAtIndex: 0];
        
        // Apple has non-breaking spaces in the results, especially in
        // French but sometimes in English too.
        NSString * nbsp = @"\u00A0";
        
        marketingName =
          [[configCodeNode stringValue]
            stringByReplacingOccurrencesOfString: nbsp withString: @" "];
        }
      
      [document release];
      }
    }
    
  return marketingName;
  }

// Construct an Apple support query URL.
+ (NSString *) AppleSupportSPQueryURL: (NSString *) serialCode
  language: (NSString *) language
  type: (NSString *) type
  {
  NSString * append = @"&";
  
  if([type hasSuffix: @"?"])
    append = @"";
    
  return
    [NSString
      stringWithFormat:
        @"http://support-sp.apple.com/sp/%@%@cc=%@&lang=%@",
        type, append, serialCode, language];
  }

// Verify the signature of an Apple executable.
+ (NSString *) checkAppleExecutable: (NSString *) path
  {
  if(!path.length)
    return kExecutableMissing;
    
  if(![[NSFileManager defaultManager] fileExistsAtPath: path])
    return kExecutableMissing;
      
  if([Utilities isShellExecutable: path])
    return kShell;

  // Get the app path.
  path = [Utilities resolveAppleSignaturePath: path];
    
  NSString * result =
    [[[Utilities shared] signatureCache] objectForKey: path];
  
  if(result != nil)
    return result;
    
  // If I am hiding Apple tasks, then skip Xcode.
  if([[path lastPathComponent] isEqualToString: @"Xcode.app"])
    return kSignatureSkipped;

  NSMutableArray * args = [NSMutableArray array];
  
  [args addObject: @"-vv"];
  [args addObject: @"-R=anchor apple"];
  
  switch([[OSVersion shared] major])
    {
    case kSnowLeopard:
    case kLion:
    case kMountainLion:
      break;
      
    // What a mess.
    case kMavericks:
      if([[OSVersion shared] minor] < 5)
        break;
    default:
      [args addObject: @"--no-strict"];
      break;
    }
    
  [args addObject: path];

  SubProcess * subProcess = [[SubProcess alloc] init];
  
  subProcess.timeout = 60;
  
  // Give Xcode a 10-minute timeout.
  if([[path lastPathComponent] isEqualToString: @"Xcode.app"])
    subProcess.timeout = 10 * 60;
    
  if([subProcess execute: @"/usr/bin/codesign" arguments: args])
    {
    result =
      [Utilities parseSignature: subProcess.standardError forPath: path];
        
    if([result isEqualToString: kSignatureValid])
      result = kSignatureApple;
    
    // Only cache a valid signature.
    if([result isEqualToString: kSignatureApple])
      [[[Utilities shared] signatureCache] setObject: result forKey: path];
    }
  else
    {
    NSLog(@"Returning false from /usr/bin/codesign %@", args);
    result = kCodesignFailed;
    }
    
  [subProcess release];
  
  // Return valid signatures.
  if([result isEqualToString: kNotSigned])
    if([Utilities isShellScript: path])
      return kShell;

  if([result isEqualToString: kSignatureApple])
    return result;

  if([result isEqualToString: kSignatureValid])
    return result;

  // The signature is invalid. If it is in an SIP folder, go ahead
  // and accept it anyway. <sigh>
  if([Utilities isSIP: path])
    return kSignatureApple;

  return result;
  }

// Is this an SIP executable?
+ (BOOL) isSIP: (NSString *) path
  {
  if([[OSVersion shared] major] < kElCapitan)
    return NO;
    
  if([path hasPrefix: @"/usr/libexec/"])
    return YES;
    
  if([path hasPrefix: @"/usr/bin/"])
    return YES;

  if([path hasPrefix: @"/usr/sbin/"])
    return YES;

  if([path hasPrefix: @"/bin/"])
    return YES;

  if([path hasPrefix: @"/sbin/"])
    return YES;

  if([path hasPrefix: @"/System/"])
    return YES;

  return NO;
  }

// Check the signature of an executable.
+ (NSString *) checkExecutable: (NSString *) path
  {
  if(path.length == 0)
    return kExecutableMissing;
    
  if(![[NSFileManager defaultManager] fileExistsAtPath: path])
    return kExecutableMissing;
      
  if([Utilities isShellExecutable: path])
    return kShell;

  path = [Utilities resolveSignaturePath: path];
  
  NSString * result =
    [[[Utilities shared] signatureCache] objectForKey: path];
  
  if(result != nil)
    return result;
    
  NSMutableArray * args = [NSMutableArray array];
  
  [args addObject: @"-vv"];
  [args addObject: @"-R=anchor apple generic"];

  switch([[OSVersion shared] major])
    {
    case kSnowLeopard:
    case kLion:
    case kMountainLion:
      break;
      
    // What a mess.
    case kMavericks:
      if([[OSVersion shared] minor] < 5)
        break;
    default:
      [args addObject: @"--no-strict"];
      break;
    }
    
  [args addObject: path];

  SubProcess * subProcess = [[SubProcess alloc] init];
  
  subProcess.timeout = 60;
  
  if([subProcess execute: @"/usr/bin/codesign" arguments: args])
    {
    result =
      [Utilities parseSignature: subProcess.standardError forPath: path];
      
    [[[Utilities shared] signatureCache] setObject: result forKey: path];
    }
  else
    {
    NSLog(@"Returning false from /usr/bin/codesign %@", args);
    result = kCodesignFailed;
    }
    
  [subProcess release];
  
  if([result isEqualToString: kNotSigned])
    if([Utilities isShellScript: path])
      result = kShell;
    
  return result;
  }

// Check the signature of a shell script interpreter.
+ (NSString *) checkShellScriptExecutable: (NSString *) path
  {
  if(!path.length)
    return kExecutableMissing;
    
  if(![[NSFileManager defaultManager] fileExistsAtPath: path])
    return kExecutableMissing;
      
  NSString * result = nil;
    
  NSMutableArray * args = [NSMutableArray array];
  
  [args addObject: @"-vv"];
  [args addObject: @"-R=anchor apple generic"];
  [args addObject: @"--no-strict"];
  
  [args addObject: path];

  SubProcess * subProcess = [[SubProcess alloc] init];
  
  subProcess.timeout = 60;
  
  if([subProcess execute: @"/usr/bin/codesign" arguments: args])
    {
    result =
      [Utilities parseSignature: subProcess.standardError forPath: path];
    }
  else
    {
    NSLog(@"Returning false from /usr/bin/codesign %@", args);
    result = kCodesignFailed;
    }
    
  [subProcess release];
  
  // Return valid signatures.
  if([result isEqualToString: kSignatureApple])
    return result;

  if([result isEqualToString: kSignatureValid])
    return result;

  // The signature is invalid. If it is in an SIP folder, go ahead
  // and accept it anyway. <sigh>
  if([Utilities isSIP: path])
    return kSignatureApple;

  return result;
  }
  
// Get the developer of an executable.
+ (NSString *) queryDeveloper: (NSString *) path
  {
  if([path length] == 0)
    return nil;
    
  if(![[NSFileManager defaultManager] fileExistsAtPath: path])
    return nil;
      
  if([Utilities isShellExecutable: path])
    return nil;

  NSString * developer = nil;

  NSMutableArray * args = [NSMutableArray array];
  
  [args addObject: @"--assess"];
  [args addObject: @"-vv"];
    
  NSString * appPath = [Utilities resolveSignaturePath: path];
  
  [args addObject: appPath];

  SubProcess * subProcess = [[SubProcess alloc] init];
  
  subProcess.timeout = 60;
  
  if([subProcess execute: @"/usr/sbin/spctl" arguments: args])
    developer =
      [Utilities parseDeveloper: subProcess.standardError forPath: appPath];
  else
    NSLog(@"Returning false from /usr/sbin/spctl %@", args);
    
  [subProcess release];
  
  return developer;
  }

// Get the author and team ID of an executable.
+ (void) query: (NSString *) path 
  author: (NSString **) author team: (NSString **) team
  {
  if([path length] == 0)
    return;
    
  if(![[NSFileManager defaultManager] fileExistsAtPath: path])
    return;
      
  if([Utilities isShellExecutable: path])
    return;

  NSMutableArray * args = [NSMutableArray array];
  
  [args addObject: @"--assess"];
  [args addObject: @"-vv"];
    
  NSString * appPath = [Utilities resolveSignaturePath: path];
  
  [args addObject: appPath];

  SubProcess * subProcess = [[SubProcess alloc] init];
  
  subProcess.timeout = 60;
  
  if([subProcess execute: @"/usr/sbin/spctl" arguments: args])
    [Utilities 
      parse: subProcess.standardError 
      path: appPath 
      author: author 
      team: team];
  else
    NSLog(@"Returning false from /usr/sbin/spctl %@", args);
    
  [subProcess release];
  }
  
// Get the developer of a shell script executable.
+ (NSString *) queryShellScriptDeveloper: (NSString *) path
  {
  if([path length] == 0)
    return nil;
    
  if(![[NSFileManager defaultManager] fileExistsAtPath: path])
    return nil;
      
  NSString * developer = nil;

  NSMutableArray * args = [NSMutableArray array];
  
  [args addObject: @"--assess"];
  [args addObject: @"-vv"];
    
  NSString * appPath = [Utilities resolveSignaturePath: path];
  
  [args addObject: appPath];

  SubProcess * subProcess = [[SubProcess alloc] init];
  
  subProcess.timeout = 60;
  
  if([subProcess execute: @"/usr/sbin/spctl" arguments: args])
    developer =
      [Utilities parseDeveloper: subProcess.standardError forPath: appPath];
  else
    NSLog(@"Returning false from /usr/sbin/spctl %@", args);
    
  [subProcess release];
  
  return developer;
  }

// Is this a shell executable?
+ (bool) isShellExecutable: (NSString *) path
  {
  BOOL shell = NO;
  
  NSString * name = [path lastPathComponent];
  
  if([name isEqualToString: @"tclsh"])
    shell = YES;

  else if([name isEqualToString: @"perl"])
    shell = YES;

  else if([name isEqualToString: @"ruby"])
    shell = YES;

  else if([name hasPrefix: @"python"])
    shell = YES;

  else if([name isEqualToString: @"sh"])
    shell = YES;
    
  else if([name isEqualToString: @"csh"])
    shell = YES;

  else if([name isEqualToString: @"bash"])
    shell = YES;

  else if([name isEqualToString: @"zsh"])
    shell = YES;

  else if([name isEqualToString: @"tsh"])
    shell = YES;

  else if([name isEqualToString: @"ksh"])
    shell = YES;
    
  else if([name isEqualToString: @"php"])
    shell = YES;

  else if([name isEqualToString: @"osascript"])
    shell = YES;

  return shell;
  }

// Is this a shell script?
+ (bool) isShellScript: (NSString *) path
  {
  BOOL shell = NO;
  
  if([path hasSuffix: @".sh"])
    shell = YES;
  
  else if([path hasSuffix: @".csh"])
    shell = YES;
  
  else if([path hasSuffix: @".pl"])
    shell = YES;
  
  else if([path hasSuffix: @".py"])
    shell = YES;
  
  else if([path hasSuffix: @".rb"])
    shell = YES;
  
  else if([path hasSuffix: @".cgi"])
    shell = YES;

  else if([path hasSuffix: @".php"])
    shell = YES;

  else if([path hasSuffix: @".scpt"])
    shell = YES;

  // Check for shebang.
  else
    {
    char buffer[2];
    
    int fd = open([path fileSystemRepresentation], O_RDONLY);
    
    ssize_t size = read(fd, buffer, 2);
    
    if(size == 2)
      if((buffer[0] == '#') && (buffer[1] == '!'))
        shell = YES;
    
    close(fd);
    }
  
  return shell;
  }

// Parse a signature.
+ (NSString *) parseSignature: (NSData *) data
  forPath: (NSString *) path
  {
  NSString * result = kSignatureNotValid;
    
  NSString * output =
    [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
  
  // Make sure this is valid.
  if([NSString isValid: output])
    {
    if([output length])
      {
      NSString * expectedOutput =
        [NSString
          stringWithFormat:
            @"%@: valid on disk\n"
            "%@: satisfies its Designated Requirement\n"
            "%@: explicit requirement satisfied\n",
            path,
            path,
            path];
        
      if([output isEqualToString: expectedOutput])
        result = kSignatureValid;
        
      else
        {
        expectedOutput =
          [NSString
            stringWithFormat:
              @"%@: code object is not signed", path];

        // The wording has changed slightly on this.
        if([output hasPrefix: expectedOutput])
          result = kNotSigned;
        
        else
          {
          expectedOutput =
            [NSString
              stringWithFormat: @"%@: No such file or directory\n", path];

          if([output isEqualToString: expectedOutput])
            result = kExecutableMissing;
          }
        }
      }
    }
    
  [output release];
  
  return result;
  }

// Parse spctl output.
+ (NSString *) parseDeveloper: (NSData *) data
  forPath: (NSString *) path
  {
  NSString * developer = nil;
  
  [self parse: data path: path author: & developer team: NULL];
  
  return developer;
  }

// Parse spctl output.
+ (void) parse: (NSData *) data
  path: (NSString *) path
  author: (NSString **) author
  team: (NSString **) team
  {
  NSArray * lines = [Utilities formatLines: data];
  
  for(NSString * line in lines)
    {
    if([line hasPrefix: @"origin="])
      {
      NSString * origin = [line substringFromIndex: 7];
      
      if([origin hasPrefix: @"Developer ID Application: "])
        {
        NSString * developerID = [origin substringFromIndex: 26];
        
        NSRange endParenRange =
          [developerID rangeOfString: @")" options: NSBackwardsSearch];
          
        NSRange startParenRange =
          [developerID rangeOfString: @"(" options: NSBackwardsSearch];
          
        if(endParenRange.location != NSNotFound)
          if(startParenRange.location != NSNotFound)
            if((endParenRange.location - startParenRange.location) == 11)
              {
              if(author)
                *author =
                  [developerID
                    substringToIndex: startParenRange.location - 1];
              
              if(team)
                *team =
                  [developerID 
                    substringWithRange: 
                      NSMakeRange(startParenRange.location + 1, 10)];
              }
        }
      else if([origin isEqualToString: @"Software Signing"])
        *author = @"Apple, Inc.";
      else if([origin isEqualToString: @"Apple Mac OS Application Signing"])
        *author = @"Mac App Store";
      }
    }
  }

// Create a temporary directory.
+ (NSString *) createTemporaryDirectory
  {
  NSString * template =
    [NSTemporaryDirectory()
      stringByAppendingPathComponent: @"XXXXXXXXXXXX"];
  
  char * buffer = strdup([template fileSystemRepresentation]);
  
  mkdtemp(buffer);
  
  NSString * temporaryDirectory =
    [[NSFileManager defaultManager]
      stringWithFileSystemRepresentation: buffer length: strlen(buffer)];
  
  free(buffer);
  
  return temporaryDirectory;
  }

// Make a path that is suitable for a URL by appending a / for a directory.
+ (NSString *) makeURLPath: (NSString *) path
  {
  BOOL isDirectory = NO;
  
  BOOL exists =
    [[NSFileManager defaultManager]
      fileExistsAtPath: path isDirectory: & isDirectory];
  
  if(exists && isDirectory && ![path hasSuffix: @"/"])
    return [path stringByAppendingString: @"/"];
    
  return path;
  }

// Resolve a deep app path to the wrapper path.
+ (NSString *) resolveBundlePath: (NSString *) path
  {
  NSUInteger appLocation = NSNotFound;
  
  NSRange range = [path rangeOfString: @".app/Contents/MacOS/"];
  
  if(range.location == NSNotFound)
    range = [path rangeOfString: @".app/Contents/Resources/"];

  if(range.location != NSNotFound)
    appLocation = range.location + 4;
    
  range = [path rangeOfString: @".plugin/"];
  
  NSUInteger bundleLocation = NSNotFound;
  
  if(range.location != NSNotFound)
    bundleLocation = range.location + 7;
    
  range = [path rangeOfString: @".bundle/"];
  
  if(range.location != NSNotFound)
    bundleLocation = range.location + 7;

  if((appLocation != NSNotFound) && (bundleLocation != NSNotFound))
    {
    if(bundleLocation < appLocation)
      return [path substringToIndex: bundleLocation];
    else
      return [path substringToIndex: appLocation];
    }
  else if(appLocation != NSNotFound)
    return [path substringToIndex: appLocation];
  else if(bundleLocation != NSNotFound)
    return [path substringToIndex: bundleLocation];
    
  return path;
  }

// Resolve a deep path to a script to the wrapping bundle.
+ (NSString *) resolveBundledScriptPath: (NSString *) path
  {
  NSUInteger appLocation = NSNotFound;
  
  NSRange range = [path rangeOfString: @".app/Contents/MacOS/"];
  
  if(range.location == NSNotFound)
    range = [path rangeOfString: @".app/Contents/Resources/"];

  if(range.location != NSNotFound)
    appLocation = range.location + 4;
    
  range = [path rangeOfString: @".plugin/"];
  
  NSUInteger bundleLocation = NSNotFound;
  
  if(range.location != NSNotFound)
    bundleLocation = range.location + 7;
    
  range = [path rangeOfString: @".bundle/"];
  
  if(range.location != NSNotFound)
    bundleLocation = range.location + 7;

  range = [path rangeOfString: @".framework/"];
  
  if(range.location != NSNotFound)
    bundleLocation = range.location + 10;

  if((appLocation != NSNotFound) && (bundleLocation != NSNotFound))
    {
    if(bundleLocation < appLocation)
      return [path substringToIndex: bundleLocation];
    else
      return [path substringToIndex: appLocation];
    }
  else if(appLocation != NSNotFound)
    return [path substringToIndex: appLocation];
  else if(bundleLocation != NSNotFound)
    return [path substringToIndex: bundleLocation];
    
  return path;
  }

// Resolve a deep app path to the wrapper path for signature checking.
+ (NSString *) resolveAppleSignaturePath: (NSString *) path
  {
  NSUInteger appLocation = NSNotFound;
  
  NSRange range = [path rangeOfString: @".app/Contents/MacOS/"];
  
  if(range.location == NSNotFound)
    range = [path rangeOfString: @".app/Contents/Resources/"];

  if(range.location != NSNotFound)
    appLocation = range.location + 4;
    
  if(appLocation != NSNotFound)
    return [path substringToIndex: appLocation];
    
  return path;
  }

// Resolve a deep app path to the wrapper path for signature checking.
+ (NSString *) resolveSignaturePath: (NSString *) path
  {
  NSUInteger appLocation = NSNotFound;
  
  NSRange range = [path rangeOfString: @".app/Contents/MacOS/"];
  
  if(range.location == NSNotFound)
    range = [path rangeOfString: @".app/Contents/Resources/"];

  if(range.location != NSNotFound)
    appLocation = range.location + 4;
    
  range = [path rangeOfString: @".plugin/"];
  
  NSUInteger bundleLocation = NSNotFound;
  
  if(range.location != NSNotFound)
    bundleLocation = range.location + 7;
    
  if((appLocation != NSNotFound) && (bundleLocation != NSNotFound))
    {
    if(bundleLocation < appLocation)
      return [path substringToIndex: bundleLocation];
    else
      return [path substringToIndex: appLocation];
    }
  else if(appLocation != NSNotFound)
    return [path substringToIndex: appLocation];
  else if(bundleLocation != NSNotFound)
    return [path substringToIndex: bundleLocation];
    
  return path;
  }

// Return a date string.
+ (NSString *) dateAsString: (NSDate *) date
  {
  return [Utilities dateAsString: date format: @"yyyy-MM-dd HH:mm:ss"];
  }
  
// Return a date string in a format.
+ (NSString *) dateAsString: (NSDate *) date format: (NSString *) format
  {
  if(date)
    {
    NSDateFormatter * dateFormatter = [Utilities formatter: format];
    
    return [dateFormatter stringFromDate: date];
    }
    
  return nil;
  }

// Return an install date with consisten text and format.
+ (NSString *) installDateAsString: (NSDate *) date
  {
  if(![NSDate isValid: date])
    return nil;
    
  NSString * modificationDateString =
    [Utilities dateAsString: date format: @"yyyy-MM-dd"];
    
  return
    [NSString
      stringWithFormat: ECLocalizedString(@"installed %@"),
      modificationDateString];
  }

// Return a string as a date.
+ (NSDate *) stringAsDate: (NSString *) dateString
  {
  return
    [Utilities stringAsDate: dateString format: @"yyyy-MM-dd HH:mm:ss"];
  }

// Return a date string in a format.
+ (NSDate *) stringAsDate: (NSString *) dateString
  format: (NSString *) format
  {
  if(dateString)
    {
    NSDateFormatter * dateFormatter = [Utilities formatter: format];
    
    return [dateFormatter dateFromString: dateString];
    }
    
  return nil;
  }

// Return a date formatter.
+ (NSDateFormatter *) formatter: (NSString *) format
  {
  NSDateFormatter * dateFormatter =
    [[[Utilities shared] dateFormatters] objectForKey: format];
    
  if(dateFormatter == nil)
    {
    dateFormatter = [[NSDateFormatter alloc] init];
    
    [dateFormatter setDateFormat: format];
    [dateFormatter setTimeZone: [NSTimeZone localTimeZone]];
    [dateFormatter
      setLocale: [NSLocale localeWithLocaleIdentifier: @"en_US"]];

    [[[Utilities shared] dateFormatters]
      setObject: dateFormatter forKey: format];
      
    [dateFormatter release];
    }
    
  return dateFormatter;
  }

// Try to find the modification date for a path. This will be the most
// recent creation or modification date for any file in the hierarchy.
+ (NSDate *) modificationDate: (NSString *) path
  {
  BOOL isDirectory = NO;
  
  BOOL exists =
    [[NSFileManager defaultManager]
      fileExistsAtPath: path isDirectory: & isDirectory];
  
  if(exists)
    {
    if(!isDirectory)
      return [Utilities fileModificationDate: path];
      
    return [Utilities directoryModificationDate: path];
    }
    
  return nil;
  }

// Try to find the modification date for a file. This will be the most
// recent creation or modification date for the file.
+ (NSDate *) fileModificationDate: (NSString *) path
  {
  NSDictionary * attributes =
    [[NSFileManager defaultManager]
      attributesOfItemAtPath: path error: NULL];
  
  NSDate * modificationDate = [attributes fileModificationDate];
  NSDate * creationDate = [attributes fileCreationDate];
  
  if(creationDate)
    {
    if(modificationDate)
      if([modificationDate isLaterThan: creationDate])
        return modificationDate;
    
    return creationDate;
    }
  
  return nil;
  }

// Try to find the modification date for a path. This will be the most
// recent creation or modification date for any file in the hierarchy.
+ (NSDate *) directoryModificationDate: (NSString *) path
  {
  NSURL * directoryURL = [NSURL fileURLWithPath: path];
  
  NSArray * keys =
    [NSArray
      arrayWithObjects:
        NSURLContentModificationDateKey, NSURLCreationDateKey, nil];
  
  NSDirectoryEnumerator * directoryEnumerator =
   [[NSFileManager defaultManager]
     enumeratorAtURL: directoryURL
       includingPropertiesForKeys: keys
       options: 0
       errorHandler: nil];
 
  NSDate * date = [Utilities fileModificationDate: path];
  
  if(date)
    for(NSURL * fileURL in directoryEnumerator)
      {
      NSDate * modificationDate = nil;
      NSDate * creationDate = nil;
      
      [fileURL
        getResourceValue: & modificationDate
        forKey: NSURLContentModificationDateKey
        error: NULL];
      
      [fileURL
        getResourceValue: & creationDate
        forKey: NSURLCreationDateKey
        error: NULL];

      if([creationDate isLaterThan: date])
        date = creationDate;
        
      if([modificationDate isLaterThan: date])
        date = modificationDate;
      }
    
  return date;
  }

// Send an e-mail.
+ (void) sendEmailTo: (NSString *) toAddress
  withSubject: (NSString *) subject
  content: (NSString *) bodyText
  {
  NSString * emailString =
    [NSString
      stringWithFormat:
        ECLocalizedString(@"addtowhitelistemail"),
        subject, bodyText, @"Etresoft support", toAddress ];


  NSAppleScript * emailScript =
    [[NSAppleScript alloc] initWithSource: emailString];

  [emailScript executeAndReturnError: nil];
  [emailScript release];
  }

+ (NSString *) MD5: (NSString *) string
  {
  if(![string length])
    string = @"";
    
  const char * cstr = [string UTF8String];
  unsigned char md5[16];
  
  CC_MD5(cstr, (CC_LONG)strlen(cstr), md5);

  NSMutableString * result = [NSMutableString string];
  
  for(int i = 0; i < 16; ++i)
    [result appendFormat: @"%02X", md5[i]];
  
  return result;
  }

// Generate a UUID.
+ (NSString *) UUID
  {
  CFUUIDRef uuid = CFUUIDCreate(NULL);

  NSString * result = nil;

  if(uuid)
    {
    result = (NSString *)CFUUIDCreateString(NULL, uuid);

    CFRelease(uuid);
    
    return [result autorelease];
    }
    
  return @"";
  }

// Find files inside an /etc/mach_init* directory.
+ (NSArray *) checkMachInit: (NSString *) path
  {
  NSMutableArray * files = [NSMutableArray array];
  
  // Check the old /etc/mach_init* directories.
  NSArray * mach_init =
    [[NSFileManager defaultManager]
      contentsOfDirectoryAtPath: path error: NULL];
    
  if([mach_init count] > 0)
    for(NSString * file in mach_init)
      [files addObject: [path stringByAppendingPathComponent: file]];
    
  return files;
  }

// Translate a size.
+ (NSString *) translateSize: (NSString *) size
  {
  NSString * sizeSuffix = [Utilities translateSizeSuffix: size];
  
  if([sizeSuffix length] > 0)
    {
    NSString * prefix = [size substringToIndex: [size length] - 2];
    
    return [prefix stringByAppendingString: sizeSuffix];
    }
        
  return size;
  }

// Translate a size suffix.
+ (NSString *) translateSizeSuffix: (NSString *) size
  {
  if([size hasSuffix: @" GB"])
    return ECLocalizedString(@"GB");
    
  else if([size hasSuffix: @" MB"])
    return ECLocalizedString(@"MB");
    
  else if([size hasSuffix: @" TB"])
    return ECLocalizedString(@"TB");
    
  else if([size hasSuffix: @" KB"])
    return ECLocalizedString(@"KB");
    
  else if([size hasSuffix: @" B"])
    return ECLocalizedString(@"B");
    
  return nil;
  }

// Extract the most significant name from a bundle file name.
+ (NSString *) bundleName: (NSString *) path
  {
  if([path length] == 0)
    return nil;
    
  NSString * file = [path lastPathComponent];
  
  NSString * base = [file stringByDeletingPathExtension];
  
  NSArray * parts = [base componentsSeparatedByString: @"."];
  
  NSMutableString * prefix = [NSMutableString string];
  
  // Append the first two parts, if they exist.
  NSString * current = [parts firstObject];
  
  if([current length] == 0)
    return nil;
    
  [prefix appendString: current];
  
  if([parts count] > 1)
    {
    current = [parts objectAtIndex: 1];
  
    if([current length] == 0)
      return nil;

    [prefix appendFormat: @".%@", current];
    }
    
  // Now check for two-letter TLD.
  if(([prefix length] <= 6) && ([parts count] > 2))
    {
    current = [parts objectAtIndex: 2];
  
    if([current length] == 0)
      return nil;

    [prefix appendFormat: @".%@", current];
    }
    
  return [prefix lowercaseString];
  }

// Get the current locale/language code for use in a URL.
+ (NSString *) localeCode
  {
  NSLocale * locale = [NSLocale currentLocale];
  
  NSString * language =
    [[locale objectForKey: NSLocaleLanguageCode] lowercaseString];
  
  NSString * country =
    [[locale objectForKey: NSLocaleCountryCode] lowercaseString];
  
  if((language.length == 0) || (country.length == 0))
    {
    language = @"en";
    country = @"us";
    }
    
  return [NSString stringWithFormat: @"%@-%@", language, country];
  }

// Get the CRC of an NSData.
+ (NSString *) crcData: (NSData *) data
  {
  CRC32 * crc = [CRC32 new];
  
  [crc addData: data];
  
  uint32_t value = crc.value;
  
  [crc release];
  
  return [NSString stringWithFormat: @"%x", value];
  }

// Get the CRC of a file.
+ (NSString *) crcFile: (NSString *) path
  {
  NSData * data = [NSData dataWithContentsOfFile: path];
  
  if(data != nil)
    return [Utilities crcData: data];
    
  return @"0";
  }

// Get parent bundle of a path.
+ (NSString *) getParentBundle: (NSString *) path
  {
  if([path length] == 0)
    return path;
  
  NSRange range = [path rangeOfString: @".app/"];
  
  if(range.location != NSNotFound)
    return [path substringToIndex: range.location + 5];
    
  range = [path rangeOfString: @".plugin/"];
  
  if(range.location != NSNotFound)
    return [path substringToIndex: range.location + 8];

  range = [[path lowercaseString] rangeOfString: @".prefpane/"];
  
  if(range.location != NSNotFound)
    return [path substringToIndex: range.location + 10];

  return path;
  }

// Indent a block of text.
+ (NSString *) indent: (NSString *) text by: (NSString *) indent
  {
  NSMutableArray * parts = 
    [NSMutableArray 
      arrayWithArray: [text componentsSeparatedByString: @"\n"]];
  
  NSString * lastPart = [parts lastObject];
  
  [parts removeLastObject];
  
  NSMutableString * indented = [NSMutableString string];
  
  for(NSString * part in parts)
    {
    [indented appendString: indent];
    [indented appendString: part];
    [indented appendString: @"\n"];
    }
    
  if([lastPart length] > 0)
    {
    [indented appendString: indent];
    [indented appendString: lastPart];
    }
    
  return indented;
  }
  
// Validate the app.
+ (BOOL) validate
  {
  NSString * parrot = ECLocalizedString(@"Canary");
  
  return [parrot isEqualToString: @"Parrot"];
  }
  
// Check file accessibility.
+ (BOOL) checkFile: (NSString *) path 
  hidden: (BOOL *) hidden 
  permissions: (BOOL *) permissions
  locked: (BOOL *) locked
  {
  NSString * expandedPath = [path stringByExpandingTildeInPath];
  
  // Check if the directory appears to be hidden.
  NSArray * parts = 
    [[expandedPath stringByDeletingLastPathComponent] 
      componentsSeparatedByString: @"/"];
  
  int index = 0;
  bool isHidden = false;
  bool isAccessible = true;
  bool isLocked = false;
  BOOL exists = YES;
  
  NSString * userLibrary = 
    [NSHomeDirectory() stringByAppendingPathComponent: @"Library"];
  
  NSString * userApplicationSupport = 
    [userLibrary stringByAppendingPathComponent: @"Application Support"];

  if([parts count] > 1)
    {
    for(NSString * part in parts)
      if(index++ > 0)
        {
        NSString * currentPath = 
          [[parts subarrayWithRange: NSMakeRange(0, index)]
            componentsJoinedByString: @"/"];
            
        if([currentPath isEqualToString: @"/bin"])
          continue;

        if([currentPath isEqualToString: @"/sbin"])
          continue;

        if([currentPath isEqualToString: @"/usr"])
          continue;

        if([currentPath isEqualToString: @"/Library"])
          continue;
          
        if([currentPath isEqualToString: @"/Library/Application Support"])
          continue;

        if([currentPath isEqualToString: userLibrary])
          continue;

        if([currentPath isEqualToString: userApplicationSupport])
          continue;

        if([part hasPrefix: @"."])
          isHidden = true;
          
        if([Utilities isHidden: currentPath])
          isHidden = true;
          
        if([Utilities isImmutable: currentPath])
          isLocked = true;

        if(![Utilities isDirectoryAccessible: currentPath])
          isAccessible = false;
          
        if(isHidden || isLocked || !isAccessible)
          {
          exists = YES;
          break;
          }
          
        if(!isHidden && !isLocked && isAccessible)
          {
          BOOL currentPathExists =
            [[NSFileManager defaultManager] fileExistsAtPath: currentPath];
          
          if(!currentPathExists)
            {
            exists = NO;
            break;
            }
          }
        }
    }
    
  if(!exists)
    return NO;
    
  if([Utilities isHidden: expandedPath])
    isHidden = true;
    
  if([Utilities isImmutable: expandedPath])
    isLocked = false;
    
  BOOL isDirectory = NO;
  
  BOOL fileExists = 
    [[NSFileManager defaultManager] 
      fileExistsAtPath: expandedPath isDirectory: & isDirectory];

  if(fileExists && isDirectory)
    {
    if(![Utilities isDirectoryAccessible: expandedPath])
      isAccessible = false;
    }
  else if(fileExists)
    {
    if(![Utilities isFileAccessible: expandedPath])
      isAccessible = false;
    }
  else if(isHidden || isLocked)
    isAccessible = false;
    
  if(isHidden || isLocked || !isAccessible)
    fileExists = YES;

  if(hidden != NULL)
    *hidden = isHidden;
    
  if(permissions != NULL)
    *permissions = !isAccessible;
    
  if(locked != NULL)
    *locked = isLocked;
    
  return fileExists;
  }
  
// Is a path hidden?
+ (bool) isHidden: (NSString *) path
  {
  bool hidden = false;
  
  struct attrlist attrList;
  
  attrList.bitmapcount = ATTR_BIT_MAP_COUNT;
  attrList.reserved = 0;
  attrList.commonattr = ATTR_CMN_FNDRINFO | ATTR_CMN_FLAGS;
  attrList.volattr = 0;
  attrList.dirattr = 0;
  attrList.fileattr = 0;
  attrList.forkattr = 0;
  
  typedef struct Buffer
    {
    u_int32_t length;
    FileInfo fileInfo;
    ExtendedFileInfo extendedFileInfo;
    u_int32_t flags;
    } Buffer;
    
  Buffer buffer;
  
  int error = 
    getattrlist(
      path.fileSystemRepresentation, 
      & attrList, 
      (void *)& buffer, 
      sizeof(buffer), 
      0);
      
  if(error == 0)
    {
    UInt16 FinderFlags = 
      CFSwapInt16BigToHost(buffer.fileInfo.finderFlags);
      
    if(FinderFlags & kIsInvisible)
      hidden = true;
      
    if(buffer.flags & UF_HIDDEN)
      hidden = true;
    }
    
  return hidden;
  }
  
// Is a directory accessible?
+ (bool) isDirectoryAccessible: (NSString *) path
  {
  NSError * error = nil;
  
  NSArray * contents = 
    [[NSFileManager defaultManager] 
      contentsOfDirectoryAtPath: path error: & error];
      
  if(contents == nil)
    if(error.code == NSFileReadNoPermissionError)
      return false;
      
  return true;
  }
  
// Is a file accessible?
+ (bool) isFileAccessible: (NSString *) path
  {
  int fd = open(path.fileSystemRepresentation, O_RDONLY);
  
  if(fd > 0)
    {
    char buffer[1024];
    
    ssize_t bytesRead = read(fd, buffer, 1024);
    
    close(fd);
    
    if(bytesRead >= 0)
      return true;
    }
  else if(errno == EACCES)
    return false;
    
  return true;
  }

// Is a path read-only?
+ (bool) isImmutable: (NSString *) path
  {
  bool immutable = false;
  
  struct attrlist attrList;
  
  attrList.bitmapcount = ATTR_BIT_MAP_COUNT;
  attrList.reserved = 0;
  attrList.commonattr = ATTR_CMN_FNDRINFO | ATTR_CMN_FLAGS;
  attrList.volattr = 0;
  attrList.dirattr = 0;
  attrList.fileattr = 0;
  attrList.forkattr = 0;
  
  typedef struct Buffer
    {
    u_int32_t length;
    FileInfo fileInfo;
    ExtendedFileInfo extendedFileInfo;
    u_int32_t flags;
    } Buffer;
    
  Buffer buffer;
  
  int error = 
    getattrlist(
      path.fileSystemRepresentation, 
      & attrList, 
      (void *)& buffer, 
      sizeof(buffer), 
      0);
      
  if(error == 0)
    {
    UInt16 FinderFlags = 
      CFSwapInt16BigToHost(buffer.fileInfo.finderFlags);
      
    if(FinderFlags & kNameLocked)
      immutable = true;
      
    if(buffer.flags & (UF_IMMUTABLE | SF_IMMUTABLE))
      immutable = true;
    }
    
  return immutable;
  }

// Compare versions.
+ (BOOL) isVersion: (NSString *) version1 
  laterThanVersion: (NSString *) version2
  {
  NSCharacterSet * betaSet = 
    [NSCharacterSet characterSetWithCharactersInString: @"ab"];

  NSRange betaRange1 = [version1 rangeOfCharacterFromSet: betaSet];
  NSRange betaRange2 = [version2 rangeOfCharacterFromSet: betaSet];
  
  NSString * baseVersion1 = version1;
  NSString * baseVersion2 = version2;
  
  if(betaRange1.location != NSNotFound)
    baseVersion1 = [version1 substringToIndex: betaRange1.location];

  if(betaRange2.location != NSNotFound)
    baseVersion2 = [version2 substringToIndex: betaRange2.location];
    
  NSComparisonResult result = 
    [Utilities compareVersion: baseVersion1 withVersion: baseVersion2];
    
  if(result == NSOrderedSame)
    {
    if(betaRange1.location != NSNotFound)
      {
      if(betaRange2.location != NSNotFound)
        {
        NSString * betaVersion1 = 
          [version1 substringFromIndex: betaRange1.location + 1];

        NSString * betaVersion2 = 
          [version2 substringFromIndex: betaRange2.location + 1];
      
        result = 
          [betaVersion1 
            compare: betaVersion2 
            options: NSCaseInsensitiveSearch | NSNumericSearch];
        }
      else
        return NO;
      }
    else if(betaRange2.location == NSNotFound)
      return NO;
    else
      return YES;
    }
    
  return result == NSOrderedDescending;
  }
  
// Compare versions.
+ (NSComparisonResult) compareVersion: (NSString *) version1 
  withVersion: (NSString *) version2
  {
  NSCharacterSet * set = 
    [NSCharacterSet characterSetWithCharactersInString: @".-"];
    
  NSArray * parts1 = [version1 componentsSeparatedByCharactersInSet: set];
  NSArray * parts2 = [version2 componentsSeparatedByCharactersInSet: set];
  
  NSUInteger index = 0;
  
  while(true)
    {
    NSString * number1 = nil;
    NSString * number2 = nil;
    
    if(index < parts1.count)
      number1 = [parts1 objectAtIndex: index];

    if(index < parts2.count)
      number2 = [parts2 objectAtIndex: index];
      
    if((number1 != nil) && (number2 != nil))
      {
      NSComparisonResult result = 
        [number1 
          compare: number2 
          options: NSCaseInsensitiveSearch | NSNumericSearch];
      
      if(result == NSOrderedDescending)
        return result;
      else if(result == NSOrderedAscending)
        return result;
      }
    else if(number1 != nil)
      return NSOrderedDescending;
    else if(number2 != nil)
      return NSOrderedAscending;
    else
      break;
        
    ++index;
    }
    
  return NSOrderedSame;
  }

// Format an exectuable array for printing, redacting any user names in
// the path.
+ (NSString *) formatExecutable: (NSArray *) parts
  {
  NSMutableArray * mutableParts = [NSMutableArray array];
  
  // Sanitize the whole thing.
  for(NSString * part in parts)
    [mutableParts addObject: [self cleanPath: part]];
    
  return [mutableParts componentsJoinedByString: @" "];
  }

// Make a path more presentable.
+ (NSString *) prettyPath: (NSString *) path
  {
  NSString * cleanPath = [self cleanPath: path];
  
  NSString * name = [cleanPath lastPathComponent];
  
  // What are you trying to hide?
  if([name hasPrefix: @"."])
    cleanPath =
      [NSString
        stringWithFormat:
          ECLocalizedString(@"%@ (hidden)"), cleanPath];

  // Silly Apple.
  else if([name hasPrefix: @"com.apple.CSConfigDotMacCert-"])
    cleanPath = [self sanitizeMobileMe: cleanPath];

  // What are you trying to expose?
  else if([name hasPrefix: @"com.facebook.videochat."])
    cleanPath = [self sanitizeFacebook: cleanPath];

  // What are you trying to expose?
  else if([name hasPrefix: @"com.adobe.ARM."])
    cleanPath = @"com.adobe.ARM.[...].plist";

  return cleanPath;
  }

// Redact a name.
+ (NSString *) cleanName: (NSString *) name
  {
  if([name isEqualToString: @"Macintosh HD"])
    return name;
    
  if([name isEqualToString: @"Preboot"])
    return name;

  if([name isEqualToString: @"Recovery"])
    return name;

  if([name isEqualToString: @"Recovery HD"])
    return name;

  if([name isEqualToString: @"Flash Player"])
    return name;

  if([name isEqualToString: @"Disk Image"])
    return name;

  if([name isEqualToString: @"Volumes"])
    return name;

  if(name.length > 3)
    return 
      [NSString 
        stringWithFormat: 
          @"%@%@%@", 
          [name substringToIndex: 1], 
          [@"*" 
            stringByPaddingToLength: name.length - 2 
            withString: @"*" 
            startingAtIndex: 0],
          [name substringFromIndex: name.length - 1]];
    
  return name;
  }
  
// Redact a mount point.
+ (NSString *) cleanMountPoint: (NSString *) path
  {
  if([path hasPrefix: @"/private/"])
    return path;
    
  NSArray * parts = [path componentsSeparatedByString: @"/"];
  
  NSMutableArray * cleanParts = [[NSMutableArray alloc] init];
  
  for(NSString * part in parts)
    [cleanParts addObject: [self cleanName: part]];
    
  NSString * cleanPath = [cleanParts componentsJoinedByString: @"/"];
  
  [cleanParts release];
  
  return cleanPath;
  }
  
// Redact any user names in a path.
+ (NSString *) cleanPath: (NSString *) path
  {
  if([path hasPrefix: @"/Volumes/"])
    path = [Utilities cleanMountPoint: path];
    
  NSMutableArray * cleanParts = [NSMutableArray array];
  
  // There is no guarantee this is a real path.
  NSArray * parts =
    [path
      componentsSeparatedByCharactersInSet:
        [NSCharacterSet whitespaceAndNewlineCharacterSet]];
  
  for(NSString * pathPart in parts)
    [cleanParts addObject: [self cleanString: pathPart]];
    
  NSString * cleanedPath = [cleanParts componentsJoinedByString: @" "];
  
  return [self cleanString: cleanedPath];
  }

// Redact any user names in a string.
+ (NSString *) cleanString: (NSString *) string
  {
  // Redact an e-mail.
  NSRange emailRange = [string rangeOfString: @"@"];
  
  if(emailRange.location != NSNotFound)
    {
    NSArray * parts = [string componentsSeparatedByString: @"@"];
    
    if(parts.count == 2)
      {
      NSString * account = [parts objectAtIndex: 0];
      NSString * domain = [parts objectAtIndex: 1];
      
      if((account.length > 0) && (domain.length > 0))
        return 
          [NSString
            stringWithFormat:
              @"%@@%@", 
              [self cleanName: account], 
              [self cleanName: domain]];
      }
    }
    
  NSString * username = NSUserName();
  NSString * fullname = NSFullUserName();

  NSMutableSet * names = [NSMutableSet new];
  
  if([username length] > 0)
    [names addObject: username];
    
  if([fullname length] > 0)
    [names addObject: fullname];
    
  [names 
    addObjectsFromArray: [fullname componentsSeparatedByString: @" "]];
  
  [names 
    addObjectsFromArray: [fullname componentsSeparatedByString: @"-"]];

  [names 
    addObjectsFromArray: [fullname componentsSeparatedByString: @"_"]];
      
  NSString * redacted = [string stringByAbbreviatingWithTildeInPath];

  for(NSString * name in names)
    redacted = [self redactName: name from: redacted];
    
  [names release];
  
  // Go ahead and look for an unredacted and unabbreviated user path.
  NSRange range = [redacted rangeOfString: @"/Users/"];

  if(range.location != NSNotFound)
    {
    NSString * pathPart = 
      [redacted substringFromIndex: range.location];
    
    NSArray * pathParts = [pathPart componentsSeparatedByString: @"/"];
    
    redacted = 
      [self redactName: [pathParts objectAtIndex: 2] from: redacted];
    }
    
  return redacted;
  }

// Redact any user names in a string.
+ (NSString *) redactName: (NSString *) name from: (NSString *) string
  {
  NSRange range = NSMakeRange(NSNotFound, 0);

  if([self shouldRedact: name])
    range = [string rangeOfString: name];
  
  if(range.location == NSNotFound)
    return string;
    
  return
    [NSString
      stringWithFormat:
        @"%@%@%@",
        [string substringToIndex: range.location],
        ECLocalizedString(@"[redacted]"),
        [string substringFromIndex: range.location + range.length]];
  }

// Is this a redactable user name?
+ (bool) shouldRedact: (NSString *) username
  {
  NSString * name = [username lowercaseString];
  
  if([name length] < 4)
    return NO;
    
  if([name isEqualToString: @"apple"])
    return NO;
    
  if([name isEqualToString: @"macintosh"])
    return NO;
    
  return YES;
  }

// Apple used to put the user's name into a file name.
+ (NSString *) sanitizeMobileMe: (NSString *) path
  {
  NSString * parent = [path stringByDeletingLastPathComponent];
  NSString * file = [path lastPathComponent];
  
  NSScanner * scanner = [NSScanner scannerWithString: file];

  BOOL found =
    [scanner
      scanString: @"com.apple.CSConfigDotMacCert-" intoString: NULL];

  if(!found)
    return file;
    
  found = [scanner scanUpToString: @"@" intoString: NULL];

  if(!found)
    return file;
    
  NSString * domain = nil;
  
  found = [scanner scanUpToString: @".com-" intoString: & domain];

  if(!found)
    return file;

  found = [scanner scanString: @".com-" intoString: NULL];

  if(!found)
    return file;
    
  NSString * suffix = nil;

  found = [scanner scanUpToString: @"\n" intoString: & suffix];

  if(!found)
    return file;
    
  return
    [parent
      stringByAppendingPathComponent:
        [NSString
          stringWithFormat:
          @"com.apple.CSConfigDotMacCert-%@%@.com-%@",
          ECLocalizedString(@"[redacted]"),
          domain,
          suffix]];
  }

// Facebook puts the users name in a filename too.
+ (NSString *) sanitizeFacebook: (NSString *) file
  {
  NSScanner * scanner = [NSScanner scannerWithString: file];

  BOOL found =
    [scanner
      scanString: @"com.facebook.videochat." intoString: NULL];

  if(!found)
    return file;
    
  [scanner scanUpToString: @".plist" intoString: NULL];

  return
    ECLocalizedString(@"com.facebook.videochat.[redacted].plist");
  }

// Get the OS version.
+ (NSString *) OSVersion
  {
  return [[OSVersion shared] version];
  }
  
@end
