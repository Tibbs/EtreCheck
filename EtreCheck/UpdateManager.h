/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2016. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

@interface UpdateManager : NSObject
  {
  NSWindow * myWindow;
  NSTextView * myTextView;
  NSString * myContent;
  NSURL * myUpdateURL;
  }

// The window itself.
@property (retain) IBOutlet NSWindow * window;

// The text view.
@property (retain) IBOutlet NSTextView * textView;

// The update content.
@property (retain) NSString * content;

// The update URL.
@property (retain) NSURL * updateURL;

// Show the window.
- (void) show;

// Quit and go to update.
- (IBAction) quitAndUpdate: (id) sender;

// Continue without update.
- (IBAction) continueWithoutUpdate: (id) sender;

@end
