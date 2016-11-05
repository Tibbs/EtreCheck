//
//  PopoverSampleAppAppDelegate.h
//  Copyright 2011-2014 Indragie Karunaratne. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class INPopover;
@interface PopoverSampleAppAppDelegate : NSObject <NSApplicationDelegate> {
@private
    NSWindow *__weak window;
    INPopover *popover;
}
@property (nonatomic, strong) INPopover *popover;
@property (weak) IBOutlet NSWindow *window;
- (IBAction)togglePopover:(id)sender;
@end
