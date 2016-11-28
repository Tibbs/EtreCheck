/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2012-2014. All rights reserved.
 **********************************************************************/

#import <Cocoa/Cocoa.h>

#define kHeightOffset 128

typedef enum EtreCheckStatus
  {
  kSetup,
  kIntroduction,
  kRunning,
  kReportTransition,
  kReport
  }
EtreCheckStatus;

@interface EtreCheckWindow : NSWindow
  {
  EtreCheckStatus myStatus;
  }

@property (assign) EtreCheckStatus status;

@end
