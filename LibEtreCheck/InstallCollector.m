/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014-2017. All rights reserved.
 **********************************************************************/

#import "InstallCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"
#import "NSArray+Etresoft.h"
#import "SubProcess.h"
#import "XMLBuilder.h"
#import "LocalizedString.h"
#import "NSString+Etresoft.h"
#import "NSDate+Etresoft.h"
#import "NSSet+Etresoft.h"
#import "NSDictionary+Etresoft.h"
#import "Model.h"
#import "EtreCheckConstants.h"
#import "OSVersion.h"

// Collect install information.
@implementation InstallCollector

// Install items.
@synthesize installs = myInstalls;

// Constructor.
- (id) init
  {
  self = [super initWithName: @"install"];
  
  if(self != nil)
    {
    myInstalls = [NSMutableArray new];
    }
    
  return self;
  }

// Destructor.
- (void) dealloc  
  {
  [myInstalls release];
  
  [super dealloc];
  }

// Perform the collection.
- (void) performCollect
  {
  NSMutableArray * installsToPrint = [NSMutableArray new];
  
  if(installsToPrint == nil)
    return;
    
  [self collectInstalls];
  
  if(self.installs.count > 0)
    {
    NSDate * then =
      [[NSDate date] dateByAddingTimeInterval: -60 * 60 * 24 * 30];
  
    for(NSMutableDictionary * install in self.installs)
      if([NSDictionary isValid: install])
        {
        NSString * name = [install objectForKey: @"_name"];
        NSDate * date = [install objectForKey: @"install_date"];
        NSString * source = [install objectForKey: @"package_source"];
        
        if(![NSString isValid: name])
          continue;
          
        if(![NSDate isValid: date])
          continue;
          
        if(![NSString isValid: source])
          continue;
          
        // Any 3rd party installationsn in the last 30 days.
        if([source isEqualToString: @"package_source_other"])
          {
          if([then compare: date] == NSOrderedAscending)
            [installsToPrint addObject: install];
          }
        }
    }
    
  [self printInstalls: installsToPrint];
    
  [installsToPrint release];
  }

// Collect current updates.
/* - (void) collectCurrentUpdates
  {
  if([[OSVersion shared] major] >= kMavericks)
    {
    NSURL * url =
      [NSURL 
        URLWithString: 
          @"https://swscan.apple.com/content/catalogs/others/"
          "index-10.13-10.12-10.11-10.10-10.9"
          "-mountainlion-lion-snowleopard-leopard.merged-1.sucatalog.gz"];
    
    NSData * data = [NSData dataWithContentsOfURL: url];
    
    NSDictionary * plist = [NSDictionary readPropertyListData: data];
    
    if([NSDictionary isValid: plist])
      {
      NSNumber * version = [plist objectForKey: @"CatalogVersion"];
      
      if(version.intValue == 2)
        {
        NSDictionary * products = [plist objectForKey: @"Products"];
        
        if([NSDictionary isValid: products])
          [self parseProducts: products];
        }
      }
    }
  } 
  
// Parse update products.
- (void) parseProducts: (NSDictionary *) products
  {
  for(NSString * key in products)
    {
    NSDictionary * product = [products objectForKey: key];
    
    if([NSDictionary isValid: product])
      [self parseProduct: product];
    }
  }
  
// Parse an update product.
- (void) parseProduct: (NSDictionary *) product
  {
  NSString * metadataURL = [product objectForKey: @"ServerMetadataURL"];
  
  if([NSString isValid: metadataURL])
    {
    NSDate * postDate = [product objectForKey: @"PostDate"];
    
    if([NSDate isValid: postDate])
      {
      NSString * key = 
        [[metadataURL lastPathComponent] stringByDeletingPathExtension];
        
      NSString * name = 
        [self.criticalAppleInstallNameLookup objectForKey: key];
      
      if([NSString isValid: name])
        {
        NSURL * url = [[NSURL alloc] initWithString: metadataURL];
        
        NSData * data = [NSData dataWithContentsOfURL: url];
        
        [url release];
        
        NSDictionary * plist = [NSDictionary readPropertyListData: data];
        
        if([NSDictionary isValid: plist])
          {
          NSString * version = 
            [plist objectForKey: @"CFBundleShortVersionString"];
          
          if([NSString isValid: version])
            {
            NSDictionary * currentInstall = 
              [self.criticalAppleInstalls objectForKey: name];
            
            if(currentInstall != nil)
              {
              NSDate * date = 
                [currentInstall objectForKey: @"install_date"];
              
              if([date isLaterThan: postDate])
                return;
              }  
              
            currentInstall = 
              [self.criticalAppleInstalls objectForKey: name];
            
            if(currentInstall != nil)
              {
              NSString * currentVersion = 
                [currentInstall objectForKey: @"install_version"];
              
              BOOL later = 
                [Utilities 
                  isVersion: version laterThanVersion: currentVersion];
                
              if(!later)
                return;
              }  

            NSDictionary * install =
              [[NSDictionary alloc] 
                initWithObjectsAndKeys:
                  name, @"_name", 
                  postDate, @"post_date",
                  @"package_source_apple", @"package_source",
                  version, @"install_version",
                  @YES, @"critical",
                  @NO, @"installed",
                  nil];
            
            [self.pendingCriticalAppleInstalls 
              setObject: install forKey: name];
            
            [install release];
            }
          }
        }
      }
    }
  } */

// Collect installs.
- (void) collectInstalls
  {
  NSString * key = @"SPInstallHistoryDataType";
  
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
        NSArray * items = [results objectForKey: @"_items"];
          
        if([NSArray isValid: items])
          for(NSDictionary * item in items)
            {
            NSMutableDictionary * install = 
              [[NSMutableDictionary alloc] initWithDictionary: item];
            
            [install setObject: @YES forKey: @"installed"];
            
            [self.installs addObject: install];
            
            [install release];
            }
        }
      }
    }

  [subProcess release];
  
  [self.installs
    sortUsingComparator:
      ^NSComparisonResult(id _Nonnull obj1, id _Nonnull obj2)
      {
      NSDictionary * install1 = obj1;
      NSDictionary * install2 = obj2;
      
      NSDate * date1 = nil;
      NSDate * date2 = nil;
      
      if([NSDictionary isValid: install1])
        date1 = [install1 objectForKey: @"install_date"];
      
      if([NSDictionary isValid: install2])
        date2 = [install2 objectForKey: @"install_date"];
      
      if(![NSDate isValid: date2])
        return NSOrderedDescending;
        
      if((date2 != nil) && [NSDate isValid: date1])
        return [date1 compare: date2];
        
      return NSOrderedSame;
      }];
  }

// Remove duplicates.
- (NSArray *) removeDuplicates: (NSArray *) installs
  {
  NSMutableDictionary * lastInstallsByNameAndVersion = 
    [NSMutableDictionary new];
  
  for(NSDictionary * install in installs)
    if([NSDictionary isValid: install])
      {
      NSString * name = [install objectForKey: @"_name"];
        
      if([NSString isValid: name])
        [lastInstallsByNameAndVersion setObject: install forKey: name];
      }
      
  NSMutableSet * lastInstalls = 
    [[NSMutableSet alloc] 
      initWithArray: [lastInstallsByNameAndVersion allValues]];
  
  [lastInstallsByNameAndVersion release];
  
  NSMutableArray * installsToPrint = [NSMutableArray array];
  
  for(NSDictionary * install in installs)
    if([lastInstalls containsObject: install])
      [installsToPrint addObject: install];
      
  [lastInstalls release];
  
  return installsToPrint;
  }
  
// Print installs.
- (void) printInstalls: (NSArray *) installs
  {
  NSArray * installsToPrint = [self removeDuplicates: installs];
  
  if(installsToPrint.count > 0)
    {
    [self.result appendAttributedString: [self buildTitle]];

    for(NSDictionary * install in installsToPrint)
      if([NSDictionary isValid: install])
        {
        NSString * name = [install objectForKey: @"_name"];
        NSDate * install_date = [install objectForKey: @"install_date"];
        NSDate * post_date = [install objectForKey: @"post_date"];
        NSString * version = [install objectForKey: @"install_version"];

        if(![NSString isValid: name])
          continue;
          
        if(![NSString isValid: version])
          continue;
        
        NSString * installDate =
          [Utilities installDateAsString: install_date];

        if([NSString isValid: installDate])
          {          
          [self.xml startElement: @"package"];
          
          [self.xml addElement: @"name" value: name];
          [self.xml addElement: @"version" value: version];
          [self.xml addElement: @"installdate" date: install_date];
          [self.xml addElement: @"postdate" date: post_date];
          
          [self.xml endElement: @"package"];
          
          // TODO: Add source.
          [self.result
            appendString:
              [NSString
                stringWithFormat:
                  ECLocalizedString(@"    %@: %@ (%@)\n"),
                  name,
                  version,
                  installDate]];
          }
        }
      
    [self.result appendString: @"\n"];
    
    [self.result
      appendString: ECLocalizedString(@"installsincomplete")];
    
    [self.result appendCR];
    }
  }
  
/* // Load security update names.
- (void) loadSecurityUpdateNames
  {
  NSBundle * bundle = [NSBundle bundleForClass: [self class]];

  NSString * signaturePath =
    [bundle pathForResource: @"securityUpdateNames" ofType: @"plist"];
    
  NSData * plistData = [NSData dataWithContentsOfFile: signaturePath];
  
  NSDictionary * plist = [NSDictionary readPropertyListData: plistData];
  
  if([NSDictionary isValid: plist])
    {
    NSArray * names = [plist objectForKey: @"names"];
    
    mySecurityUpdateNames = [[NSSet alloc] initWithArray: names];
    }
  }

// Is this a security update?
- (bool) isSecurityUpdate: (NSString *) name
  {
  for(NSString * string in self.securityUpdateNames)
    {
    NSRange range = [name rangeOfString: string];
    
    if(range.location != NSNotFound)
      return true;
    }
    
  return false;
  } */
  
@end
