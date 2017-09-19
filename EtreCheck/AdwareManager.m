/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2016-2017. All rights reserved.
 **********************************************************************/

#import "AdwareManager.h"
#import "LibEtreCheck/LibEtreCheck.h"
#import "CURLRequest.h"

#define kRemove @"remove"
#define kWhitelist @"whitelist"
#define kSigned @"signed"
#define kPath @"path"

#define kRemoveColumnIndex 0
#define kWhitelistColumnIndex 1

#define kGetHelp 1
#define kProceed 2

@interface UninstallManager ()

// Show the window with content.
- (void) show: (NSString *) content;

// Uninstall an array of items.
- (void) uninstallItems: (NSMutableArray *) items;

// Verify removal of files.
- (void) verifyRemoveFiles: (NSMutableArray *) files;

// Tell the user that EtreCheck is too old.
- (BOOL) reportOldEtreCheckVersion;

// Tell the user that the EtreCheck version is unverified.
- (BOOL) reportUnverifiedEtreCheckVersion;

@end

@implementation AdwareManager

@synthesize whitelistDescription = myWhitelistDescription;
@synthesize removeButton = myRemoveButton;
@dynamic canReportFiles;
@synthesize reportButton = myReportButton;
@synthesize foundUnknownLegitimateFiles = myFoundUnknownLegitimateFiles;
@synthesize removingUnknownFiles = myRemovingUnknownFiles;

// Can I remove files?
- (BOOL) canRemoveFiles
  {
  int removeCount = 0;
  int whitelistCount = 0;
  BOOL disallow = NO;

  for(NSDictionary * item in self.filesToRemove)
    {
    if([[item objectForKey: kRemove] boolValue])
      ++removeCount;
    else if([[item objectForKey: kWhitelist] boolValue])
      ++whitelistCount;
    else
      disallow = YES;
    }
    
  if(disallow)
    return NO;
    
  return removeCount > 0;
  }

// Can I report files?
- (BOOL) canReportFiles
  {
  int removeCount = 0;
  int whitelistCount = 0;
  BOOL disallow = NO;

  for(NSDictionary * item in self.filesToRemove)
    {
    if([[item objectForKey: kRemove] boolValue])
      ++removeCount;
    else if([[item objectForKey: kWhitelist] boolValue])
      ++whitelistCount;
    else
      disallow = YES;
    }
    
  if(disallow)
    return NO;
    
  return whitelistCount > 0;
  }

// Constructor.
- (id) init
  {
  if(self = [super init])
    {
    myWhitelistDescription = [NSAttributedString new];
    }
    
  return self;
  }

// Destructor.
- (void) dealloc
  {
  self.removeButton = nil;
  self.reportButton = nil;
  self.whitelistDescription = nil;

  [super dealloc];
  }

// Show the window.
- (void) show
  {
  [super show: NSLocalizedString(@"adware", NULL)];
  
  [self willChangeValueForKey: @"canRemoveFiles"];
  [self willChangeValueForKey: @"canReportFiles"];
  
  self.filesRemoved = NO;
  
  NSMutableDictionary * filesToRemove = [NSMutableDictionary new];
  
  for(NSString * path in [[Model model] adwareLaunchdFiles])
    {
    NSDictionary * info = [[[Model model] launchdFiles] objectForKey: path];

    if(info != nil)
      {
      NSMutableDictionary * item = [NSMutableDictionary new];
      
      [item setObject: path forKey: kPath];
      [item setObject: info forKey: kLaunchdTask];
      
      [filesToRemove setObject: item forKey: path];
      
      [item setObject: [NSNumber numberWithBool: YES] forKey: kRemove];
        
      [item release];
      }
    }
    
  for(NSString * path in [[Model model] adwareFiles])
    {
    if([filesToRemove objectForKey: path] == nil)
      {
      // Double-check to make sure the file is still there.
      BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath: path];
      
      if(exists)
        {
        NSString * pathToRemove = [Utilities makeURLPath: path];
        
        NSMutableDictionary * item = [NSMutableDictionary new];
        
        [item setObject: pathToRemove forKey: kPath];
        
        [filesToRemove setObject: item forKey: path];
        
        [item setObject: [NSNumber numberWithBool: YES] forKey: kRemove];
        
        [item release];
        }
      }
    }
  
  NSArray * sortedFilesToRemove =
    [[filesToRemove allKeys] sortedArrayUsingSelector: @selector(compare:)];
  
  for(NSString * file in sortedFilesToRemove)
    {
    NSMutableDictionary * item = [filesToRemove objectForKey: file];
    
    if(item)
      [self.filesToRemove addObject: item];
    }

  [filesToRemove release];
  
  [self.tableView reloadData];

  [self didChangeValueForKey: @"canReportFiles"];
  [self didChangeValueForKey: @"canRemoveFiles"];
  }

// Close the window.
- (IBAction) close: (id) sender
  {
  self.whitelistDescription = nil;

  [super close: sender];
  }

// Remove the files.
- (IBAction) removeFiles: (id) sender
  {
  if([super canRemoveFiles])
    {
    if(self.removingUnknownFiles)
      {
      int proceed = [self warnDeleteUnknown];
      
      if(proceed == kProceed)
        if(self.foundUnknownLegitimateFiles && self.removingUnknownFiles)
          proceed = [self warnDeleteUnknownAgain];
        
      if(proceed == kGetHelp)
        [self getHelp];
        
      if(proceed != kProceed)
        return;
      }
        
    NSMutableArray * filesToRemove = [NSMutableArray new];
    NSMutableArray * filesToKeep = [NSMutableArray new];
    
    for(NSMutableDictionary * item in self.filesToRemove)
      if([[item objectForKey: kRemove] boolValue])
        [filesToRemove addObject: item];
      else
        [filesToKeep addObject: item];
      
    [self willChangeValueForKey: @"canRemoveFiles"];
  
    [super uninstallItems: filesToRemove];
    
    [self.filesToRemove removeAllObjects];
    [self.filesToRemove addObjectsFromArray: filesToKeep];
    [self.filesToRemove addObjectsFromArray: filesToRemove];
    
    [self didChangeValueForKey: @"canRemoveFiles"];

    [self.tableView reloadData];

    [filesToKeep release];
    [filesToRemove release];
    }
  }

// Verify removal of files.
- (void) verifyRemoveFiles: (NSMutableArray *) files
  {
  [super verifyRemoveFiles: files];

  NSMutableArray * filesNotRemoved = [NSMutableArray new];
  
  for(NSDictionary * item in files)
    if([[item objectForKey: kFileDeleted] boolValue])
      self.filesRemoved = YES;
    else
      [filesNotRemoved addObject: item];
  
  [files setArray: filesNotRemoved];
  
  [filesNotRemoved release];
  }

// Contact Etresoft to add to whitelist.
- (IBAction) report: (id) sender
  {
  NSString * description = [self.whitelistDescription string];
  
  if([description length] < 10)
    {
    [self requireDescription];
    
    return;
    }
  
  NSMutableString * json = [NSMutableString string];
  
  [json appendString: @"{\"action\":\"report\","];
  [json appendString: @"\"files\":["];
  
  bool first = YES;

  for(NSDictionary * item in self.filesToRemove)
    {
    NSString * path = [item objectForKey: kPath];
    
    if(!path)
      continue;
      
    NSDictionary * info = [item objectForKey: kLaunchdTask];
    
    NSArray * command =
      [path length] > 0
        ? [info objectForKey: kCommand]
        : nil;
    
    NSString * cmd =
      [command count] > 0
        ? [command componentsJoinedByString: @" "]
        : @"";

    path =
      [path stringByReplacingOccurrencesOfString: @"\"" withString: @"'"];
      
    NSString * name = [path lastPathComponent];
    
    if(!first)
      [json appendString: @","];
      
    first = NO;
    
    [json appendString: @"{"];
    
    [json
      appendFormat: @"\"known\":\"%@\",", [item objectForKey: kWhitelist]];
    
    [json
      appendFormat:
        @"\"signature\":\"%@\",", [item objectForKey: kSignature]];

    [json appendFormat: @"\"name\":\"%@\",", name];
    [json appendFormat: @"\"path\":\"%@\",", path];
    [json appendFormat: @"\"cmd\":\"%@\"", cmd];
      
    [json appendString: @"}"];
    }
    
  [json appendString: @"],"];
  [json
    appendFormat:
      @"\"description\":\"%@\"}",
      [description
        stringByReplacingOccurrencesOfString: @"\"" withString: @"'"]];
  
  POST * request =
    [[POST alloc]
      init:
        [Utilities
          buildSecureURLString:
            @"etrecheck.com/server/adware_detection.php"]
      callback:
        ^(CURLRequest * curlRequest, BOOL success)
          {
          dispatch_async(
            dispatch_get_main_queue(),
            ^{
              if(success)
                if([curlRequest.responseString isEqualToString: @"OK"])
                  {
                  [self thanksForSubmission];
                  
                  return;
                  }
    
              [self submissionFallbackToEmail];
            });
          }];

  dispatch_async(
    dispatch_get_global_queue(
      DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
      ^{
        [request send: json];
        [request release];
      });
  }

// Require a description for reporting.
- (void) requireDescription
  {
  NSAlert * alert = [[NSAlert alloc] init];

  [alert
    setMessageText: NSLocalizedString(@"Description required", NULL)];
    
  [alert setAlertStyle: NSInformationalAlertStyle];

  [alert
    setInformativeText: NSLocalizedString(@"descriptionrequired", NULL)];

  // This is the rightmost, first, default button.
  [alert addButtonWithTitle: NSLocalizedString(@"OK", NULL)];

  [alert runModal];

  [alert release];
  }

// Thank the user for their submission.
- (void) thanksForSubmission
  {
  NSAlert * alert = [[NSAlert alloc] init];

  [alert
    setMessageText: NSLocalizedString(@"Thanks for your submission", NULL)];
    
  [alert setAlertStyle: NSInformationalAlertStyle];

  [alert
    setInformativeText: NSLocalizedString(@"thanksforsubmission", NULL)];

  // This is the rightmost, first, default button.
  [alert addButtonWithTitle: NSLocalizedString(@"OK", NULL)];

  [alert runModal];

  [alert release];
  }

// Allow the user to submit an update via e-mail.
- (void) submissionFallbackToEmail
  {
  NSAlert * alert = [[NSAlert alloc] init];

  [alert
    setMessageText: NSLocalizedString(@"Submission failed", NULL)];
    
  [alert setAlertStyle: NSInformationalAlertStyle];

  [alert
    setInformativeText: NSLocalizedString(@"submissionfailed", NULL)];

  // This is the rightmost, first, default button.
  [alert
    addButtonWithTitle: NSLocalizedString(@"Yes - Send via e-mail", NULL)];

  [alert addButtonWithTitle: NSLocalizedString(@"No", NULL)];

  NSInteger result = [alert runModal];

  if(result == NSAlertFirstButtonReturn)
    {
    NSMutableString * content = [NSMutableString string];
    
    [content
      appendString: @"EtreCheck found the following unknown files:\n\n"];

    for(NSDictionary * item in self.filesToRemove)
      {
      NSString * path = [item objectForKey: kPath];
    
      if([path length] > 0)
        [content
          appendString:
            [NSString
              stringWithFormat:
                @"%@ %@\n",
                [[item objectForKey: kWhitelist] boolValue]
                  ? @"Known" : @"Unknown",
                path]];
      }
      
    [content appendString: @"\n\n"];
    [content appendString: [self.whitelistDescription string]];
    [content appendString: @"\n"];
      
    [Utilities
      sendEmailTo: @"info@etresoft.com"
      withSubject: @"Unknown files report"
      content: content];
    }

  [alert release];
  }

// Get the user some help.
- (void) getHelp
  {
  [[NSWorkspace sharedWorkspace]
    openURL:
      [NSURL
        URLWithString:
          [Utilities
            buildSecureURLString: NSLocalizedString(@"ascurl", NULL)]]];
  }

// Warn the user that they are deleting unknown files.
- (int) warnDeleteUnknown
  {
  NSAlert * alert = [[NSAlert alloc] init];

  [alert
    setMessageText:
      NSLocalizedString(@"Are you sure?", NULL)];
    
  [alert setAlertStyle: NSWarningAlertStyle];

  [alert
    setInformativeText:
      NSLocalizedString(@"warndeleteunknown", NULL)];

  // This is the rightmost, first, default button.
  [alert addButtonWithTitle: NSLocalizedString(@"Cancel", NULL)];

  [alert
    addButtonWithTitle: NSLocalizedString(@"Get Help", NULL)];

  [alert
    addButtonWithTitle: NSLocalizedString(@"Continue", NULL)];

  NSInteger result = [alert runModal];

  [alert release];

  if(result == NSAlertSecondButtonReturn)
    return kGetHelp;
    
  if(result == NSAlertThirdButtonReturn)
    return kProceed;
    
  return 0;
  }

// Warn the user that they are probably deleting legitimate unknown files.
- (int) warnDeleteUnknownAgain
  {
  NSAlert * alert = [[NSAlert alloc] init];

  [alert
    setMessageText:
      NSLocalizedString(@"Are you sure you are sure?", NULL)];
    
  [alert setAlertStyle: NSWarningAlertStyle];

  [alert
    setInformativeText:
      NSLocalizedString(@"warndeletelegitimateunknown", NULL)];

  // This is the rightmost, first, default button.
  [alert addButtonWithTitle: NSLocalizedString(@"Cancel", NULL)];

  [alert
    addButtonWithTitle: NSLocalizedString(@"Get Help", NULL)];

  [alert
    addButtonWithTitle: NSLocalizedString(@"Continue", NULL)];

  NSInteger result = [alert runModal];

  [alert release];

  if(result == NSAlertSecondButtonReturn)
    return kGetHelp;
    
  if(result == NSAlertThirdButtonReturn)
    return kProceed;
    
  return 0;
  }

#pragma mark - NSTableViewDataSource

- (NSInteger) numberOfRowsInTableView: (NSTableView *) aTableView
  {
  return self.filesToRemove.count;
  }

- (id) tableView: (NSTableView *) tableView
  objectValueForTableColumn: (NSTableColumn *) tableColumn
  row: (NSInteger) row
  {
  if(row >= self.filesToRemove.count)
    return nil;

  NSMutableDictionary * item = [self.filesToRemove objectAtIndex: row];
  
  NSString * path = [item objectForKey: kPath];
  NSString * name = [path lastPathComponent];
  
  NSDictionary * info = [item objectForKey: kLaunchdTask];
    
  NSString * signature = [info objectForKey: kSignature];

  BOOL isSigned = NO;
  BOOL isDatFile = NO;
  
  if([signature isEqualToString: kSignatureApple])
    isSigned = YES;
  else if([signature isEqualToString: kSignatureValid])
    isSigned = YES;

  if([name hasPrefix: @"."])
    isDatFile = YES;
    
  // Signed files can only be whitelisted.
  // .dat files can only be removed.
  if([[tableColumn identifier] isEqualToString: kWhitelist])
    {
    NSButtonCell * cell = [tableColumn dataCellForRow: row];
    
    [cell setEnabled: (!isDatFile || !isSigned)];

    return [item objectForKey: kWhitelist];
    }
    
  // Signed files can only be whitelisted.
  // .dat files can only be removed.
  if([[tableColumn identifier] isEqualToString: kRemove])
    {
    NSButtonCell * cell = [tableColumn dataCellForRow: row];
    
    [cell setEnabled: (!isDatFile || !isSigned)];
      
    return [item objectForKey: kRemove];
    }
    
  if([[tableColumn identifier] isEqualToString: kSigned])
    return [NSNumber numberWithBool: isSigned];
    
  if([[tableColumn identifier] isEqualToString: kPath])
    return [item objectForKey: kPath];
    
  return nil;
  }

- (void) tableView: (NSTableView *) tableView
  setObjectValue: (id) object
  forTableColumn: (NSTableColumn *) tableColumn
  row: (NSInteger) row
  {
  if(row >= self.filesToRemove.count)
    return;
    
  [self willChangeValueForKey: @"canRemoveFiles"];
  [self willChangeValueForKey: @"canReportFiles"];
    
  NSMutableDictionary * item = [self.filesToRemove objectAtIndex: row];
    
  if([[tableColumn identifier] isEqualToString: kWhitelist])
    {
    [item setObject: object forKey: kWhitelist];
    
    if([object boolValue])
      [item setObject: [NSNumber numberWithBool: NO] forKey: kRemove];

    [tableView
      reloadDataForRowIndexes: [NSIndexSet indexSetWithIndex: row]
      columnIndexes: [NSIndexSet indexSetWithIndex: kRemoveColumnIndex]];
    }
  else if([[tableColumn identifier] isEqualToString: kRemove])
    {
    [item setObject: object forKey: kRemove];
    
    if([object boolValue])
      {
      [item setObject: [NSNumber numberWithBool: NO] forKey: kWhitelist];
    
      self.removingUnknownFiles = YES;
      }
      
    [tableView
      reloadDataForRowIndexes: [NSIndexSet indexSetWithIndex: row]
      columnIndexes: [NSIndexSet indexSetWithIndex: kWhitelistColumnIndex]];
    }

  [self didChangeValueForKey: @"canReportFiles"];
  [self didChangeValueForKey: @"canRemoveFiles"];
  }

#pragma mark - NSTableViewDelegate

@end
