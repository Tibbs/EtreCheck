/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

// A callback for section progress.
typedef void (^SectionCallback)(NSString * sectionName);

// A callback for overall progress.
typedef void (^ProgressCallback)(double progress);

// A callback for an app inspection.
typedef void (^ApplicationIconCallback)(NSImage * icon);

// Perform the check.
@interface Checker : NSObject
  {
  NSMutableDictionary * myResults;
  NSMutableDictionary * myCompleted;
  
  SectionCallback myStartSection;
  SectionCallback myCompleteSection;
  ProgressCallback myProgress;
  ApplicationIconCallback myApplicationIcon;
  dispatch_block_t myComplete;
  
  double myCurrentProgress;
  }

@property (retain) NSMutableDictionary * results;
@property (retain) NSMutableDictionary * completed;

// The section start callback.
@property (copy) SectionCallback startSection;

// The section complete callback.
@property (copy) SectionCallback completeSection;

// The progress callback.
@property (copy) ProgressCallback progress;

// The application icon callback.
@property (copy) ApplicationIconCallback applicationIcon;

// The completion callback.
@property (copy) dispatch_block_t complete;

// The current progress.
@property (assign) double currentProgress;

// Do the check and return the report.
- (NSAttributedString *) check;

// Collect output.
- (void) collectOutput;

@end
