/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "UbiquityContainer.h"
#import "UbiquityContainerDirectory.h"
#import "UbiquityFile.h"
#import "XMLBuilder.h"

@implementation UbiquityContainer

// The ubiquity ID for this container.
@synthesize ubiquityID = myUbiquityID;

// This container's bundle ID.
@synthesize bundleID = myBundleID;

// A dictionary of UbiquityContainerDirectories.
@synthesize directories = myDirectories;

// The current directory.
@synthesize currentDirectory = myCurrentDirectory;

// The pending file count.
@dynamic pendingFileCount;

// The pending file count.
- (int) pendingFileCount
  {
  int count = 0;
  
  for(NSString * directoryName in self.directories)
    {
    UbiquityContainerDirectory * directory = 
      [self.directories objectForKey: directoryName];
      
    if(directory != nil)
      for(UbiquityFile * file in directory.pendingFiles)
        if(file.name.length > 0)
          ++count;
    }
    
  return count;
  }
  
// Constructor.
- (instancetype) initWithUbiquityID: (NSString *) ubiquityID
  {
  self = [super init];
  
  if(self != nil)
    {
    myUbiquityID = [ubiquityID retain];
    myDirectories = [NSMutableDictionary new];
    
    [self setupBundleID];
    }
    
  return self;
  }
  
// Destructor.
- (void) dealloc
  {
  [myUbiquityID release];
  
  self.bundleID = nil;
  self.directories = nil;
  self.currentDirectory = nil;
  
  [super dealloc];
  }
  
// Parse a line from brctl status.
- (void) parseBrctlStatusLine: (NSString *) line
  {
  NSString * trimmedLine =
    [line
      stringByTrimmingCharactersInSet:
        [NSCharacterSet whitespaceAndNewlineCharacterSet]];

  if([trimmedLine hasPrefix: @"Under "])
    [self parseDirectoryName: [trimmedLine substringFromIndex: 6]];
  else if([trimmedLine hasPrefix: @"r:"])
    [self parseFileName: trimmedLine];
  else if([trimmedLine hasPrefix: @"> upload{"])
    [self parseUploadStatus: line];
  else if([trimmedLine hasPrefix: @"> downloader{"])
    [self parseDownloadStatus: line];
  }
  
// Parse a directory name.
- (void) parseDirectoryName: (NSString *) directoryName
  {
  if(directoryName.length == 0)
    directoryName = @"/";
    
  UbiquityContainerDirectory * directory = 
    [[UbiquityContainerDirectory alloc] 
      initWithContainer: self directory: directoryName];
  
  self.currentDirectory = directory;
  
  if(directory != nil)
    [self.directories setObject: directory forKey: directoryName];
  
  [directory release];
  }
  
// Parse a file name.
- (void) parseFileName: (NSString *) line
  {
  NSString * name = nil;
  
  NSRange range = [line rangeOfString: @" sz:"];
  
  if(range.location != NSNotFound)
    {
    NSString * data = [line substringFromIndex: range.location + 8];
    
    NSRange nRange = [data rangeOfString: @" n:\""];
    NSRange sigRange = [data rangeOfString: @" sig:"];
    
    if((nRange.location != NSNotFound) && (sigRange.location != NSNotFound))
      if((sigRange.location - 2) > (nRange.location + 4))
        {
        NSRange nameRange = 
            NSMakeRange(
              nRange.location + 4, 
              sigRange.location - 1 - nRange.location - 4);
              
        name = [data substringWithRange: nameRange];
        }
    }
      
  if(name.length > 0)
    {
    UbiquityFile * file = [[UbiquityFile alloc] initWithName: name];
    
    if(file != nil)
      [self.currentDirectory.pendingFiles addObject: file];
    
    [file release];
    }
  }
  
// Parse an upload status.
- (void) parseUploadStatus: (NSString *) line
  {
  UbiquityFile * file = [self.currentDirectory.pendingFiles lastObject];
  
  file.status = @"uploading";
  file.progress = [self readProgress: file.status line: line];
  }
  
// Parse a download status.
- (void) parseDownloadStatus: (NSString *) line
  {
  UbiquityFile * file = [self.currentDirectory.pendingFiles lastObject];
  
  file.status = @"downloading";
  file.progress = [self readProgress: file.status line: line];
  }

// Read a progress from an iCloud status line.
- (double) readProgress: (NSString *) action line: (NSString *) line
  {
  double percentage = 0.0;
    
  NSString * match = [[NSString alloc] initWithFormat: @" %@:", action];
  
  NSRange range = [line rangeOfString: match];
  
  if(range.location != NSNotFound)
    {
    NSScanner * scanner = 
      [[NSScanner alloc] 
        initWithString: 
          [line substringFromIndex: range.location + match.length]];
    
    [scanner scanDouble: & percentage];
      
    [scanner release];
    }
    
  [match release];
  
  return percentage;
  }

// Setup the bundle ID.
- (void) setupBundleID
  {
  self.bundleID = self.ubiquityID;
  
  NSArray * parts = [self.ubiquityID componentsSeparatedByString: @"."];
  
  if(parts.count > 1)
    {
    NSString * teamID = [parts firstObject];
    
    if(teamID.length == 10)
      self.bundleID = 
        [[parts subarrayWithRange: NSMakeRange(1, parts.count - 1)] 
          componentsJoinedByString: @"."];
    }
  }
  
// Build the XML value.
- (void) buildXMLValue: (XMLBuilder *) xml
  {
  [xml startElement: @"container"];
    
  [xml addElement: @"ubiquityid" value: self.ubiquityID];
  [xml addElement: @"bundleid" value: self.bundleID];
  
  NSMutableDictionary * directories = [NSMutableDictionary new];
  
  for(UbiquityContainerDirectory * directory in self.directories.allValues)
    {
    
    }
    
  [xml startElement: @"directories"];
  [xml endElement: @"directories"];
  
  [directories release];
  
  [xml addArray: @"directories" values: self.directories.allValues];
  
  [xml endElement: @"container"];
  }

@end
