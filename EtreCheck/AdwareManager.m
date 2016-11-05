/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2016. All rights reserved.
 **********************************************************************/

#import "AdwareManager.h"
#import "Model.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"
#import "TTTLocalizedPluralString.h"
#import "LaunchdCollector.h"

@interface UninstallManager ()

// Show the window with content.
- (void) show: (NSString *) content;

// Verify removal of files.
- (void) verifyRemoveFiles: (NSMutableArray *) files;

// Tell the user that EtreCheck is too old.
- (BOOL) reportOldEtreCheckVersion;

// Tell the user that the EtreCheck version is unverified.
- (BOOL) reportUnverifiedEtreCheckVersion;

@end

@implementation AdwareManager

// Can I remove files?
// Override the base behaviour to allow the button to be enabled. Then,
// do the super's canRemoveFiles check only if the user clicks the button.
- (BOOL) canRemoveFiles
  {
  return [self.filesToRemove count] > 0;
    return NO;
  }

// Show the window.
- (void) show
  {
  [super show: NSLocalizedString(@"adware", NULL)];
  
  self.filesRemoved = NO;
  
  [self willChangeValueForKey: @"canRemoveFiles"];
  
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
        
        [item release];
        }
      }
    }
    
  NSArray * adwareFiles =
    [[filesToRemove allKeys] sortedArrayUsingSelector: @selector(compare:)];
  
  for(NSString * adwareFile in adwareFiles)
    {
    NSMutableDictionary * item = [filesToRemove objectForKey: adwareFile];
    
    if(item)
      [self.filesToRemove addObject: item];
    }
    
  [filesToRemove release];
  
  [self.tableView reloadData];
  
  [self didChangeValueForKey: @"canRemoveFiles"];
  }

// Remove the files.
- (IBAction) removeFiles: (id) sender
  {
  if([super canRemoveFiles])
    {
    [self willChangeValueForKey: @"canRemoveFiles"];
  
    [super removeFiles: sender];
    
    [self.tableView reloadData];

    [self didChangeValueForKey: @"canRemoveFiles"];
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

#pragma mark - NSTableViewDataSource

- (NSInteger) numberOfRowsInTableView: (NSTableView *) aTableView
  {
  return self.filesToRemove.count;
  }

- (id) tableView: (NSTableView *) aTableView
  objectValueForTableColumn: (NSTableColumn *) aTableColumn
  row: (NSInteger) rowIndex
  {
  if(rowIndex < self.filesToRemove.count)
    {
    NSDictionary * item = [self.filesToRemove objectAtIndex: rowIndex];
  
    return [item objectForKey: kPath];
    }
    
  return nil;
  }

@end
