/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

// Try to extract events from log files and various types of system reports.
typedef enum EventType
  {
  kUnknown = 0,
  kCrash,
  kCPU,
  kHang,
  kSelfTestPass,
  kSelfTestFail,
  kPanic,
  kASLLog,
  kSystemLog,
  kLog,
  kShutdown
  }
EventType;

@interface DiagnosticEvent : NSObject
  {
  EventType myType;
  NSString * myName;
  NSString * mySafeFile;
  NSDate * myDate;
  NSString * myFile;
  NSString * myDetails;
  NSString * myPath;
  NSString * myIdentifier;
  NSString * myInformation;
  int myCode;
  int myCount;
  }

@property (assign) EventType type;
@property (strong) NSString * name;
@property (strong) NSDate * date;
@property (strong) NSString * file;
@property (strong) NSString * safefile;
@property (strong) NSString * details;
@property (strong) NSString * path;
@property (strong) NSString * identifier;
@property (strong) NSString * information;
@property (assign) int code;
@property (assign) int count;

@end
