/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>
#import "Model.h"

// A callback for section progress.
typedef void (^SectionCallback)(NSString * sectionName);

// A callback for overall progress.
typedef void (^ProgressCallback)(double progress);

// Perform the check.
@interface Checker : NSObject
  {
  NSMutableDictionary * myResults;
  NSMutableDictionary * myCompleted;
  
  SectionCallback myStartSection;
  SectionCallback myCompleteSection;
  ProgressCallback myProgress;
  dispatch_block_t myComplete;
  
  double myCurrentProgress;
  
  Model * myModel;
  }

@property (retain) NSMutableDictionary * results;
@property (retain) NSMutableDictionary * completed;

// The section start callback.
@property (copy) SectionCallback startSection;

// The section complete callback.
@property (copy) SectionCallback completeSection;

// The progress callback.
@property (copy) ProgressCallback progress;

// The completion callback.
@property (copy) dispatch_block_t complete;

// The current progress.
@property (assign) double currentProgress;

// The model for this run.
@property (retain) Model * model;

// Do the check and return the report.
- (NSAttributedString *) check;

// Collect output.
- (void) collectOutput;

// Save debug information.
- (NSString *) saveDebugInformation;

@end
