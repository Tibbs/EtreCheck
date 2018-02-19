/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014-2017. All rights reserved.
 **********************************************************************/

#import "UnsignedCollector.h"
#import "Model.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"
#import "LaunchdCollector.h"
#import "XMLBuilder.h"
#import "EtreCheckConstants.h"
#import "LocalizedString.h"
#import "Launchd.h"
#import "LaunchdFile.h"
#import "Adware.h"
#import "NSDictionary+Etresoft.h"
#import "NSString+Etresoft.h"
#import <netinet/in.h>
#import <netdb.h>

#define kWhitelistKey @"whitelist"
#define kWhitelistPrefixKey @"whitelist_prefix"
#define kAdwareExtensionsKey @"adwareextensions"
#define kBlacklistKey @"blacklist"
#define kBlacklistSuffixKey @"blacklist_suffix"
#define kBlacklistMatchKey @"blacklist_match"

// Collect information about unsigned files.
@implementation UnsignedCollector

// Track all unique whitelist prefixes.
@synthesize whitelistPrefixes = myWhitelistPrefixes;

// Prefixes being looked up.
@synthesize networkPrefixes = myNetworkPrefixes;

// A queue for managing asyncronous tasks.
@synthesize queue = myQueue;

// A semaphore for waiting for a number of tasks.
@synthesize pendingTasks = myPendingTasks;

// Am I emitting content already?
@synthesize emittingContent = myEmittingContent;

// Constructor.
- (id) init
  {
  self = [super initWithName: @"unsigned"];
  
  if(self != nil)
    {
    NSString * label = [[NSString alloc] initWithString: @"Unsigned"];
    
    myQueue = 
      dispatch_queue_create(label.UTF8String, DISPATCH_QUEUE_SERIAL);
    
    [label release];
    
    myPendingTasks = dispatch_group_create();
    
    myNetworkPrefixes = [NSMutableDictionary new];
    }
    
  return self;
  }

// Destructor.
- (void) dealloc
  {
  [myNetworkPrefixes release];
  [myWhitelistPrefixes release];
  dispatch_release(myPendingTasks);
  dispatch_release(myQueue);
  
  [super dealloc];
  }
  
// Print any unsigned files found.
- (void) performCollect
  {
  [self buildLegitimatePrefixes];
  
  [self collectUnsignedFiles];
  
  [self waitForDetails];
  
  [self printUnsignedFiles];
  [self exportUnsignedFiles];
  }
  
// Build a database of legitimate prefixes.
- (void) buildLegitimatePrefixes
  {
  // Build a list of whitelist prefixes. 
  NSMutableSet * whitelistFiles = [[self.model adware] whitelistFiles];
  NSMutableSet * legitimateStrings = [NSMutableSet new];
  
  for(NSString * file in whitelistFiles)
    {
    NSString * prefix = [Utilities bundleName: file];
    
    if(prefix.length > 0)
      [legitimateStrings addObject: prefix]; 
    }
    
  myWhitelistPrefixes = [[NSSet alloc] initWithSet: legitimateStrings];
  
  [legitimateStrings release];
  }
  
// Collect unsigned files. 
- (void) collectUnsignedFiles
  {
  Launchd * launchd = [self.model launchd];
  
  // I will have already filtered out launchd files specific to this 
  // context.
  for(NSString * path in [launchd filesByPath])
    {
    LaunchdFile * file = [[launchd filesByPath] objectForKey: path];
    
    if([LaunchdFile isValid: file])
      [self checkUnsigned: file];
    }
  }
  
// Check for an unsigned file.
- (void) checkUnsigned: (LaunchdFile *) file
  {
  if([file.signature isEqualToString: kSignatureApple])
    return;
    
  if([file.signature isEqualToString: kSignatureValid])
    return;
  
  // This will be in clean up.
  if([file.signature isEqualToString: kExecutableMissing])
    return;

  // If it is already adware, skip it here.
  if(file.adware != nil)
    return;
    
  [[[self.model launchd] unsignedFiles] addObject: file];
  
  [self getDetails: file];
  }
  
// Get details about an unsigned file.
- (void) getDetails: (LaunchdFile *) file
  {
  NSString * name = [file.path lastPathComponent];
  NSString * prefix = [Utilities bundleName: name];
  
  if([[[self.model adware] whitelistFiles] containsObject: name])
    file.details = kUnsignedWhitelist;
  else if([self.whitelistPrefixes containsObject: prefix])
    file.details = kUnsignedWhitelistPrefix;
  else
    [self lookupDetails: prefix file: file];
  }
  
// Lookup details about an unsigned file.
- (void) lookupDetails: (NSString *) prefix file: (LaunchdFile *) file
  {
  NSArray * parts = [prefix componentsSeparatedByString: @"."];
  
  NSString * domainName = 
    [[[parts reverseObjectEnumerator] allObjects] 
      componentsJoinedByString: @"."];
    
  if(![NSString isValid: domainName]) 
    return;
    
  dispatch_sync(
    self.queue, 
    ^{
      NSMutableSet * files = 
        [self.networkPrefixes objectForKey: domainName];
      
      if(files == nil)
        {
        files = [NSMutableSet new];
        
        [self.networkPrefixes setObject: files forKey: domainName];
        
        [files release];
        }
        
     [files addObject: file];   
     }); 
    
  dispatch_group_async(
    self.pendingTasks,
    dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
    ^{
      struct addrinfo ai_hints;

      bzero(& ai_hints, sizeof(ai_hints));
      
      ai_hints.ai_flags = AI_PASSIVE;
      ai_hints.ai_family = PF_UNSPEC;
      ai_hints.ai_socktype = SOCK_STREAM;

      struct addrinfo * server_addr = NULL;

      int error = getaddrinfo(
        [domainName UTF8String],
        "http",
        & ai_hints,
        & server_addr);
    
      if(error != 0)
        dispatch_sync(
          self.queue, 
          ^{
            if(!self.emittingContent)
              {
              NSMutableSet * files = 
                [self.networkPrefixes objectForKey: domainName];
                
              for(LaunchdFile * file in files)
                file.details = kUnsignedDNSInvalid;
              }
          });
    });
  }
  
// Wait to collect all the details
- (void) waitForDetails
  {
  dispatch_group_wait(
    self.pendingTasks, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 30));
    
  dispatch_sync(
    self.queue, 
    ^{
      self.emittingContent = YES;
    });
  }
  
// Print unsigned files.
- (void) printUnsignedFiles
  {
  if([self.model launchd].unsignedFiles.count == 0)
    return;
    
  [self.result appendAttributedString: [self buildTitle]];
  
  for(LaunchdFile * launchdFile in [[self.model launchd] unsignedFiles])
    {
    if([self hideFile: launchdFile])
      continue;
      
    // Print the file.
    [self.result appendString: @"    "];
    [self.result appendString: launchdFile.path];
    [self.result appendString: @" "];

    if([launchdFile.status isEqualToString: kStatusNotLoaded])
      {
      NSAttributedString * enableLink = 
        [self generateEnableLink: launchdFile.path];

      if(enableLink)
        [self.result appendAttributedString: enableLink];
      }
      
    else
      {
      NSAttributedString * disableLink = 
        [self generateDisableLink: launchdFile.path];

      if(disableLink)
        [self.result appendAttributedString: disableLink];
      }
      
    if(launchdFile.executable.length > 0)
      {
      [self.result appendString: @"\n        "];
      [self.result 
        appendString: [self cleanPath: launchdFile.executable]];
      }

    [self.result appendString: @"\n"];
    }
    
  [self.result appendCR];
  }
  
// Should this file be hidden?
- (BOOL) hideFile: (LaunchdFile *) file
  {
  Launchd * launchd = [self.model launchd];
  
  NSDictionary * appleFile = [launchd.appleFiles objectForKey: file.path];
  
  if([NSDictionary isValid: appleFile])
    {
    NSString * expectedSignature = [appleFile objectForKey: kSignature];
    
    if([NSString isValid: expectedSignature])
      if([file.signature isEqualToString: expectedSignature])
        return [self.model ignoreKnownAppleFailures];
    }
    
  return NO;
  }
  
// Export unsigned files.
- (void) exportUnsignedFiles
  {
  if([self.model launchd].unsignedFiles.count == 0)
    return;

  [self.xml startElement: @"launchdfiles"];
  
  for(LaunchdFile * launchdFile in [[self.model launchd] unsignedFiles])

    // Export the XML.
    [self.xml addFragment: launchdFile.xml];
  
  [self.xml endElement: @"launchdfiles"];
  }

// Generate a "disable" link.
- (NSAttributedString *) generateDisableLink: (NSString *) path
  {
  NSMutableAttributedString * urlString =
    [[NSMutableAttributedString alloc] initWithString: @""];
    
  [urlString appendString: @" "];
  
  NSString * encodedPath = 
    [path stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
  
  NSString * url = 
    [NSString 
      stringWithFormat: @"etrecheck://unsigned/disable?%@", encodedPath];

  [urlString
    appendString: ECLocalizedString(@"[Disable]")
    attributes:
      @{
        NSFontAttributeName : [[Utilities shared] boldFont],
        NSLinkAttributeName : url
      }];
    
  return [urlString autorelease];
  }

// Generate an "enable" link.
- (NSAttributedString *) generateEnableLink: (NSString *) path
  {
  NSMutableAttributedString * urlString =
    [[NSMutableAttributedString alloc] initWithString: @""];
    
  [urlString appendString: @" "];
  
  NSString * encodedPath = 
    [path stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
  
  NSString * url = 
    [NSString 
      stringWithFormat: @"etrecheck://unsigned/enable?%@", encodedPath];
  
  [urlString
    appendString: ECLocalizedString(@"[Enable]")
    attributes:
      @{
        NSFontAttributeName : [[Utilities shared] boldFont],
        NSLinkAttributeName : url
      }];
    
  return [urlString autorelease];
  }

@end
