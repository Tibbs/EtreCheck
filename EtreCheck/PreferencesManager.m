/***********************************************************************
 ** Etresoft
 ** Created by Kian Lim on 9/9/16.
 ** Copyright (c) 2016. All rights reserved.
 **********************************************************************/

#import "PreferencesManager.h"
#import "SearchEngine.h"

@implementation PreferencesManager

@synthesize window = myWindow;
@synthesize popUpButton = myPopUpButton;

// Show the window.
- (IBAction) show: (id) sender
  {
	[self.popUpButton selectItemAtIndex: [SearchEngine currentSearchEngine]];

  [self.window makeKeyAndOrderFront: sender];
  }

// Close the window.
- (void) windowWillClose: (NSNotification *) notification
  {
	//[[NSApplication sharedApplication] stopModal];
  }

- (IBAction) valueChanged: (id) sender
  {
	NSPopUpButton * popUpButton = (NSPopUpButton *)sender;
	
  SearchEngineType searchEngineType =
    (SearchEngineType)popUpButton.indexOfSelectedItem;
    
	[SearchEngine setSearchEngineType: searchEngineType];
  }

@end
