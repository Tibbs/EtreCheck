/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2016. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>
#import "UninstallManager.h"

@interface UnknownFilesManager : UninstallManager
  <NSTableViewDelegate, NSTableViewDataSource>
  {
  NSAttributedString * myWhitelistDescription;
  NSButton * myRemoveButton;
  NSButton * myReportButton;
  }

// User's whitelist description.
@property (retain) NSAttributedString * whitelistDescription;

// The remove button.
@property (retain) IBOutlet NSButton * removeButton;

// Can the report button be clicked?
@property (readonly) BOOL canReportFiles;

// The report button.
@property (retain) IBOutlet NSButton * reportButton;

@end
