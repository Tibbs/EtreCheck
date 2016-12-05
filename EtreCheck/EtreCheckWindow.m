/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2016. All rights reserved.
 **********************************************************************/

#import "EtreCheckWindow.h"

@implementation EtreCheckWindow

@synthesize status = myStatus;

// Save the window frame as a string.
- (void) saveFrameUsingName: (NSString *) name
  {
  switch(self.status)
    {
    // Normal behaviour.
    case kSetup:
    case kIntroduction:
    case kRunning:
      [super saveFrameUsingName: name];
      break;
      
    // Don't save any transition value.
    case kReportTransition:
      break;
      
    // If the report is complete, hack up the position to adjust for the
    // adjustment of the EtreCheck window.
    case kReport:
      {
      // Adjust the frame to account for the expanding window frame.
      NSRect frame = self.frame;
      
      frame.origin.y += (kHeightOffset * 2);
      frame.size.height -= (kHeightOffset * 2);
      
      // Save the output.
      NSRect screenFrame = [[self screen] frame];
      
      NSString * frameString =
        [NSString
          stringWithFormat:
            @"%d %d %d %d %d %d %d %d",
            (int)frame.origin.x,
            (int)frame.origin.y,
            (int)frame.size.width,
            (int)frame.size.height,
            (int)screenFrame.origin.x,
            (int)screenFrame.origin.y,
            (int)screenFrame.size.width,
            (int)screenFrame.size.height];
      
      [[NSUserDefaults standardUserDefaults]
        setObject: frameString forKey: @"NSWindow Frame EtreCheck"];
      
      break;
      }
    }
  }

@end
