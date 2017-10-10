/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "LaunchdCollector.h"
#import "Launchd.h"
#import "LaunchdFile.h"
#import "XMLBuilder.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"
#import "EtreCheckConstants.h"
#import "LocalizedString.h"
#import "Model.h"

// Collect all sorts of launchd information.
@implementation LaunchdCollector

// Additional attributes indexed by path.
@synthesize attributes = myAttributes;

// Destructor.
- (void) dealloc
  {
  [myAttributes release];
  
  [super dealloc];
  }
  
// Perform the collection.
- (void) performCollect
  {
  // Create attributes for these launchd files.
  myAttributes = [NSMutableDictionary new];
  
  // Load all launchd files. No-op after first call.
  [[[Model model] launchd] load];
  }

// Print files in a given directory.
- (void) printFilesInDirectory: (NSString *) directory
  {
  NSMutableArray * files = [NSMutableArray new];
  
  for(NSString * path in [[[Model model] launchd] tasksByPath])
    if([path hasPrefix: directory])
      {
      LaunchdFile * file = 
        [[[[Model model] launchd] tasksByPath] objectForKey: path];
      
      if(file != nil)
        [files addObject: file];
      }
      
  [self printFiles: files];
  
  [files release];
  }
  
// Print tasks.
- (void) printFiles: (NSArray *) files
  {
  // I will have already filtered out launchd files specific to this 
  // context.
  for(LaunchdFile * file in files)
    {
    // Collect additional information about this file.
    [self collectFileInformation: file];
    
    // Print the file.
    [self printFile: file];
    
    // Export the XML.
    [self exportXMLFile: file];
    }
  }

// Collect additional information about this file.
- (void) collectFileInformation: (LaunchdFile *) file
  {
  // Create attributes for this file.
  NSMutableDictionary * attributes = [NSMutableDictionary new];
  
  [self.attributes setObject: attributes forKey: file.path];
  
  [attributes release];
  
  // Set install date.
  attributes[@"installdate"] = [self modificationDate: file.path];
  
  // Set signature and developer, if any.
  [self checkSignature: file attributes: attributes];
  }
  
// Get the modification date of a file.
- (NSDate *) modificationDate: (NSString *) path
  {
  NSRange appRange = [path rangeOfString: @".app/Contents/MacOS/"];
  
  if(appRange.location != NSNotFound)
    path = [path substringToIndex: appRange.location + 4];

  return [Utilities modificationDate: path];
  }

// Collect the signature of a launchd item.
- (void) checkSignature: (LaunchdFile *) file 
  attributes: (NSMutableDictionary *) attributes
  {
  // I need an executable for this.
  if(file.executable.length > 0)
    {
    NSString * signature = [Utilities checkExecutable: file.executable];
    
    if([signature length] > 0)
      {
      [attributes setObject: signature forKey: kSignature];
        
      // If I have a valid executable, query the actual developer.
      if([signature isEqualToString: kSignatureValid])
        {
        NSString * developer = [Utilities queryDeveloper: file.executable];
        
        if(developer.length > 0)
          {
          [attributes setObject: developer forKey: kDeveloper];
          
          return;
          }
        }
      }
      
    // If I have an executable, record the CRC.
    [attributes 
      setObject: [Utilities crcFile: file.executable] 
      forKey: kExecutableCRC];
    }
    
  // I should always have a plist CRC.
  [attributes setObject: [Utilities crcFile: file.path] forKey: kPlistCRC];
  }

// Print the file.
- (void) printFile: (LaunchdFile *) file
  {
  NSDictionary * attributes = [self.attributes objectForKey: file.path];
  
  // Print the status.
  [self printFileStatus: file];
  
  // Print the file name. Only the leaf part is necessary.
  [self.result appendString: [file.path lastPathComponent]];
  
  // Print the signature, or lack thereof.
  [self printSignatureForFile: file attributes: attributes];
  
  // Print a support link.
  [self printSupportLinkForFile: file];
  
  // Print an adware indicator.
  [self printAdwareForFile: file attributes: attributes];
  
  [self.result appendString: @"\n"];
  }
  
// Print the file status.
- (void) printFileStatus: (LaunchdFile *) file
  {
  NSString * statusString = ECLocalizedString(@"not loaded");
  
  NSColor * color = [[Utilities shared] gray];
  
  if([file.status isEqualToString: kStatusLoaded])
    {
    statusString = ECLocalizedString(@"loaded");
    color = [[Utilities shared] blue];
    }
  else if([file.status isEqualToString: kStatusRunning])
    {
    statusString = ECLocalizedString(@"running");
    color = [[Utilities shared] green];
    }
  else if([file.status isEqualToString: kStatusFailed])
    {
    statusString = ECLocalizedString(@"failed");
    color = [[Utilities shared] red];
    }
  else if([file.status isEqualToString: kStatusKilled])
    {
    statusString = ECLocalizedString(@"killed");
    color = [[Utilities shared] red];
    }
  
  NSMutableAttributedString * output =
    [[NSMutableAttributedString alloc] init];
    
  [self.model addElement: @"status" value: statusString];
  
  [output
    appendString: [NSString stringWithFormat: @"    [%@]    ", statusString]
    attributes:
      @{
        NSForegroundColorAttributeName : color,
        NSFontAttributeName : [[Utilities shared] boldFont]
      }];
  
  [self.result appendAttributedString: output];
  
  [output release];
  }
  
// Print the signature.
- (void) printSignatureForFile: (LaunchdFile *) file 
  attributes: (NSDictionary *) attributes
  {
  NSString * plistCRC = [attributes objectForKey: kPlistCRC];
  NSString * executableCRC = [attributes objectForKey: kExecutableCRC];
  NSDate * modificationDate = [attributes objectForKey: kModificationDate];
  NSString * developer = [attributes objectForKey: kDeveloper];

  NSString * modificationDateString =
    [Utilities installDateAsString: modificationDate];

  [self.result appendString: @" "];

  if(developer.length > 0)
    [self.result 
      appendString: 
        [NSString 
          stringWithFormat: 
            @"(%@ - %@)", developer, modificationDateString]];
  else
    [self.result 
      appendString: 
        [NSString 
          stringWithFormat: 
            @"(? %@ %@ - %@)", 
            plistCRC, executableCRC, modificationDateString]];
  }
  
// Print a support link.
- (void) printSupportLinkForFile: (LaunchdFile *) file
  {
  NSString * lookupLink = [self getSupportURLForFile: file];
  
  if(lookupLink.length > 0)
    {
    [self.result appendString: @" "];

    [self.result
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
- (NSString *) getSupportURLForFile: (LaunchdFile *) file
  {
  if([file.label hasPrefix: @"com.apple."])
    return nil;
    
  NSString * filename = [file.path lastPathComponent];
  
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

// Print the adware status, if any, for a file.
- (void) printAdwareForFile: (LaunchdFile *) file 
  attributes: (NSDictionary *) attributes
  {
  NSNumber * adware = [attributes objectForKey: @"adware"];
  
  if([adware boolValue])
    {
    [self.result appendString: @" "];

    [self.result
      appendString: ECLocalizedString(@"Adware!")
      attributes:
        @{
          NSForegroundColorAttributeName : [[Utilities shared] red],
          NSFontAttributeName : [[Utilities shared] boldFont]
        }];
        
    if(file.executable.length > 0)
      {
      [self.result appendString: @" "];

      [self.result appendString: @"\n        "];
      [self.result appendString: [Utilities cleanPath: file.executable]];
      }
    }
  }
  
// Export a file as XML.
- (void) exportXMLFile: (LaunchdFile *) file
  {
  [self.model startElement: @"file"];
  
  NSDictionary * attributes = [self.attributes objectForKey: file.path];
  
  NSString * plistCRC = [attributes objectForKey: kPlistCRC];
  NSString * executableCRC = [attributes objectForKey: kExecutableCRC];
  NSDate * modificationDate = [attributes objectForKey: kModificationDate];
  NSNumber * unknown = [attributes objectForKey: kUnknown];
  NSString * signature = [attributes objectForKey: kSignature];
  NSString * developer = [attributes objectForKey: kDeveloper];
  NSNumber * adware = [attributes objectForKey: kAdware];

  [self.model addElement: @"status" value: file.status];
  [self.model addElement: @"path" value: file.path];
  [self.model addElement: @"label" value: file.label];
  
  if(plistCRC.length > 0)
    [self.model addElement: @"plistcrc" value: plistCRC];
    
  if(executableCRC.length > 0)
    [self.model addElement: @"execrc" value: executableCRC];

  if(file.executable.length > 0)
    [self.model addElement: @"executable" value: file.executable];
  
  if(file.arguments.count > 0)
    {
    [self.model startElement: @"arguments"];
    
    for(NSString * argument in file.arguments)
      [self.model addElement: @"argument" value: argument];
      
    [self.model endElement: @"arguments"];
    }
    
  [self.model addElement: @"valid" boolValue: file.configScriptValid];
  
  if(signature.length > 0)
    [self.model addElement: @"signature" value: signature];
    
  if(developer.length > 0)
    [self.model addElement: @"developer" value: developer];

  if(modificationDate != nil)
    [self.model addElement: @"installdate" date: modificationDate];

  if(unknown != nil)
    [self.model addElement: @"unknown" boolValue: unknown.boolValue];

  if(adware != nil)
    [self.model addElement: @"adware" boolValue: adware.boolValue];
    
  [self.model endElement: @"file"];
  }
  
@end
