/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2012-2014. All rights reserved.
 **********************************************************************/

#import "EtreCheckWindow.h"

@implementation EtreCheckWindow

@synthesize status = myStatus;

- (void) saveFrameUsingName: (NSString *) name
  {
  switch(self.status)
    {
    case kSetup:
    case kIntroduction:
    case kRunning:
      [super saveFrameUsingName: name];
      break;
    case kReportTransition:
      break;
    case kReport:
      {
      NSRect frame = self.frame;
      
      frame.origin.y += (kHeightOffset * 2);
      frame.size.height -= (kHeightOffset * 2);
      
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
