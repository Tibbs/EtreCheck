/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "ConfigurationCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Model.h"
#import "Utilities.h"
#import "SubProcess.h"
#import "XMLBuilder.h"

#define kRootlessPrefix @"System Integrity Protection status:"

// Collect changes to config files like /etc/sysctl.conf and /etc/hosts.
@implementation ConfigurationCollector

@synthesize configFiles = myConfigFiles;
@synthesize modifiedFiles = myModifiedFiles;
@synthesize modifications = myModifications;

// Constructor.
- (id) init
  {
  self = [super initWithName: @"configurationfiles"];
  
  if(self)
    {
    return self;
    }
    
  return nil;
  }

// Destructor.
- (void) dealloc
  {
  self.configFiles = nil;
  self.modifiedFiles = nil;
  self.modifications = nil;
  
  [super dealloc];
  }

// Perform the collection.
- (void) performCollection
  {
  [self
    updateStatus: NSLocalizedString(@"Checking configuration files", NULL)];

  [self checkExistingConfigFiles];
  
  bool haveChanges = [self.configFiles count] > 0;

  [self checkModifiedConfigFiles];

  if([self.modifiedFiles count] > 0)
    haveChanges = YES;
    
  [self checkOtherModifications];
  
  if([self.modifications count] > 0)
    haveChanges = YES;
  
  // See if /etc/hosts has any changes or is corrupt.
  bool corrupt = NO;
  
  NSUInteger hostsCount = [self hostsStatus: & corrupt];
  
  if(hostsCount || corrupt)
    haveChanges = YES;
    
  // Only print this section if I have changes.
  if(haveChanges)
    {
    [self.result appendAttributedString: [self buildTitle]];
    
    [self printModifiedFiles];

    [self printUnexpectedFiles];
      
    // Print changes to /etc/hosts.
    [self printHostsStatus: corrupt count: hostsCount];
    
    [self printOtherModifications];
      
    [self.result appendCR];
    }
    
  dispatch_semaphore_signal(self.complete);
  }

// Find modified configuration files.
- (void) checkModifiedConfigFiles
  {
  NSMutableArray * files = [NSMutableArray array];
  
  NSFileManager * fileManager = [NSFileManager defaultManager];
  
  NSDictionary * attributes =
    [fileManager attributesOfItemAtPath: @"/etc/sudoers" error: NULL];
  
  // See if /etc/sudoers has been modified.
  if(attributes)
    {
    int version = [[Model model] majorOSVersion];
    unsigned long long expectedSize = attributes.fileSize;
    
    switch(version)
      {
      case kSnowLeopard:
        expectedSize = 1242;
        break;
      case kLion:
        expectedSize = 1275;
        break;
      case kMountainLion:
        expectedSize = 1275;
        break;
      case kMavericks:
        expectedSize = 1275;
        break;
      case kYosemite:
        expectedSize = 1275;
        break;
      case kElCapitan:
        expectedSize = 2299;
        break;
      case kSierra:
        expectedSize = 1563;
        break;
      }
    
    // All the beta testers have an El Capitan file.
    // I guess this is permanently broken.
    if([[Model model] ignoreKnownAppleFailures])
      if((version >= kYosemite) && (attributes.fileSize == 2299))
        expectedSize = 2299;

    if(attributes.fileSize != expectedSize)
      {
      [self.XML startElement: kConfigurationFileWrongSize];
      
      [self.XML addAttribute: kSeverity value: kSerious];
      [self.XML addAttribute: kSeverityExplanation value: @"Wrong size"];

      [self.XML addElement: kConfigurationFileName value: @"/etc/sudoers"];
      [self.XML
        addElement: kConfigurationFileSize
        unsignedLonglongValue: attributes.fileSize];
      [self.XML
        addElement: kConfigurationFileExpectedSize
        unsignedLonglongValue: expectedSize];
      
      [self.XML endElement: kConfigurationFileWrongSize];
      
      [files
        addObject:
          [NSString
            stringWithFormat:
              NSLocalizedString(
                @"    %@, File size %llu but expected %llu\n",
                NULL),
              @"/etc/sudoers",
              attributes.fileSize,
              expectedSize]];
      }
    }
  
  self.modifiedFiles = files;
  }

// Find existing configuration files.
- (void) checkExistingConfigFiles
  {
  NSMutableArray * files = [NSMutableArray array];
  
  NSFileManager * fileManager = [NSFileManager defaultManager];
  
  // See if /etc/sysctl.conf exists.
  if([fileManager fileExistsAtPath: @"/etc/sysctl.conf"])
    {
    [self.XML startElement: kConfigurationFileUnexpected];
    
    [self.XML addAttribute: kSeverity value: kSerious];
    [self.XML addAttribute: kSeverityExplanation value: @"unexpected"];

    [self.XML
      addElement: kConfigurationFileName value: @"/etc/sysctl.conf"];
    
    [self.XML endElement: kConfigurationFileUnexpected];

    [files addObject: @"/etc/sysctl.conf"];
    }
    
  // See if /etc/launchd.conf exists.
  if([fileManager fileExistsAtPath: @"/etc/launchd.conf"])
    {
    [self.XML startElement: kConfigurationFileUnexpected];
    
    [self.XML addAttribute: kSeverity value: kSerious];
    [self.XML addAttribute: kSeverityExplanation value: @"unexpected"];

    [self.XML
      addElement: kConfigurationFileName value: @"/etc/launchd.conf"];
    
    [self.XML endElement: kConfigurationFileUnexpected];

    [files addObject: @"/etc/launchd.conf"];
    }
    
  self.configFiles = files;
  }

// Check for other modifications.
- (void) checkOtherModifications
  {
  NSMutableArray * otherModificiations = [NSMutableArray array];
  
  if([[Model model] majorOSVersion] >= kElCapitan)
    {
    NSString * status = [self checkRootlessStatus];
  
    [self.XML startElement: kConfigurationSIP];
      
    if([status isEqualToString: @"enabled"])
      {
      [self.XML
        addElement: kConfigurationSIPValue value: @"enabled"];
        
      [[Model model] setSIP: YES];
      }
    else
      {
      [self.XML addAttribute: kSeverity value: kSerious];
      [self.XML addAttribute: kSeverityExplanation value: @"SIP disabled"];
      
      [self.XML
        addElement: kConfigurationSIPValue value: status];

      [otherModificiations
        addObject:
          [[[NSMutableAttributedString alloc]
            initWithString:
              [NSString
                stringWithFormat:
                  NSLocalizedString(
                    @"System Integrity Protection status: %@", NULL),
                  status]
            attributes:
              [NSDictionary
                dictionaryWithObjectsAndKeys:
                  [NSColor redColor], NSForegroundColorAttributeName, nil]]
            autorelease]];
      }

    [self.XML endElement: kConfigurationSIP];
    }
    
  self.modifications = otherModificiations;
  }

// Check System Integrity Protection.
- (NSString *) checkRootlessStatus
  {
  bool csrutilExists =
    [[NSFileManager defaultManager] fileExistsAtPath: @"/usr/bin/csrutil"];
    
  if(!csrutilExists)
    return NSLocalizedString(@"/usr/bin/crutil missing", NULL);
    
  // Now consolidate destination information.
  NSArray * args =
    @[
      @"status",
    ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  [subProcess autorelease];
  
  if([subProcess execute: @"/usr/bin/csrutil" arguments: args])
    {
    NSString * status =
      [[NSString alloc]
        initWithData: subProcess.standardOutput
        encoding: NSUTF8StringEncoding];
    
    NSString * result = status;
    
    NSScanner * scanner = [NSScanner scannerWithString: status];
    
    if([scanner scanString: kRootlessPrefix intoString: NULL])
      [scanner scanUpToString: @"." intoString: & result];
      
    if(![result length])
      result =
        [NSString
          stringWithFormat:
            NSLocalizedString(@"/usr/bin/csrutil returned \"%@\"", NULL),
            status];
    
    [status release];
    
    return result;
    }
    
  return NSLocalizedString(@"missing", NULL);
  }

// Collect the number of changes to /etc/hosts and its status.
- (NSUInteger) hostsStatus: (bool *) corrupt
  {
  NSUInteger count = 0;
  
  NSString * hosts =
    [NSString
      stringWithContentsOfFile:
        @"/etc/hosts" encoding: NSUTF8StringEncoding error: nil];
  
  NSArray * lines = [hosts componentsSeparatedByString: @"\n"];
  
  for(NSString * line in lines)
    {
    if(![line length])
      continue;
      
    if([line hasPrefix: @"#"])
      continue;
      
    NSString * hostname = [self readHostname: line];
      
    if(corrupt && !hostname)
      *corrupt = YES;
      
    if([hostname length] < 1)
      continue;
      
    if([hostname isEqualToString: @"localhost"])
      continue;

    if([hostname isEqualToString: @"broadcasthost"])
      continue;
            
    ++count;
    }
    
  return count;
  }

// Read a name from /etc/hosts.
// Return nil if the name is invalid or the file is corrupt.
- (NSString *) readHostname: (NSString *) line
  {
  NSString * trimmedLine =
    [line
      stringByTrimmingCharactersInSet:
        [NSCharacterSet whitespaceAndNewlineCharacterSet]];

  if([trimmedLine hasPrefix: @"#"])
    return @"";
    
  if([trimmedLine length] < 1)
    return @"";
    
  NSScanner * scanner = [NSScanner scannerWithString: trimmedLine];
  
  NSString * address = nil;
  
  bool scanned =
    [scanner
      scanUpToCharactersFromSet:
        [NSCharacterSet whitespaceAndNewlineCharacterSet]
      intoString: & address];
  
  if(!scanned)
    return nil;
    
  NSString * name = nil;

  scanned =
    [scanner
      scanUpToCharactersFromSet:
        [NSCharacterSet whitespaceAndNewlineCharacterSet]
      intoString: & name];

  if(!scanned)
    return nil;
    
  return name;
  }

// Print modified files.
- (void) printModifiedFiles
  {
  // Print modified configFiles.
  for(NSString * modifiedFile in self.modifiedFiles)
    [self.result
      appendString: modifiedFile
      attributes:
        [NSDictionary
          dictionaryWithObjectsAndKeys:
            [NSColor redColor], NSForegroundColorAttributeName, nil]];
  }

// Print unexpected files.
- (void) printUnexpectedFiles
  {
  // Print existing configFiles.
  for(NSString * configFile in self.configFiles)
    [self.result
      appendString:
        [NSString stringWithFormat:
          NSLocalizedString(
            @"    %@ - File exists but not expected\n", NULL),
          configFile]];
  }

// Print other modifications.
- (void) printOtherModifications
  {
  // Print existing configFiles.
  for(NSAttributedString * modification in self.modifications)
    {
    [self.result appendString: @"    "];
    
    [self.result appendAttributedString: modification];
    
    [self.result appendString: @"\n"];
    }
  }

// Print the status of the hosts file.
- (void) printHostsStatus: (bool) corrupt count: (NSUInteger) count
  {
  NSString * corruptString = @"";
  
  if(corrupt)
    corruptString = NSLocalizedString(@" - Corrupt!", NULL);
    
  NSString * countString = @"";
  
  if(count > 0)
    countString =
      [NSString
        stringWithFormat:
          NSLocalizedString(@" - Count: %d", NULL), count];
    
  [self.XML startElement: kConfigurationHostsFile];
    
  NSString * status = @"valid";
  
  if((count > 10) || corrupt)
    {
    [self.XML addAttribute: kSeverity value: kSerious];
    
    if(count > 10)
      {
      status = @"count > 10";
      [self.XML addAttribute: kSeverityExplanation value: @"count > 10"];
      }
    else if(corrupt)
      {
      status = @"corrupt";
      [self.XML
        addAttribute: kSeverityExplanation value: @"hosts file corrupt"];
      }
      
    [self.result
      appendString:
        [NSString
          stringWithFormat:
            NSLocalizedString(@"    /etc/hosts%@%@\n", NULL),
            countString, corruptString]
      attributes:
        [NSDictionary
          dictionaryWithObjectsAndKeys:
            [NSColor redColor], NSForegroundColorAttributeName, nil]];
    }
  else if(count > 0)
    [self.result
      appendString:
        [NSString
          stringWithFormat:
            NSLocalizedString(@"    /etc/hosts%@%@\n", NULL),
            countString, corruptString]];

  [self.XML
    addElement: kConfigurationHostsFileCount integerValue: count];
  [self.XML
    addElement: kConfigurationHostsFileStatus value: status];

  [self.XML endElement: kConfigurationHostsFile];
  }

@end
