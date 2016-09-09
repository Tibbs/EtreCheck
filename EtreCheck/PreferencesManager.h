//
//  PreferencesManager.h
//  EtreCheck
//
//  Created by Kian Lim on 9/9/16.
//  Copyright © 2016 Etresoft. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PreferencesManager : NSObject <NSWindowDelegate> {
	NSWindow *myWindow;
	NSPopUpButton *myPopUpButton;
}

// The window itself.
@property (retain) IBOutlet NSWindow *window;

// The pop-up button.
@property (retain) IBOutlet NSPopUpButton *popUpButton;

// Show the window.
- (void) show;

@end
