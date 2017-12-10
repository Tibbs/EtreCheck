/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "NetworkCollector.h"
#import "ByteCountFormatter.h"
#import "XMLBuilder.h"
#import "LocalizedString.h"
#import "OSVersion.h"
#import "NSArray+Etresoft.h"
#import "NSDictionary+Etresoft.h"
#import "NetworkInterface.h"
#import "UbiquityContainer.h"
#import "UbiquityContainerDirectory.h"
#import "UbiquityFile.h"
#import "NSMutableAttributedString+Etresoft.h"

@implementation NetworkCollector

// Constructor.
@synthesize interfaces = myInterfaces;

// Ubiquity containers.
@synthesize ubiquityContainers = myUbiquityContainers;

// iCloud free amount.
@synthesize iCloudFree = myiCloudFree;

- (id) init
  {
  self = [super initWithName: @"network"];
  
  if(self != nil)
    {
    myInterfaces = [NSMutableArray new];
    myUbiquityContainers = [NSMutableArray new];
    }
    
  return self;
  }

// Destructor.
- (void) dealloc
  {
  [myInterfaces release];
  [myUbiquityContainers release];
  
  [super dealloc];
  }

// Perform the collection.
- (void) performCollect
  {
  [self collectNetwork];
  [self collectiCloud];
    
  [self printNetwork];
  [self exportNetwork];
  }

// Collect network information.
- (void) collectNetwork
  {
  NSArray * args =
    @[
      @"-xml",
      @"SPNetworkDataType"
    ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  if([subProcess execute: @"/usr/sbin/system_profiler" arguments: args])
    {
    NSArray * plist =
      [NSArray readPropertyListData: subProcess.standardOutput];
  
    if([NSArray isValid: plist])
      {
      NSDictionary * results = [plist objectAtIndex: 0];
      
      if([NSDictionary isValid: results])
        {
        NSArray * items = [results objectForKey: @"_items"];
          
        if([NSArray isValid: items])
          for(NSDictionary * item in items)
            {
            NetworkInterface * interface = 
              [NetworkInterface 
                NetworkInterfaceWithPropertyListDictionary: item];
                
            if(interface != nil)
              [self.interfaces addObject: interface];
            }
        }
      }
    }
    
  [subProcess release];
  }

// Collect iCloud information.
- (void) collectiCloud
  {
  [self collectiCloudPendingFiles];
  [self collectiCloudQuota];
  }
  
// Collect iCloud pending files information.
- (void) collectiCloudPendingFiles
  {
  int version = [[OSVersion shared] major];

  if(version < kElCapitan)
    return;
    
  NSArray * args =
    @[
      @"status",
    ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  if([subProcess execute: @"/usr/bin/brctl" arguments: args])
    {
    NSArray * lines = [Utilities formatLines: subProcess.standardOutput];
    
    UbiquityContainer * container = nil;
    
    for(NSString * line in lines)
      {
      if([line hasPrefix: @"<"])
        {
        NSString * ubiquityID = [self getUbiquityID: line];
        
        if(ubiquityID.length > 0)
          {
          if(container.pendingFileCount > 0)
            [self.ubiquityContainers addObject: container];
            
          [container release];
            
          container = 
            [[UbiquityContainer alloc] initWithUbiquityID: ubiquityID];
            
          continue;
          }
        }
      
      [container parseBrctlStatusLine: line];
      }
      
    if(container.pendingFileCount > 0)
      [self.ubiquityContainers addObject: container];
      
    [container release];
    }

  [subProcess release];
  }

// Get the ubiquity ID.
- (NSString *) getUbiquityID: (NSString *) line
  {
  NSRange end = [line rangeOfString: @"["];
  
  if(end.location != NSNotFound)
    return [line substringWithRange: NSMakeRange(1, end.location - 1)];
    
  return nil;
  }

// Collect iCloud quota.
- (void) collectiCloudQuota
  {
  int version = [[OSVersion shared] major];

  if(version < kSierra)
    return;

  long long bytes = 0;
    
  NSArray * args =
    @[
      @"quota",
    ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  if([subProcess execute: @"/usr/bin/brctl" arguments: args])
    {
    NSArray * lines = [Utilities formatLines: subProcess.standardOutput];
    
    for(NSString * line in lines)
      {
      NSScanner * scanner = [NSScanner scannerWithString: line];
      
      [scanner scanLongLong: & bytes];
      }
    }
    
  [subProcess release];
  
  self.iCloudFree = bytes;
  }
  
// Print network information.
- (void) printNetwork
  {
  BOOL hasData = NO;
  
  if(self.interfaces.count > 0)
    hasData = [self printInterfaces: hasData];
    
  if(self.ubiquityContainers.count > 0)
    hasData = [self printiCloudPendingFiles: hasData];
    
  int version = [[OSVersion shared] major];

  if(version >= kSierra)
    hasData = [self printiCloudFree: hasData];
    
  if(hasData)
    [self.result appendCR];
  }

// Print Network interfaces. 
- (BOOL) printInterfaces: (BOOL) hasData
  {
  if(!hasData)
    [self.result appendAttributedString: [self buildTitle]];

  for(NetworkInterface * interface in self.interfaces)
    {
    [self.result appendAttributedString: interface.attributedStringValue];
    
    hasData = YES;
    }
    
  return hasData;
  }
  
// Print iCloud pending files. 
- (BOOL) printiCloudPendingFiles: (BOOL) hasData
  {
  if(!hasData)
    [self.result appendAttributedString: [self buildTitle]];

  int count = 0;
  
  for(UbiquityContainer * container in self.ubiquityContainers)
    count += container.pendingFileCount;
      
  if(count > 0)
    {
    NSString * pendingFileCount = 
      ECLocalizedPluralString(count, @"pending file");

    [self.result
      appendString: ECLocalizedString(@"    iCloud Status: ")];
      
    if(count >= 10)
      [self.result
        appendString: pendingFileCount
        attributes:
          @{
            NSForegroundColorAttributeName : [[Utilities shared] red],
            NSFontAttributeName : [[Utilities shared] boldFont]
          }];
    else
      [self.result appendString: pendingFileCount];
      
    [self.result appendString: @"\n"];

    return YES;
    }
    
  return hasData;
  }
  
// Print iCloud free. 
- (BOOL) printiCloudFree: (BOOL) hasData
  {
  if(!hasData)
    [self.result appendAttributedString: [self buildTitle]];

  ByteCountFormatter * formatter = [ByteCountFormatter new];
      
  // Apple uses 1024 for this one.
  formatter.k1000 = 1024.0;
      
  NSString * iCloudFree = [formatter stringFromByteCount: self.iCloudFree];

  [formatter release];
  
  if([iCloudFree length] > 0)
    {
    [self.result
      appendString:
        [NSString
          stringWithFormat:
            ECLocalizedString(@"    iCloud Quota: %@ available"),
            iCloudFree]];
      
    if(self.iCloudFree < 1024 * 1024 * 256)
      [self.result
        appendString: ECLocalizedString(@" (Low!)")
        attributes:
          @{
            NSForegroundColorAttributeName : [[Utilities shared] red],
            NSFontAttributeName : [[Utilities shared] boldFont]
          }];
      
    [self.result appendString: @"\n"];
    
    return YES;
    }
    
  return hasData;
  }

// Export network information.
- (void) exportNetwork
  {
  if(self.interfaces.count > 0)
    [self.xml addArray: @"interfaces" values: self.interfaces];
    
  if(self.ubiquityContainers.count > 0)
    [self.xml 
      addArray: @"icloudpendingfiles" values: self.ubiquityContainers];

  int version = [[OSVersion shared] major];

  if(version >= kSierra)
    {
    ByteCountFormatter * formatter = [ByteCountFormatter new];
        
    // Apple uses 1024 for this one.
    formatter.k1000 = 1024.0;
        
    NSString * iCloudFree = 
      [formatter stringFromByteCount: self.iCloudFree];

    [formatter release];
    
    [self.xml addElement: @"icloudfree" valueWithUnits: iCloudFree];
    }
  }

@end
