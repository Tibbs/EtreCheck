/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2016. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>
#import "PopoverManager.h"

@interface SMARTManager : PopoverManager
  {
  NSProgressIndicator * mySpinner;
  }

@property (retain) IBOutlet NSProgressIndicator * spinner;

@end
