/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "LaunchdFile.h"
#import "NumberFormatter.h"
#import "LaunchdLoadedTask.h"
#import "OSVersion.h"
#import "SubProcess.h"
#import "EtreCheckConstants.h"
#import "NSDictionary+Etresoft.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"
#import "LocalizedString.h"
#import "XMLBuilder.h"

// A wrapper around a launchd task.
@interface LaunchdTask ()

// Parse a dictionary.
- (void) parseDictionary: (NSDictionary *) dict;

@end

// A wrapper around a launchd config file.
@implementation LaunchdFile

// The config script contents.
@synthesize plist = myPlist;

// Is the config script valid?
@synthesize configScriptValid = myConfigScriptValid;

// The launchd context.
@synthesize context = myContext;

// Loaded tasks.
@synthesize loadedTasks = myLoadedTasks;

// Overall status.
@synthesize status = myStatus;

// Overall status.
- (NSString *) status
  {
  if(myStatus == nil)
    {
    if(self.loadedTasks.count == 0)
      myStatus = kStatusNotLoaded;
    else
      {
      myStatus = kStatusLoaded;
      
      for(LaunchdLoadedTask * task in self.loadedTasks)
        {
        if(task.PID.length > 0)
          {
          NSNumber * pid = 
            [[NumberFormatter sharedNumberFormatter] 
              convertFromString: task.PID];
            
          if([pid longValue] > 0)
            myStatus = kStatusRunning;
          }
          
        if(task.lastExitCode.length > 0)
          if(![task.lastExitCode isEqualToString: @"-"])
            {
            if([task.lastExitCode isEqualToString: @"127"])
              myStatus = kStatusKilled;
            else 
              {
              NSNumber * lastExitCode = 
                [[NumberFormatter sharedNumberFormatter] 
                  convertFromString: task.lastExitCode];
                
              if([lastExitCode longValue] != 0)
                myStatus = kStatusFailed;
              }
            }
        }
      }
    }
    
  return myStatus;
  }
  
// Constructor with path.
- (nullable instancetype) initWithPath: (nonnull NSString *) path
  {
  if(path.length > 0)
    {
    self = [super init];
    
    if(self != nil)
      {
      myLoadedTasks = [NSMutableArray new];
      
      [self parseFromPath: path];

      [self findContext];  
      }
    }
    
  return self;
  }
  
// Destructor.
- (void) dealloc
  {
  [myContext release];
  [myPlist release];
  [myLoadedTasks release];
  [myStatus release];
  
  [super dealloc];
  }
    
// Parse from a path.
- (void) parseFromPath: (nonnull NSString *) path 
  {
  self.path = [path stringByAbbreviatingWithTildeInPath];
  myPlist = [[NSDictionary readPropertyList: path] retain];
  
  if(self.plist.count > 0)
    [super parseDictionary: self.plist];
    
  myConfigScriptValid = (self.label.length > 0);
    
  self.authorName = [self checkSignature];
  }

// Collect the signature of a launchd item.
- (NSString *) checkSignature
  {
  // I need an executable for this.
  if(self.executable.length == 0)
    return @"? ? ?";
    
  NSString * signature = nil;
  
  if([self.label hasPrefix: @"com.apple."])
    signature = [Utilities checkAppleExecutable: self.executable];
  else  
    signature = [Utilities checkExecutable: self.executable];
  
  if([signature length] > 0)
    {
    if([signature isEqualToString: kSignatureApple])
      return @"Apple, Inc.";
      
    // If I have a valid executable, query the actual developer.
    if([signature isEqualToString: kSignatureValid])
      {
      NSString * developer = [Utilities queryDeveloper: self.executable];
      
      if(developer.length > 0)
        return developer;
      }
    }
   
  return 
    [NSString 
      stringWithFormat: 
        @"? %@ %@", 
        [Utilities crcFile: self.path],
        [Utilities crcFile: self.executable]];
  }
  
// Load a launchd task.
- (void) load
  {
  SubProcess * launchctl = [[SubProcess alloc] init];
  
  NSArray * arguments = 
    [[NSArray alloc] initWithObjects: @"load", @"-wF", self.path, nil];
    
  [launchctl execute: @"/bin/launchctl" arguments: arguments];
    
  [arguments release];
  [launchctl release];
  }

// Unload a launchd task.
- (void) unload
  {
  SubProcess * launchctl = [[SubProcess alloc] init];
  
  NSArray * arguments = 
    [[NSArray alloc] initWithObjects: @"unload", @"-wF", self.path, nil];
    
  [launchctl execute: @"/bin/launchctl" arguments: arguments];
    
  [arguments release];
  [launchctl release];
  }

#pragma mark - Context

// Find the context based on the path.
- (void) findContext
  {
  if([self.path hasPrefix: @"/System/Library/"])
    myContext = kLaunchdAppleContext;
  else if([self.path hasPrefix: @"/Library/"])
    myContext = kLaunchdSystemContext;
  else if([self.path hasPrefix: @"~/Library/"])
    myContext = kLaunchdUserContext;
  else
    {
    NSString * libraryPath = 
      [NSHomeDirectory() stringByAppendingPathComponent: @"Library"];
      
    if([self.path hasPrefix: libraryPath])
      myContext = kLaunchdUserContext;
    else 
      myContext = kLaunchdUnknownContext;
    }
  }
  
#pragma mark - PrintableItem

// Build the attributedString value.
- (void) buildAttributedStringValue: 
  (NSMutableAttributedString *) attributedString
  {
  // Print the status.
  [self appendFileStatus: attributedString];
  
  // Print the name.
  [attributedString appendString: [self.path lastPathComponent]];
  
  // Print the signature.
  [self appendSignature: attributedString];
  
  // Print a support link.
  [self appendLookupLink: attributedString];
  }
  
// Append the file status.
- (void) appendFileStatus: (NSMutableAttributedString *) attributedString
  {
  NSString * statusString = ECLocalizedString(@"not loaded");
  
  NSColor * color = [[Utilities shared] gray];
  
  if([self.status isEqualToString: kStatusLoaded])
    {
    statusString = ECLocalizedString(@"loaded");
    color = [[Utilities shared] blue];
    }
  else if([self.status isEqualToString: kStatusRunning])
    {
    statusString = ECLocalizedString(@"running");
    color = [[Utilities shared] green];
    }
  else if([self.status isEqualToString: kStatusFailed])
    {
    statusString = ECLocalizedString(@"failed");
    color = [[Utilities shared] red];
    }
  else if([self.status isEqualToString: kStatusKilled])
    {
    statusString = ECLocalizedString(@"killed");
    color = [[Utilities shared] red];
    }
  
  [attributedString
    appendString: [NSString stringWithFormat: @"    [%@]    ", statusString]
    attributes:
      @{
        NSForegroundColorAttributeName : color,
        NSFontAttributeName : [[Utilities shared] boldFont]
      }];
  }
  
// Append the signature.
- (void) appendSignature: (NSMutableAttributedString *) attributedString
  {
  NSString * modificationDateString =
    [Utilities installDateAsString: self.modificationDate];

  [attributedString appendString: @" "];

  [attributedString 
    appendString: 
      [NSString 
        stringWithFormat: 
          @"(%@ - %@)", self.authorName, modificationDateString]];
  }

// Append a lookup link.
- (void) appendLookupLink: (NSMutableAttributedString *) attributedString
  {
  NSString * lookupLink = [self getLookupURLForFile];
  
  if(lookupLink.length > 0)
    {
    [attributedString appendString: @" "];

    [attributedString
      appendString: ECLocalizedString(@"[Lookup]")
      attributes:
        @{
          NSFontAttributeName : [[Utilities shared] boldFont],
          NSForegroundColorAttributeName : [[Utilities shared] blue],
          NSLinkAttributeName : lookupLink
        }];
    }
  }
  
// Try to construct a support URL.
- (NSString *) getLookupURLForFile
  {
  if([self.label hasPrefix: @"com.apple."])
    return nil;
    
  NSString * filename = [self.path lastPathComponent];
  
  if([filename hasSuffix: @".plist"])
    {
    NSString * key = [filename stringByDeletingPathExtension];

    NSString * query =
      [NSString
        stringWithFormat:
          @"%@%@%@%@",
          ECLocalizedString(@"ascsearch"),
          @"type=discussion&showAnsweredFirst=true&q=",
          key,
          @"&sort=updatedDesc&currentPage=1&includeResultCount=true"];

    return query;
    }
    
  return nil;
  }
  
// Build the XML value.
- (void) buildXMLValue: (XMLBuilder *) xml
  {
  [xml startElement: @"file"];
  
  [xml addElement: @"status" value: self.status];
  [xml addElement: @"path" value: self.path];
  [xml addElement: @"label" value: self.label];
  
  if(self.executable.length > 0)
    [xml addElement: @"executable" value: self.executable];
  
  if(self.arguments.count > 0)
    {
    [xml startElement: @"arguments"];
    
    for(NSString * argument in self.arguments)
      [xml addElement: @"argument" value: argument];
      
    [xml endElement: @"arguments"];
    }
    
  [xml addElement: @"valid" boolValue: self.configScriptValid];
  
  [xml addElement: @"author" value: self.authorName];
    
  if(self.modificationDate != nil)
    [xml addElement: @"installdate" date: self.modificationDate];

  [xml endElement: @"file"];
  }

@end
