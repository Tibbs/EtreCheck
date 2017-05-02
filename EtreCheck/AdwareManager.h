/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2016-2017. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>
#import "UninstallManager.h"

@interface AdwareManager : UninstallManager
  <NSTableViewDelegate, NSTableViewDataSource>
  {
  NSAttributedString * myWhitelistDescription;
  NSButton * myRemoveButton;
  NSButton * myReportButton;
  BOOL myFoundUnknownLegitimateFiles;
  BOOL myRemovingUnknownFiles;
  }

// User's whitelist description.
@property (retain) NSAttributedString * whitelistDescription;

// The remove button.
@property (retain) IBOutlet NSButton * removeButton;

// Can the report button be clicked?
@property (readonly) BOOL canReportFiles;

// The report button.
@property (retain) IBOutlet NSButton * reportButton;

// Did I find unknown files that are likely legitimate?
@property (assign) BOOL foundUnknownLegitimateFiles;

// Is the user removing unknown files?
@property (assign) BOOL removingUnknownFiles;

@end
