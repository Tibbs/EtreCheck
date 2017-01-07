/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

// Try to extract events from log files and various types of system reports.
typedef enum EventType
  {
  kUnknown,
  kCrash,
  kCPU,
  kHang,
  kSelfTestPass,
  kSelfTestFail,
  kPanic,
  kASLLog,
  kSystemLog,
  kLog
  }
EventType;

@interface DiagnosticEvent : NSObject
  {
  EventType myType;
  NSString * myName;
  NSDate * myDate;
  NSString * myFile;
  NSString * myDetails;
  NSString * myPath;
  NSString * myIdentifier;
  NSString * myInformation;
  }

@property (assign) EventType type;
@property (strong) NSString * name;
@property (strong) NSDate * date;
@property (strong) NSString * file;
@property (strong) NSString * details;
@property (strong) NSString * path;
@property (strong) NSString * identifier;
@property (strong) NSString * information;

@end
