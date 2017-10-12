/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014-2017. All rights reserved.
 **********************************************************************/

#import "SystemSoftwareCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Model.h"
#import "Utilities.h"
#import "SubProcess.h"
#import "LaunchdCollector.h"
#import "XMLBuilder.h"
#import "NSArray+Etresoft.h"
#import "NSDictionary+Etresoft.h"
#import "EtreCheckConstants.h"
#import "LocalizedString.h"
#import "OSVersion.h"

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
    
  if(!dataFound)
    {
    [self.result
      appendString:
        ECLocalizedString(
          @"    Operating system information not found!\n")
      attributes:
        @{
          NSFontAttributeName : [[Utilities shared] boldFont],
          NSForegroundColorAttributeName : [[Utilities shared] red]
        }];
        
    [self.result appendCR];
    }
  }

// Print a system software item.
- (BOOL) printSystemSoftware: (NSDictionary *) item
  {
  NSString * version = [item objectForKey: @"os_version"];
  NSString * uptime = [item objectForKey: @"uptime"];

  NSString * OSName = nil;
  
  NSString * marketingName = 
    [self fallbackMarketingName: version name: & OSName];
  
  [self.model addElement: @"name" value: OSName];
  [self.model addElement: @"version" value: [[OSVersion shared] version]];
  [self.model addElement: @"build" value: [[OSVersion shared] build]];
  
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
            ECLocalizedString(@"    %@ - Uptime: %@%@\n"),
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

  NSString * dayString = ECLocalizedPluralString(days, @"day");
  NSString * hourString = ECLocalizedPluralString(hours, @"hour");
  
  if(days > 0)
    hourString = @"";
    
  [self.result
    appendString:
      [NSString
        stringWithFormat:
          ECLocalizedString(@"    %@ - Uptime: %@%@\n"),
          marketingName,
          dayString,
          hourString]];
          
  return YES;
  }

// Query Apple for the marketing name.
// Don't even bother with this.
- (NSString *) marketingName: (NSString *) version
  {
  NSString * language = ECLocalizedString(@"en");
  
  NSURL * url =
    [NSURL
      URLWithString:
        [NSString
          stringWithFormat:
            @"http://support-sp.apple.com/sp/product?edid=10.%d&lang=%@",
            [[OSVersion shared] major] - 4,
            language]];
  
  NSString * marketingName = [Utilities askAppleForMarketingName: url];
  NSString * OSName = nil;
  
  if([marketingName length] && ([[OSVersion shared] major] >= kLion))
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
  
  switch([[OSVersion shared] major])
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
