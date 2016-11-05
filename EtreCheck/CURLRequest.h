/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2015. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

typedef void CURL;

@class CURLRequest;

typedef void (^CompletionCallback)(CURLRequest * curlRequest, BOOL success);

@interface CURLRequest : NSObject
  {
  CompletionCallback myCompletionCallback;
  CURL * myCURL;
  NSString * myURL;
  NSDictionary * myHeaders;
  NSDictionary * myParameters;
  NSData * myData;
  int myStatusCode;
  NSData * myResponse;
  NSMutableData * myPendingResponse;
  }

@property (copy) CompletionCallback completionCallback;
@property (readonly) CURL * cURL;
@property (retain) NSString * url;
@property (retain) NSDictionary * headers;
@property (retain) NSDictionary * parameters;
@property (copy) NSData * data;
@property (assign) NSString * content;
@property (readonly) int statusCode;
@property (readonly) NSData * response;
@property (readonly) NSString * responseString;

// Constructor with URL (which could be either an NSString or NSURL).
- (instancetype) init: (id) url;

// Constructor with URL (which could be either an NSString or NSURL) and
// completion callback.
- (instancetype) init: (id) url callback: (CompletionCallback) completion;

// Send the request.
- (void) send;

// Send the request with data (which could be either an NSString or NSData).
- (void) send: (id) data;

@end

// A HEAD request.
@interface HEAD : CURLRequest

@end

// A GET request.
@interface GET : CURLRequest

@end

// A PUT request.
@interface PUT : CURLRequest

@end

// A POST request.
@interface POST : CURLRequest

@end

// A DELETE request.
@interface DELETE : CURLRequest

@end

// An OPTIONS request.
@interface OPTIONS : CURLRequest

@end

