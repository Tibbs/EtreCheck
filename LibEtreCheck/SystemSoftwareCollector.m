/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014-2017. All rights reserved.
 **********************************************************************/

#import "SystemSoftwareCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Model.h"
#import "Utilities.h"
#import "TTTLocalizedPluralString.h"
#import "SubProcess.h"
#import "LaunchdCollector.h"
#import "XMLBuilder.h"
#import "NSArray+Etresoft.h"
#import "NSDictionary+Etresoft.h"
#import "EtreCheckConstants.h"

// Collect system software information.
@implementation SystemSoftwareCollector

// Constructor.
- (id) init
  {
  self = [super initWithName: @"systemsoftware"];
  
  if(self != nil)
    {
    }
    
  return self;
  }

// Perform the collection.
- (void) performCollect
  {
  [self.result appendAttributedString: [self buildTitle]];
  
  BOOL dataFound = NO;
  
  NSArray * args =
    @[
      @"-xml",
      @"SPSoftwareDataType"
    ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  if([subProcess execute: @"/usr/sbin/system_profiler" arguments: args])
    {
    NSArray * plist =
      [NSArray readPropertyListData: subProcess.standardOutput];
  
    if(plist && [plist count])
      {
      NSArray * items =
        [[plist objectAtIndex: 0] objectForKey: @"_items"];
        
      if([items count])
        for(NSDictionary * item in items)
          if([self printSystemSoftware: item])
            {
            dataFound = YES;
            [self.result appendCR];
            break;
            }
      }
    }
    
  [subProcess release];
    
  // Load the software signatures and expected launchd files. Even if no
  // data was found, we will assume 10.12.6 just to keep the output clean 
  // and still print a failure message next.
  [self loadAppleSoftware];
  [self loadAppleLaunchd];
  
  if(!dataFound)
    {
    [self.result
      appendString:
        NSLocalizedString(
          @"    Operating system information not found!\n", NULL)
      attributes:
        @{
          NSFontAttributeName : [[Utilities shared] boldFont],
          NSForegroundColorAttributeName : [[Utilities shared] red]
        }];
        
    [self.result appendCR];
    }
  }

// Load Apple software.
- (void) loadAppleSoftware
  {
  NSString * softwarePath =
    [[NSBundle mainBundle]
      pathForResource: @"appleSoftware" ofType: @"plist"];
    
  NSData * plistData = [NSData dataWithContentsOfFile: softwarePath];
  
  if(plistData)
    {
    NSDictionary * plist = [NSDictionary readPropertyListData: plistData];
  
    if(plist)
      {
      int version = [[Model model] majorOSVersion];
      
      switch(version)
        {
        case kSnowLeopard:
          [self loadAppleSoftware: [plist objectForKey: @"10.6"]];
          break;
        case kLion:
          [self loadAppleSoftware: [plist objectForKey: @"10.7"]];
          break;
        case kMountainLion:
          [self loadAppleSoftware: [plist objectForKey: @"10.8"]];
          break;
        case kMavericks:
          [self loadAppleSoftware: [plist objectForKey: @"10.9"]];
          break;
        case kYosemite:
          [self loadAppleSoftware: [plist objectForKey: @"10.10"]];
          break;
        case kElCapitan:
          [self loadAppleSoftware: [plist objectForKey: @"10.11"]];
          break;
        default:
          [self loadAppleSoftware: [plist objectForKey: @"10.12"]];
          break;
        }
      }
    }
  }

// Load apple software for a specific OS version.
- (void) loadAppleSoftware: (NSDictionary *) software
  {
  if(software)
    [[Model model] setAppleSoftware: software];
  }

// Load Apple launchd files.
- (void) loadAppleLaunchd
  {
  NSString * launchdPath =
    [[NSBundle mainBundle]
      pathForResource: @"appleLaunchd" ofType: @"plist"];
    
  NSData * plistData = [NSData dataWithContentsOfFile: launchdPath];
  
  if(plistData)
    {
    NSDictionary * plist = [NSDictionary readPropertyListData: plistData];
  
    if(plist)
      {
      int version = [[Model model] majorOSVersion];
      
      switch(version)
        {
        case kSnowLeopard:
          [self loadAppleLaunchd: [plist objectForKey: @"10.6"]];
          break;
        case kLion:
          [self loadAppleLaunchd: [plist objectForKey: @"10.7"]];
          break;
        case kMountainLion:
          [self loadAppleLaunchd: [plist objectForKey: @"10.8"]];
          break;
        case kMavericks:
          [self loadAppleLaunchd: [plist objectForKey: @"10.9"]];
          break;
        case kYosemite:
          [self loadAppleLaunchd: [plist objectForKey: @"10.10"]];
          break;
        case kElCapitan:
          [self loadAppleLaunchd: [plist objectForKey: @"10.11"]];
          break;
        case kSierra:
          [self loadAppleLaunchd: [plist objectForKey: @"10.12"]];
          break;
        case kHighSierra:
        default:
          [self loadAppleLaunchd: [plist objectForKey: @"10.13"]];
          break;
        }
      }
    }
  }

// Load apple launchd files for a specific OS version.
- (void) loadAppleLaunchd: (NSDictionary *) launchdFiles
  {
  if(launchdFiles)
    {
    [[Model model] setAppleLaunchd: launchdFiles];
    
    NSMutableDictionary * appleLaunchdByLabel = [NSMutableDictionary new];
    
    for(NSString * path in launchdFiles)
      {
      NSDictionary * info = [launchdFiles objectForKey: path];
      
      NSString * label = [info objectForKey: kLabel];
      
      if([label length] > 0)
        [appleLaunchdByLabel setObject: info forKey: label];
      }
      
    [[Model model] setAppleLaunchdByLabel: appleLaunchdByLabel];
    
    [appleLaunchdByLabel release];
    }
  }

// Print a system software item.
- (BOOL) printSystemSoftware: (NSDictionary *) item
  {
  NSString * version = [item objectForKey: @"os_version"];
  NSString * uptime = [item objectForKey: @"uptime"];

  if(![self parseOSVersion: version])
    return NO;
  
  if(![self parseOSBuild: version])
    return NO;

  NSString * OSName = nil;
  
  NSString * marketingName = 
    [self fallbackMarketingName: version name: & OSName];
  
  [self.model addElement: @"name" value: OSName];
  [self.model addElement: @"version" value: [[Model model] OSVersion]];
  [self.model addElement: @"build" value: [[Model model] OSBuild]];
  
  int days = 0;
  int hours = 0;

  BOOL parsed = [self parseUpTime: uptime days: & days hours: & hours];
  
  if(!parsed)
    {
    [self.model addElement: @"uptime" value: uptime];
    
    [self.result
      appendString:
        [NSString
          stringWithFormat:
            NSLocalizedString(@"    %@ - Uptime: %@%@\n", NULL),
            marketingName,
            @"",
            uptime]];
            
    return YES;
    }
    
  int uptimeValue = (days * 24);
  
  if(uptimeValue == 0)
    uptimeValue += hours;
    
  [self.model 
    addElement: @"uptime" 
    intValue: uptimeValue
    attributes: 
      [NSDictionary dictionaryWithObjectsAndKeys: @"hours", @"units", nil]];

  NSString * dayString = TTTLocalizedPluralString(days, @"day", nil);
  NSString * hourString = TTTLocalizedPluralString(hours, @"hour", nil);
  
  if(days > 0)
    hourString = @"";
    
  [self.result
    appendString:
      [NSString
        stringWithFormat:
          NSLocalizedString(@"    %@ - Uptime: %@%@\n", NULL),
          marketingName,
          dayString,
          hourString]];
          
  return YES;
  }

// Query Apple for the marketing name.
// Don't even bother with this.
- (NSString *) marketingName: (NSString *) version
  {
  NSString * language = NSLocalizedString(@"en", NULL);
  
  NSURL * url =
    [NSURL
      URLWithString:
        [NSString
          stringWithFormat:
            @"http://support-sp.apple.com/sp/product?edid=10.%d&lang=%@",
            [[Model model] majorOSVersion] - 4,
            language]];
  
  NSString * marketingName = [Utilities askAppleForMarketingName: url];
  NSString * OSName = nil;
  
  if([marketingName length] && ([[Model model] majorOSVersion] >= kLion))
    {
    marketingName =
      [marketingName
        stringByAppendingString: [version substringFromIndex: 4]];
    }
  else
    return [self fallbackMarketingName: version name: & OSName];
    
  return marketingName;
  }

// Get a fallback marketing name.
- (NSString *) fallbackMarketingName: (NSString *) version 
  name: (NSString **) OSName
  {
  NSString * fallbackMarketingName = version;
  
  NSString * OSType = @"OS X";
  NSString * name = nil;
  int offset = 5;
  
  switch([[Model model] majorOSVersion])
    {
    case kSnowLeopard:
      name = @"Snow Leopard";
      offset = 9;
      break;
      
    case kLion:
      name = @"Lion";
      offset = 9;
      break;
      
    case kMountainLion:
      name = @"Mountain Lion";
      break;
      
    case kMavericks:
      name = @"Mavericks";
      break;
      
    case kYosemite:
      name = @"Yosemite";
      break;
      
    case kElCapitan:
      name = @"El Capitan";
      break;
      
    case kSierra:
      OSType = @"macOS";
      name = @"Sierra";
      break;

    case kHighSierra:
      OSType = @"macOS";
      name = @"High Sierra";
      break;

    default:
      return version;
    }
    
  *OSName = [NSString stringWithFormat: @"%@ %@", OSType, name];
  
  fallbackMarketingName =
    [NSString
      stringWithFormat:
        @"%@ %@", *OSName, [version substringFromIndex: offset]];
  
  return fallbackMarketingName;
  }

// Parse the OS version.
- (BOOL) parseOSVersion: (NSString *) profilerVersion
  {
  BOOL result = NO;
  
  if([profilerVersion length] > 0)
    {
    NSScanner * scanner = 
      [[NSScanner alloc] initWithString: profilerVersion];
    
    [scanner scanUpToString: @"(" intoString: NULL];
    [scanner scanString: @"(" intoString: NULL];
    
    NSString * buildVersion = nil;
      
    bool found = [scanner scanUpToString: @")" intoString: & buildVersion];
      
    if(found)
      found = [self parseBuildVersion: buildVersion];
    
    [scanner release];
    
    if(found)
      result = YES;
    }
    
  // Sometimes this doesn't work in extreme cases. Keep trying.
  if(!result)
    {
    NSArray * args = @[@"-buildVersion"];
    
    SubProcess * subProcess = [[SubProcess alloc] init];
    
    if([subProcess execute: @"/usr/bin/sw_vers" arguments: args])
      {
      NSString * buildVersion = 
        [[NSString alloc] 
          initWithData: subProcess.standardOutput 
          encoding: NSUTF8StringEncoding];
       
      if([buildVersion length] > 0)
        result = [self parseBuildVersion: buildVersion];
        
      [buildVersion release];
      }
      
    [subProcess release];
    }
    
  // If I have a system version, set the verification flag.
  if(result)
    [[Model model] setVerifiedSystemVersion: YES];
    
  // Otherwise, just pick Sierra but keep the flag off.
  else
    {
    [[Model model] setMajorOSVersion: 16];
    [[Model model] setMinorOSVersion: 6];
    }
    
  return result;
  }

// Parse a build version.
- (bool) parseBuildVersion: (NSString *) buildVersion
  {
  NSScanner * scanner = [[NSScanner alloc] initWithString: buildVersion];
    
  int majorVersion = 0;
  
  bool found = [scanner scanInt: & majorVersion];
  
  if(found)
    {
    [[Model model] setMajorOSVersion: majorVersion];
    
    NSString * minorVersion = nil;
    
    found = [scanner scanUpToString: @")" intoString: & minorVersion];
    
    if(found)
      {
      unichar ch;
      
      [minorVersion getCharacters: & ch range: NSMakeRange(0, 1)];
      
      [[Model model] setMinorOSVersion: ch - 'A'];
      }
    }
    
  [scanner release];
  
  return found;
  }

// Parse the OS build.
- (BOOL) parseOSBuild: (NSString *) profilerVersion
  {
  if(profilerVersion)
    {
    NSScanner * scanner = [NSScanner scannerWithString: profilerVersion];
    
    [scanner scanUpToString: @"10." intoString: NULL];

    NSString * version = nil;
    
    bool found = [scanner scanUpToString: @" (" intoString: & version];
    
    if(found)
      {
      [[Model model] setOSVersion: version];
      
      [scanner scanString: @"(" intoString: NULL];
      
      NSString * build = nil;
      
      found = [scanner scanUpToString: @")" intoString: & build];
      
      if(found)
        {
        [[Model model] setOSBuild: build];
        
        return YES;
        }
      }
    }
    
  return NO;
  }

// Parse system uptime.
- (bool) parseUpTime: (NSString *) uptime
  days: (int *) days hours: (int *) hours
  {
  NSScanner * scanner = [NSScanner scannerWithString: uptime];

  bool found = [scanner scanString: @"up " intoString: NULL];

  if(!found)
    return found;

  found = [scanner scanInt: days];

  if(!found)
    return found;

  found = [scanner scanString: @":" intoString: NULL];

  if(!found)
    return found;

  found = [scanner scanInt: hours];
  
  if(*hours >= 18)
    ++*days;
    
  return found;
  }

@end
