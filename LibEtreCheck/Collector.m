/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014-2017. All rights reserved.
 **********************************************************************/

#import "Collector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Model.h"
#import "Utilities.h"
#import "XMLBuilder.h"
#import "LocalizedString.h"
#import "OSVersion.h"
#import "NSString+Etresoft.h"

@implementation Collector

@synthesize name = myName;
@synthesize title = myTitle;
@synthesize result = myResult;
@synthesize complete = myComplete;
@dynamic done;
@synthesize xml = myXML;
@synthesize model = myModel;
@synthesize simulating = mySimulating;

// Provide easy access to localized collector titles.
+ (NSString *) title: (NSString *) name
  {
  return ECLocalizedStringFromTable(name, @"Collectors");
  }
  
// Is this collector complete?
- (bool) done
  {
  return !dispatch_semaphore_wait(self.complete, DISPATCH_TIME_NOW);
  }

// Constructor.
- (instancetype) initWithName: (NSString *) name
  {
  self = [super init];
  
  if(self)
    {
    myName = [name copy];
    myResult = [NSMutableAttributedString new];
    myFormatter = [NSNumberFormatter new];
    myComplete = dispatch_semaphore_create(0);
    
    self.title = ECLocalizedStringFromTable(self.name, @"Collectors");
    
    myXML = [XMLBuilder new];
    
    [self.xml startElement: self.name];
    }
    
  return self;
  }

// Destructor.
- (void) dealloc
  {
  [myXML release];
  dispatch_release(myComplete);
  [myFormatter release];
  [myResult release];
  [myTitle release];
  [myName release];
  self.model = nil;
  
  [super dealloc];
  }

// Do the collection.
- (void) collect
  {
  [self performCollect];
  
  dispatch_semaphore_signal(self.complete);

  [self.xml endElement: self.name];  
  }

// Simulate the collection.
- (void) simulate
  {
  self.simulating = YES;
  
  [self collect];
  }

// Perform the collection.
- (void) performCollect
  {
  // Derived classes must implement.
  }

// Construct a title with a bold, blue font using a given anchor into
// the online help.
- (NSAttributedString *) buildTitle
  {
  NSMutableAttributedString * string = [NSMutableAttributedString new];
    
  NSString * url =
    [NSString stringWithFormat: @"etrecheck://help/%@", self.name];

  // This has already been localized.
  [string
    appendString: self.title
    attributes:
      @{
        NSFontAttributeName : [[Utilities shared] boldFont],
        NSLinkAttributeName : url
      }];
    
  [string appendString: @" "];
  
  [string
    appendString: ECLocalizedString(@"info")
    attributes:
      @{
        NSFontAttributeName : [[Utilities shared] italicFont],
        NSForegroundColorAttributeName : [[Utilities shared] blue],
        NSLinkAttributeName : url
      }];
    
  [string appendString: @"\n"];
  
  return [string autorelease];
  }

// Convert a program name and optional bundle ID into a DNS-style URL.
- (NSAttributedString *) getSupportURL: (NSString *) name
  bundleID: (NSString *) path
  {
  NSMutableAttributedString * url =
    [[NSMutableAttributedString alloc] initWithString: @""];
    
  NSString * bundleID = [path lastPathComponent];
  
  if([bundleID hasPrefix: @"com.apple."])
    return [url autorelease];
    
  if([bundleID hasSuffix: @".plist"])
    bundleID = [bundleID stringByDeletingPathExtension];

  NSString * query =
    [NSString
      stringWithFormat:
        @"%@%@%@%@",
        ECLocalizedString(@"ascsearch"),
        @"type=discussion&showAnsweredFirst=true&q=",
        bundleID,
        @"&sort=updatedDesc&currentPage=1&includeResultCount=true"];

  [url appendString: @" "];

  [url
    appendString: ECLocalizedString(@"[Lookup]")
    attributes:
      @{
        NSFontAttributeName : [[Utilities shared] boldFont],
        NSForegroundColorAttributeName : [[Utilities shared] blue],
        NSLinkAttributeName : query
      }];
    
  return [url autorelease];
  }

// Extract the (possible) host from a bundle ID.
- (NSString *) convertBundleIdToHost: (NSString *) bundleID
  {
  NSScanner * scanner = [NSScanner scannerWithString: bundleID];
  
  NSString * domain = nil;
  
  if([scanner scanUpToString: @"." intoString: & domain])
    {
    [scanner scanString: @"." intoString: NULL];

    NSString * name = nil;
    
    if([scanner scanUpToString: @"." intoString: & name])
      return [NSString stringWithFormat: @"%@.%@", name, domain];
    }
  
  return nil;
  }

// Get a support link from a bundle.
- (NSAttributedString *) getSupportLink: (NSDictionary *) bundle
  {
  NSString * name = [bundle objectForKey: @"CFBundleName"];
  NSString * bundleID = [bundle objectForKey: @"CFBundleIdentifier"];

  if([NSString isValid: name] && [NSString isValid: bundleID])
    {
    NSAttributedString * supportLink =
      [self getSupportURL: name bundleID: bundleID];
        
    if(supportLink != nil)
      return supportLink;
    }
    
  return [[[NSAttributedString alloc] initWithString: @""] autorelease];
  }

// Try to determine the OS version associated with a bundle.
- (NSString *) getOSVersion: (NSDictionary *) info age: (int *) age
  {
  NSString * version = [self getSDKVersion: info age: age];
  
  if(version)
    return version;
    
  version = [self getSDKName: info age: age];
  
  if(version)
    return version;
    
  version = [self getBuildVersion: info age: age];
  
  if(version)
    return version;
    
  return @"";
  }

// Return the build version of a bundle.
- (NSString *) getBuildVersion: (NSDictionary *) info age: (int *) age
  {
  NSString * buildVersion = [info objectForKey: @"BuildMachineOSBuild"];

  if([NSString isValid: buildVersion])
    {
    NSScanner * scanner = [NSScanner scannerWithString: buildVersion];
    
    int majorVersion = 0;
    
    bool found = [scanner scanInt: & majorVersion];
    
    if(found)
      {
      if(age)
        *age = ([[OSVersion shared] major] - majorVersion);
        
      NSString * minorVersion = nil;
      
      found =
        [scanner
          scanCharactersFromSet:
            [NSCharacterSet
              characterSetWithCharactersInString:
                @"ABCDEFGHIKLMNOPQRSTUVWXYZ"]
              intoString: & minorVersion];
        
      if(found)
        return
          [NSString stringWithFormat: @"OS X 10.%d", majorVersion - 4];
      }
    }
    
  return nil;
  }

// Return the SDKVersion of a bundle.
- (NSString *) getSDKVersion: (NSDictionary *) info age: (int *) age
  {
  NSString * sdkVersion = [info objectForKey: @"DTSDKBuild"];

  if([NSString isValid: sdkVersion])
    {
    NSScanner * scanner = [NSScanner scannerWithString: sdkVersion];
    
    int majorVersion = 0;
    
    bool found = [scanner scanInt: & majorVersion];
    
    if(found && (majorVersion > 3))
      {
      if(age)
        *age = ([[OSVersion shared] major] - majorVersion);
        
      NSString * minorVersion = nil;
      
      found =
        [scanner
          scanCharactersFromSet:
            [NSCharacterSet
              characterSetWithCharactersInString:
                @"ABCDEFGHIKLMNOPQRSTUVWXYZ"]
              intoString: & minorVersion];
        
      if(found)
        return
          [NSString stringWithFormat: @"SDK 10.%d", majorVersion - 4];
      }
    }
    
  return nil;
  }

// Return the SDK name of a bundle.
- (NSString *) getSDKName: (NSDictionary *) info age: (int *) age
  {
  NSString * sdkName = [info objectForKey: @"DTSDKName"];
  
  if([NSString isValid: sdkName])
    {
    NSScanner * scanner = [NSScanner scannerWithString: sdkName];
    
    [scanner scanString: @"macosx10." intoString: NULL];
    
    int majorVersion = 0;
    
    bool found = [scanner scanInt: & majorVersion];
    
    if(found)
      {
      if(age)
        *age = ([[OSVersion shared] major] - majorVersion);
      
      return [NSString stringWithFormat: @"SDK 10.%d", majorVersion - 4];
      }
    }
    
  return nil;
  }

// Find the maximum of two version number strings.
- (NSString *) maxVersion: (NSArray *) versions
  {
  if([versions count] < 2)
    return [versions lastObject];
  
  [myFormatter setNumberStyle: NSNumberFormatterNoStyle];
  
  NSString * version1 = [versions objectAtIndex: 0];
  NSString * version2 = [versions objectAtIndex: 1];
  
  NSCharacterSet * delimiters =
    [NSCharacterSet characterSetWithCharactersInString: @". "];
    
  NSArray * value1 =
    [version1 componentsSeparatedByCharactersInSet: delimiters];
  NSArray * value2 =
    [version2 componentsSeparatedByCharactersInSet: delimiters];
  
  NSUInteger index = 0;

  NSComparisonResult result = NSOrderedSame;
  
  while(result == NSOrderedSame)
    {
    if(index == [value2 count])
      break;
    
    if(index == [value1 count])
      {
      result = NSOrderedAscending;
      
      break;
      }
      
    result =
      [self
        compareValue: [value1 objectAtIndex: index]
        withValue: [value2 objectAtIndex: index]
        formatter: myFormatter];
      
    ++index;
    }
  
  return
    result == NSOrderedAscending
      ? version2
      : version1;
  }

// Compare two values, formatted as numbers, if possible.
- (NSComparisonResult) compareValue: (NSString *) value1
  withValue: (NSString *) value2 formatter: (NSNumberFormatter *) formatter
  {
  NSNumber * numberValue1 = [formatter numberFromString: value1];
  NSNumber * numberValue2 = [formatter numberFromString: value2];

  if(numberValue1 && numberValue2)
    return [numberValue1 compare: numberValue1];
    
  return [value1 compare: value2];
  }

// Generate a "remove adware" link.
- (NSAttributedString *) generateRemoveAdwareLink
  {
  NSMutableAttributedString * urlString =
    [[NSMutableAttributedString alloc] initWithString: @""];
    
  [urlString appendString: @" "];
  
  [urlString
    appendString: ECLocalizedString(@"[Remove]")
    attributes:
      @{
        NSFontAttributeName : [[Utilities shared] boldFont],
        NSForegroundColorAttributeName : [[Utilities shared] red],
        NSLinkAttributeName : @"etrecheck://adware/remove"
      }];
    
  return [urlString autorelease];
  }

// Format an exectuable array for printing, redacting any user names in
// the path.
- (NSString *) formatExecutable: (NSArray *) parts
  {
  NSMutableArray * mutableParts = [NSMutableArray array];
  
  // Sanitize the whole thing.
  for(NSString * part in parts)
    [mutableParts addObject: [self cleanPath: part]];
    
  return [mutableParts componentsJoinedByString: @" "];
  }

// Make a path more presentable.
- (NSString *) prettyPath: (NSString *) path
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
- (NSString *) cleanName: (NSString *) name
  {
  if([name isEqualToString: @"Macintosh HD"])
    return name;
    
  if([name isEqualToString: @"Recovery HD"])
    return name;

  if([name isEqualToString: @"Flash Player"])
    return name;

  if([name isEqualToString: @"Disk Image"])
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
  
// Redact any user names in a path.
- (NSString *) cleanPath: (NSString *) path
  {
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
- (NSString *) cleanString: (NSString *) string
  {
  if([string hasSuffix: @"@me.com"])
    return
      [NSString
        stringWithFormat:
          @"%@@me.com", ECLocalizedString(@"[redacted]")];

  if([string hasSuffix: @"@mac.com"])
    return
      [NSString
        stringWithFormat:
          @"%@@mac.com", ECLocalizedString(@"[redacted]")];

  // See if the full user name is in the computer name.
  NSString * computerName = [self.model computerName];
  NSString * hostName = [self.model hostName];
    
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
      
  if([computerName length] > 0)
    [names addObject: computerName];
    
  if([hostName length] > 0)
    [names addObject: hostName];

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
- (NSString *) redactName: (NSString *) name from: (NSString *) string
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
- (bool) shouldRedact: (NSString *) username
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
- (NSString *) sanitizeMobileMe: (NSString *) path
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
- (NSString *) sanitizeFacebook: (NSString *) file
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

@end
