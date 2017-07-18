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
#import "NSArray+Etresoft.h"
#import "SubProcess.h"
#import "LaunchdCollector.h"

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
    
  // There should always be data found.
  if(dataFound)
    {
    // Now that I know what OS version I have, load the software signatures
    // and expected launchd files.
    [self loadAppleSoftware];
    [self loadAppleLaunchd];
    }
  else
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
    NSDictionary * plist = [Utilities readPropertyListData: plistData];
  
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
    NSDictionary * plist = [Utilities readPropertyListData: plistData];
  
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
        default:
          [self loadAppleLaunchd: [plist objectForKey: @"10.12"]];
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
  
  NSString * marketingName = [self fallbackMarketingName: version];
  
  int days = 0;
  int hours = 0;

  BOOL parsed = [self parseUpTime: uptime days: & days hours: & hours];
  
  if(!parsed)
    {
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
  
  if([marketingName length] && ([[Model model] majorOSVersion] >= kLion))
    {
    marketingName =
      [marketingName
        stringByAppendingString: [version substringFromIndex: 4]];
    }
  else
    return [self fallbackMarketingName: version];
    
  return marketingName;
  }

// Get a fallback marketing name.
- (NSString *) fallbackMarketingName: (NSString *) version
  {
  NSString * fallbackMarketingName = version;
  
  NSString * OSName = @"OS X";
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
      OSName = @"macOS";
      name = @"Sierra";
      break;

    default:
      return version;
    }
    
  fallbackMarketingName =
    [NSString
      stringWithFormat:
        @"%@ %@ %@", OSName, name, [version substringFromIndex: offset]];
  
  return fallbackMarketingName;
  }

// Parse the OS version.
- (BOOL) parseOSVersion: (NSString *) profilerVersion
  {
  if(profilerVersion)
    {
    NSScanner * scanner = [NSScanner scannerWithString: profilerVersion];
    
    [scanner scanUpToString: @"(" intoString: NULL];
    [scanner scanString: @"(" intoString: NULL];
    
    int majorVersion = 0;
    
    bool found = [scanner scanInt: & majorVersion];
    
    if(found)
      {
      [[Model model]
        setMajorOSVersion: majorVersion];
      
      NSString * minorVersion = nil;
      
      found = [scanner scanUpToString: @")" intoString: & minorVersion];
      
      if(found)
        {
        unichar ch;
        
        [minorVersion getCharacters: & ch range: NSMakeRange(0, 1)];
        
        [[Model model] setMinorOSVersion: ch - 'A'];
        
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
