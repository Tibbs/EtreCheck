/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "LaunchdFile.h"
#import "LaunchdLoadedTask.h"
#import "Launchd.h"
#import "OSVersion.h"
#import "SubProcess.h"
#import "EtreCheckConstants.h"
#import "NSDictionary+Etresoft.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"
#import "LocalizedString.h"
#import "XMLBuilder.h"
#import "NSDate+Etresoft.h"
#import <ServiceManagement/ServiceManagement.h>

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
  
// The executable's signature.
@synthesize signature = mySignature;

// The plist CRC.
@synthesize plistCRC = myPlistCRC;

// The executable CRC.
@synthesize executableCRC = myExecutableCRC;

// Is the file loaded?
@dynamic loaded;

// The safety score.
@synthesize safetyScore = mySafetyScore;

// Adware.
@synthesize adware = myAdware;

// I will need a unique, XML-safe identifier for each launchd file.
@synthesize identifier = myIdentifier;

// Is this an Apple file?
@synthesize apple = myApple;

// Return a unique number.
+ (int) uniqueIdentifier
  {
  static int counter = 0;
  
  dispatch_sync(
    dispatch_get_main_queue(), 
    ^{
      ++counter;
    });
    
  return counter;
  }
  
// Get the status.
- (NSString *) status
  {
  if(myStatus == nil)
    {
    if(self.loadedTasks.count == 0)
      myStatus = [kStatusNotLoaded copy];
    else
      {
      for(LaunchdLoadedTask * task in self.loadedTasks)
        {
        if([task.status isEqualToString: kStatusRunning])
          myStatus = [task.status retain];
          
        else if(myStatus == nil)
          {
          if([task.status isEqualToString: kStatusKilled])
            myStatus = [task.status retain];
          else if([task.status isEqualToString: kStatusFailed])
            myStatus = [task.status retain];
          }
        }
        
      if(myStatus == nil)
        myStatus = [kStatusLoaded copy];
      }
    }
    
  return myStatus;
  }

// Get the last exit code.
- (NSString *) lastExitCode
  {
  if(myLastExitCode == nil)
    {
    if(self.loadedTasks.count > 0)
      {
      NSMutableSet * exitCodes = [NSMutableSet new];
      
      for(LaunchdLoadedTask * task in self.loadedTasks)
        if(task.lastExitCode.length > 0)
          [exitCodes addObject: task.lastExitCode];
        
      myLastExitCode = 
        [[[exitCodes allObjects] componentsJoinedByString: @","] retain];
      
      [exitCodes release];
      }
    }
    
  return myLastExitCode;
  }
  
// Is the file loaded?
- (BOOL) loaded
  {
  return self.loadedTasks.count > 0;
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
      
      // Start off with a safety score of 10. Adware will lose that.
      mySafetyScore = 10;
      
      myIdentifier = 
        [[NSString alloc] 
          initWithFormat: @"launchd%d", [LaunchdFile uniqueIdentifier]];
      
      [self parseFromPath: path];

      [self getModificationDate];
        
      if(myConfigScriptValid)
        {
        [self findContext];  

        [self findNewTasks];
        }
      }
    }
    
  return self;
  }
  
// Destructor.
- (void) dealloc
  {
  self.context = nil;
  self.plist = nil;
  self.loadedTasks = nil;
  self.signature = nil;
  self.identifier = nil;
  self.executableCRC = nil;
  self.plistCRC = nil;
  
  [super dealloc];
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

// Requery the file.
- (void) requery
  {
  NSMutableSet * unloadedTasks = [NSMutableSet new];
  
  for(LaunchdLoadedTask * task in self.loadedTasks)
    {
    [task requery];
  
    if([task.status isEqualToString: kStatusNotLoaded])
      [unloadedTasks addObject: task];
    }
    
  for(LaunchdLoadedTask * task in unloadedTasks)
    [self.loadedTasks removeObject: task];
    
  [unloadedTasks release];
  
  self.status = nil;
  
  [self findNewTasks];
  }
  
// Is this a launchd file?
- (BOOL) isLaunchdFile
  {
  return YES;
  }
  
#pragma mark - Private methods

// Parse from a path.
- (void) parseFromPath: (nonnull NSString *) path 
  {
  self.path = [path stringByAbbreviatingWithTildeInPath];
  self.plist = [NSDictionary readPropertyList: path];
  
  if(self.plist.count > 0)
    [super parseDictionary: self.plist];
    
  myConfigScriptValid = (self.label.length > 0);
    
  [self calculateSafetyScore];
  }

// Calculate a safety score.
- (void) calculateSafetyScore
  {
  // If the config script is valid, award 10 points.
  if(self.configScriptValid)
    {
    self.safetyScore = self.safetyScore + 10;
    
    // If the label matches the file name, award another 10 points.
    NSString * baseName = 
      [[self.path lastPathComponent] stringByDeletingPathExtension];
      
    if([baseName isEqualToString: self.label])
      self.safetyScore = self.safetyScore + 10;
    }
  }
  
// Collect the signature of a launchd item.
- (void) checkSignature: (Launchd *) launchd
  {
  NSDictionary * appleFile = [launchd.appleFiles objectForKey: self.path];

  if(appleFile != nil)
    {
     NSString * expectedSignature = [appleFile objectForKey: kSignature];
  
    NSString * signature = 
      [Utilities checkAppleExecutable: self.executable];
      
    if(expectedSignature != nil)
      {
      if([signature isEqualToString: expectedSignature])
        {
        self.apple = YES;
        self.signature = signature;
        }
      }
    }
    
  if(!self.apple)
    self.signature = [Utilities checkExecutable: self.executable];
  
  NSString * executableType = @"?";
  
  if([self.signature length] > 0)
    {
    if([self.signature isEqualToString: kSignatureApple])
      {
      self.authorName = @"Apple, Inc.";
      self.safetyScore = 100;
      return;
      }
      
    // If I have a valid executable, query the actual developer.
    if([self.signature isEqualToString: kSignatureValid])
      {
      NSString * developer = [Utilities queryDeveloper: self.executable];
      
      if(developer.length > 0)
        {
        self.authorName = developer;
        self.safetyScore = 100;
        return;
        }
      }
    else if([self.signature isEqualToString: kShell])
      executableType = ECLocalizedString(@"Shell Script");
    }
   
  self.authorName = executableType;
  self.plistCRC = [Utilities crcFile: self.path];
  self.executableCRC = [Utilities crcFile: self.executable];
  }
  
// Get the modification date.
- (void) getModificationDate
  {
  self.modificationDate = [Utilities modificationDate: self.path];

  if(self.executable.length > 0)
    if([[NSFileManager defaultManager] fileExistsAtPath: self.executable])
      {
      NSDate * executableModificationDate = 
        [Utilities modificationDate:self.executable];
        
      if([executableModificationDate isLaterThan: self.modificationDate])
        self.modificationDate = executableModificationDate;
      }
  }
  
// Find new tasks for this file.
- (void) findNewTasks
  {
  if([[OSVersion shared] major] >= kYosemite)
    [self findNewLaunchdTasks];
  else
    [self findNewServiceManagementTasks];
  }
  
// Find new load all entries.
- (void) findNewLaunchdTasks
  {
  [self findNewSystemLaunchdTasks];
  [self findNewUserLaunchdTasks];
  [self findNewGUILaunchdTasks];
  }
  
// Load all system domain tasks.
- (void) findNewSystemLaunchdTasks
  {
  SubProcess * launchctl = [[SubProcess alloc] init];
  
  NSString * target = @"system/";
  
  NSArray * arguments = 
    [[NSArray alloc] initWithObjects: @"print", target, nil];
    
  [target release];
  
  if([launchctl execute: @"/bin/launchctl" arguments: arguments])
    if(launchctl.standardOutput.length > 0)
      [self 
        findNewLaunchdTasksInData: launchctl.standardOutput 
        domain: kLaunchdSystemDomain];
      
  [arguments release];
  [launchctl release];
  }

// Load all user domain tasks.
- (void) findNewUserLaunchdTasks
  {
  SubProcess * launchctl = [[SubProcess alloc] init];
  
  uid_t uid = getuid();
    
  NSString * target = [[NSString alloc] initWithFormat: @"user/%d/", uid];
  
  NSArray * arguments = 
    [[NSArray alloc] initWithObjects: @"print", target, nil];
    
  [target release];
  
  if([launchctl execute: @"/bin/launchctl" arguments: arguments])
    if(launchctl.standardOutput.length > 0)
      [self 
        findNewLaunchdTasksInData: launchctl.standardOutput 
        domain: kLaunchdUserDomain];
      
  [arguments release];
  [launchctl release];
  }

// Load all gui domain tasks.
- (void) findNewGUILaunchdTasks
  {
  SubProcess * launchctl = [[SubProcess alloc] init];
  
  uid_t uid = getuid();
    
  NSString * target = [[NSString alloc] initWithFormat: @"gui/%d/", uid];
  
  NSArray * arguments = 
    [[NSArray alloc] initWithObjects: @"print", target, nil];
    
  [target release];
  
  if([launchctl execute: @"/bin/launchctl" arguments: arguments])
    if(launchctl.standardOutput.length > 0)
      [self 
        findNewLaunchdTasksInData: launchctl.standardOutput 
        domain: kLaunchdGUIDomain];
      
  [arguments release];
  [launchctl release];
  }

// Parse a launchctl output.
- (void) findNewLaunchdTasksInData: (NSData *) data 
  domain: (NSString *) domain
  {
  NSString * plist = 
    [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
  
  // Split lines by new lines.
  NSArray * lines = [plist componentsSeparatedByString: @"\n"];
  
  // Am I parsing services now?
  bool parsingServices = false;
  
  for(NSString * line in lines)
    {
    // If I am parsing services, look for the end indicator.
    if(parsingServices)
      {
      // An argument could be a bare "}". Do a string check with whitespace.
      if([line isEqualToString: @"	}"])
        break;        
    
      [self parseLine: line domain: domain];
      }
      
    else if([line isEqualToString: @"	services = {"])
      parsingServices = true;
    }
    
  [plist release];
  }
  
// Parse a line from a launchd listing.
- (void) parseLine: (NSString *) line domain: (NSString *) domain
  {
  NSString * trimmedLine =
    [line
      stringByTrimmingCharactersInSet:
        [NSCharacterSet whitespaceAndNewlineCharacterSet]];

  NSScanner * scanner = [[NSScanner alloc] initWithString: trimmedLine];
  
  // Yes. These must all be strings. Apple likes to be clever.
  NSString * PID = nil;
  NSString * lastExitCode = nil;
  NSString * label = nil;
  
  BOOL success = 
    [scanner 
      scanUpToCharactersFromSet: 
        [NSCharacterSet whitespaceAndNewlineCharacterSet] 
      intoString: & PID];
  
  if(success)
    {
    success = 
      [scanner 
        scanUpToCharactersFromSet: 
          [NSCharacterSet whitespaceAndNewlineCharacterSet] 
        intoString: & lastExitCode];

    if(success)
      {
      // Labels can have spaces.
      success = 
        [scanner 
          scanUpToCharactersFromSet: [NSCharacterSet newlineCharacterSet] 
          intoString: & label];
  
      if(success && ![PID isEqualToString: @"PID"])
        if([label hasPrefix: self.label])
          [self loadNewTaskWithLabel: label domain: domain];
      }
    }
    
  [scanner release];
  }
  
// Load a task. Just do my best.
- (void) loadNewTaskWithLabel: (NSString *) label 
  domain: (NSString *) domain
  {
  LaunchdLoadedTask * task = 
    [[LaunchdLoadedTask alloc] initWithLabel: label inDomain: domain];
   
  if(task != nil)
    [self.loadedTasks addObject: task];
    
  [task release];
  }
  
// Find new Service Management jobs.
- (void) findNewServiceManagementTasks
  {
  if(& SMCopyAllJobDictionaries != NULL)
    {
    CFArrayRef systemJobs = 
      SMCopyAllJobDictionaries(kSMDomainSystemLaunchd);
    
    for(NSDictionary * dict in (NSArray *)systemJobs)
      {
      LaunchdLoadedTask * task = 
        [[LaunchdLoadedTask alloc] 
          initWithDictionary: dict inDomain: kLaunchdSystemDomain];
      
      if(task != nil)
        if([task.label hasPrefix: self.label])
          [self.loadedTasks addObject: task];
      
      [task release];
      }

    if(systemJobs != NULL)
      CFRelease(systemJobs);
      
    CFArrayRef userJobs = SMCopyAllJobDictionaries(kSMDomainUserLaunchd);
    
    for(NSDictionary * dict in (NSArray *)userJobs)
      {
      LaunchdLoadedTask * task = 
        [[LaunchdLoadedTask alloc] 
          initWithDictionary: dict inDomain: kLaunchdUserDomain];
      
      if(task != nil)
        if([task.label hasPrefix: self.label])
          [self.loadedTasks addObject: task];
      
      [task release];
      }
      
    if(userJobs != NULL)
      CFRelease(userJobs);
    }
  }

#pragma mark - Context

// Find the context based on the path.
- (void) findContext
  {
  if([self.path hasPrefix: @"/System/Library/"])
    self.context = kLaunchdAppleContext;
  else if([self.path hasPrefix: @"/Library/"])
    self.context = kLaunchdSystemContext;
  else if([self.path hasPrefix: @"~/Library/"])
    self.context = kLaunchdUserContext;
  else
    {
    NSString * libraryPath = 
      [NSHomeDirectory() stringByAppendingPathComponent: @"Library"];
      
    if([self.path hasPrefix: libraryPath])
      self.context = kLaunchdUserContext;
    else 
      self.context = kLaunchdUnknownContext;
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
  [attributedString appendString: @"    "];
  
  // People freak out over the word "failed".
  if([self.status  isEqualToString: kStatusFailed])
    [attributedString appendString: self.lastExitCode];
  else
    [attributedString 
      appendAttributedString: [LaunchdTask formatStatus: self.status]];
  
  [attributedString appendString: @"    "];
  }
  
// Append the signature.
- (void) appendSignature: (NSMutableAttributedString *) attributedString
  {
  NSString * modificationDateString =
    [Utilities installDateAsString: self.modificationDate];

  [attributedString appendString: @" "];

  NSMutableString * signature = [NSMutableString new];
  
  [signature appendString: self.authorName];
  
  if((self.plistCRC != nil) && (self.executableCRC != nil))
    [signature appendFormat: @" %@ %@", self.plistCRC, self.executableCRC];
    
  [attributedString 
    appendString: 
      [NSString 
        stringWithFormat: 
          @"(%@ - %@)", signature, modificationDateString]];
          
  [signature release];
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
  [xml startElement: @"launchdfile"];
  
  [xml addElement: @"identifier" value: self.identifier];
  [xml addElement: @"status" value: self.status];
  [xml addElement: @"lastexitcode" value: self.lastExitCode];
  [xml addElement: @"path" value: self.path];
  [xml addElement: @"label" value: self.label];
  [xml addElement: @"filename" value: [self.path lastPathComponent]];
  [xml addElement: @"apple" boolValue: self.apple];
  
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
    
  [xml addElement: @"plistcrc" value: self.plistCRC];
  [xml addElement: @"executablecrc" value: self.executableCRC];
    
  if(self.modificationDate != nil)
    [xml addElement: @"installdate" date: self.modificationDate];

  [xml addElement: @"safety" intValue: self.safetyScore];
  
  [xml endElement: @"launchdfile"];
  }

@end
