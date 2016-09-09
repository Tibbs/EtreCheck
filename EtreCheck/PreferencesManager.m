
//  PreferencesManager.m
//  EtreCheck
//
//  Created by Kian Lim on 9/9/16.
//  Copyright © 2016 Etresoft. All rights reserved.
//

#import "PreferencesManager.h"
#import "SearchEngine.h"

@implementation PreferencesManager

@synthesize window = myWindow;
@synthesize popUpButton = myPopUpButton;

// Show the window.
- (void)show {
	[self.popUpButton selectItemAtIndex:[SearchEngine currentSearchEngine]];
	[[NSApplication sharedApplication] runModalForWindow:self.window];
}

// Close the window.
- (void)windowWillClose:(NSNotification *)notification {
	[[NSApplication sharedApplication] stopModal];
}


- (IBAction)valueChanged:(id)sender {
	NSPopUpButton *popUpButton = (NSPopUpButton *)sender;
	SearchEngineType searchEngineType = (SearchEngineType)popUpButton.indexOfSelectedItem;
	[SearchEngine setSearchEngineType:searchEngineType];
}

@end
