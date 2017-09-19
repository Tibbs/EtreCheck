/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2015. All rights reserved.
 **********************************************************************/

#import "CURLRequest.h"
#import <curl/curl.h>

static size_t callback(
  void * contents, size_t size, size_t nmemb, void * context);

@interface CURLException : NSException

@end

CURLException * NewCURLException(
  const char * file, int line, NSString * description, CURLcode error);

@implementation CURLRequest

@synthesize completionCallback = myCompletionCallback;
@synthesize cURL = myCURL;
@synthesize url = myURL;
@synthesize headers = myHeaders;
@synthesize parameters = myParameters;
@synthesize data = myData;
@dynamic content;
@synthesize statusCode = myStatusCode;
@synthesize response = myResponse;
@dynamic responseString;

// Return a parameters string.
+ (NSString *) joinParameters: (NSDictionary *) parameters
  {
  NSMutableString * content = [NSMutableString string];
  
  if([parameters count] > 0)
    {
    for(NSString * key in parameters)
      {
      if([content length] > 0)
        [content appendString: @"&"];
        
      [content
        appendFormat:
          @"%@=%@",
          [CURLRequest urlEscape: key],
          [CURLRequest urlEscape: [parameters objectForKey: key]]];
      }
    }
    
  return [[content copy] autorelease];
  }

// Escape a path for returning to the Finder over HTTP.
+ (NSString *) urlEscape: (NSString *) string
  {
  NSString * unicode = [string decomposedStringWithCanonicalMapping];

  NSString * escaped =
    [unicode
      stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];

  // Move the characters into a buffer.
  unichar * characters = malloc(sizeof(unichar) * (escaped.length + 1));
  
  [escaped
    getCharacters: characters range: NSMakeRange(0, escaped.length)];

  // Create a buffer to hold the output.
  unichar * escapedCharacters =
    malloc(sizeof(unichar) * escaped.length * 3);

  int size = 0;

  // Go through each character.
  for(int i = 0; i < escaped.length; ++i)
    switch(characters[i])
      {
      case '$':
        escapedCharacters[size++] = '%';
        escapedCharacters[size++] = '2';
        escapedCharacters[size++] = '4';
        break;
      case '&':
        escapedCharacters[size++] = '%';
        escapedCharacters[size++] = '2';
        escapedCharacters[size++] = '6';
        break;
      case '+':
        escapedCharacters[size++] = '%';
        escapedCharacters[size++] = '2';
        escapedCharacters[size++] = 'B';
        break;
      case ',':
        escapedCharacters[size++] = '%';
        escapedCharacters[size++] = '2';
        escapedCharacters[size++] = 'C';
        break;
      case '/':
        escapedCharacters[size++] = '%';
        escapedCharacters[size++] = '2';
        escapedCharacters[size++] = 'F';
        break;
      case ':':
        escapedCharacters[size++] = '%';
        escapedCharacters[size++] = '3';
        escapedCharacters[size++] = 'A';
        break;
      case ';':
        escapedCharacters[size++] = '%';
        escapedCharacters[size++] = '3';
        escapedCharacters[size++] = 'B';
        break;
      case '=':
        escapedCharacters[size++] = '%';
        escapedCharacters[size++] = '3';
        escapedCharacters[size++] = 'D';
        break;
      case '?':
        escapedCharacters[size++] = '%';
        escapedCharacters[size++] = '3';
        escapedCharacters[size++] = 'F';
        break;
      case '@':
        escapedCharacters[size++] = '%';
        escapedCharacters[size++] = '4';
        escapedCharacters[size++] = '0';
        break;
      case ' ':
        escapedCharacters[size++] = '%';
        escapedCharacters[size++] = '2';
        escapedCharacters[size++] = '0';
        break;
      case '#':
        escapedCharacters[size++] = '%';
        escapedCharacters[size++] = '2';
        escapedCharacters[size++] = '3';
        break;
      case '<':
        escapedCharacters[size++] = '%';
        escapedCharacters[size++] = '3';
        escapedCharacters[size++] = 'C';
        break;
      case '>':
        escapedCharacters[size++] = '%';
        escapedCharacters[size++] = '3';
        escapedCharacters[size++] = 'E';
        break;
      case '\"':
        escapedCharacters[size++] = '%';
        escapedCharacters[size++] = '2';
        escapedCharacters[size++] = '2';
        break;
      case 13:
        escapedCharacters[size++] = '%';
        escapedCharacters[size++] = '0';
        escapedCharacters[size++] = 'D';
        break;
      case 10:
        escapedCharacters[size++] = '%';
        escapedCharacters[size++] = '0';
        escapedCharacters[size++] = 'A';
        break;
      case 9:
        escapedCharacters[size++] = '%';
        escapedCharacters[size++] = '0';
        escapedCharacters[size++] = '9';
        break;
      default:
        escapedCharacters[size++] = characters[i];
        break;
      }

  NSString * reallyEscaped =
    [NSString stringWithCharacters: escapedCharacters length: size];

  free(escapedCharacters);
  free(characters);

  return reallyEscaped;
  }

// Set the URL from either a string or URL.
- (void) setURL: (id) url
  {
  if([url respondsToSelector: @selector(UTF8String)])
    self.url = url;
    
  else if([url respondsToSelector: @selector(isFileReferenceURL)])
    self.url = [(NSURL *)url absoluteString];
  }

// Set the URL from either a string or URL.
- (void) setURL: (id) url parameters: (NSDictionary *) parameters
  {
  [self setURL: url];
  
  NSString * query = [CURLRequest joinParameters: parameters];
  
  if([query length] > 0)
    self.url = [url stringByAppendingFormat: @"?%@", query];
  }

- (void) setContent: (NSString *) content
  {
  [myData release];
  
  myData = [[content dataUsingEncoding: NSUTF8StringEncoding] copy];
  }

- (NSData *) response
  {
  if(!myResponse)
    {
    myResponse = [myPendingResponse copy];
    
    [myPendingResponse release];
    
    myPendingResponse = nil;
    }
    
  return myResponse;
  }

- (NSString *) responseString
  {
  NSString * string =
    [[NSString alloc]
      initWithData: self.response encoding: NSUTF8StringEncoding];
    
  return [string autorelease];
  }

// Constructor with URL (which could be either an NSString or NSURL).
- (instancetype) init: (id) url
  {
  self = [super init];
  
  if(self)
    {
    if([self setup])
      {
      [self setURL: url];
      
      return self;
      }
    }
    
  return nil;
  }

// Constructor with URL (which could be either an NSString or NSURL) and
// completion callback.
- (instancetype) init: (id) url callback: (CompletionCallback) completion
  {
  self = [super init];
  
  if(self)
    {
    if([self setup])
      {
      [self setURL: url];
      
      self.completionCallback = completion;
      
      return self;
      }
    }
    
  return nil;
  }

// Setup.
- (BOOL) setup
  {
  static dispatch_once_t onceToken;
  
  __block int error = 0;
  
  dispatch_once(
    & onceToken,
    ^{
      error = curl_global_init(CURL_GLOBAL_ALL);
    });
    
  if(!error)
    {
    myCURL = curl_easy_init();

    if(myCURL)
      {
      NSBundle * bundle = [NSBundle mainBundle];
  
      NSString * userAgent =
        [NSString
          stringWithFormat:
           @"EtreCheck/%@",
          [bundle
            objectForInfoDictionaryKey: @"CFBundleShortVersionString"]];
        
      error =
        curl_easy_setopt(myCURL, CURLOPT_USERAGENT, [userAgent UTF8String]);
      
      if(error != CURLE_OK)
        return NO;
        
      //error = curl_easy_setopt(myCURL, CURLOPT_VERBOSE, 1L);
      
      //if(error != CURLE_OK)
      //  return NO;
        
      myPendingResponse = [NSMutableData new];
      
      return YES;
      }
    }
    
  return NO;
  }

// Destructor.
- (void) dealloc
  {
  if(myCURL)
    curl_easy_cleanup(myCURL);

  [myPendingResponse release];
  [myData release];
  [myHeaders release];
  [myParameters release];
  [myCompletionCallback release];
  [myURL release];
  
  [super dealloc];  
  }

// Send a request.
- (void) send
  {
  // I guess everything has to go through a proxy loop.
  
  // First test each proxy.
  NSDictionary * proxySettings =
    (NSDictionary *)CFBridgingRelease(CFNetworkCopySystemProxySettings());
  
  NSArray * proxies =
    (NSArray *)CFBridgingRelease(CFNetworkCopyProxiesForURL(
      (__bridge CFURLRef)[NSURL URLWithString: self.url],
      (__bridge CFDictionaryRef)proxySettings));
    
  CURLcode error = 0;
  BOOL success = NO;
  
  if([proxies count])
    {
    for(NSDictionary * proxy in proxies)
      {
      [self clearProxy];
      
      if([self setupProxy: proxy])
        {
        error = [self sendRequest];
        
        if(!error)
          {
          success = YES;
          
          break;
          }
        }
      }
    
    // One way or another, I'm done now.
    [self clearProxy];
    }
    
  if(!success)
    {
    error = [self sendRequest];
  
    if(!error)
      success = YES;
    }
    
  if(self.completionCallback != nil)
    self.completionCallback(self, success);
  }

// Send a request with data.
- (void) send: (id) data
  {
  if([data respondsToSelector: @selector(getBytes:)])
    self.data = data;
    
  else if([data respondsToSelector: @selector(UTF8String)])
    self.data = [(NSString *)data dataUsingEncoding: NSUTF8StringEncoding];
    
  [self send];
  }

// Setup a proxy connection.
- (BOOL) setupProxy: (NSDictionary *) proxy
  {
  @try
    {
    CURLcode error = CURLE_OK;
    
    NSString * type = proxy[(NSString *)kCFProxyTypeKey];

    if([type isEqualToString: (NSString *)kCFProxyTypeNone])
      {
      [self clearProxy];
      
      return NO;
      }
    else if([type isEqualToString: (NSString *)kCFProxyTypeHTTP])
      {
      error = curl_easy_setopt(myCURL, CURLOPT_HTTPPROXYTUNNEL, 1);
      
      if(error != CURLE_OK)
        @throw
          NewCURLException(
            __FILE__, __LINE__, @"CURLOPT_HTTPPROXYTUNNEL", error);
        
      error = curl_easy_setopt(myCURL, CURLOPT_PROXYTYPE, CURLPROXY_HTTP);

      if(error != CURLE_OK)
        @throw
          NewCURLException(
            __FILE__, __LINE__, @"CURLOPT_PROXYTYPE", error);
      }
    else if([type isEqualToString: (NSString *)kCFProxyTypeHTTPS])
      {
      error = curl_easy_setopt(myCURL, CURLOPT_HTTPPROXYTUNNEL, 1);

      if(error != CURLE_OK)
        @throw
          NewCURLException(
            __FILE__, __LINE__, @"CURLOPT_HTTPPROXYTUNNEL", error);
        
      error = curl_easy_setopt(myCURL, CURLOPT_PROXYTYPE, CURLPROXY_HTTP);

      if(error != CURLE_OK)
        @throw
          NewCURLException(
            __FILE__, __LINE__, @"CURLOPT_PROXYTYPE", error);
      }
    else if([type isEqualToString: (NSString *)kCFProxyTypeSOCKS])
      {
      error = curl_easy_setopt(myCURL, CURLOPT_HTTPPROXYTUNNEL, 0);

      if(error != CURLE_OK)
        @throw
          NewCURLException(
            __FILE__, __LINE__, @"CURLOPT_HTTPPROXYTUNNEL", error);

      error = curl_easy_setopt(myCURL, CURLOPT_PROXYTYPE, CURLPROXY_SOCKS5);

      if(error != CURLE_OK)
        @throw
          NewCURLException(
            __FILE__, __LINE__, @"CURLOPT_PROXYTYPE", error);
      }
      
    NSString * proxyUsername = proxy[(NSString *)kCFProxyUsernameKey];
    NSString * proxyPassword = proxy[(NSString *)kCFProxyPasswordKey];
    NSString * proxyHostname = proxy[(NSString *)kCFProxyHostNameKey];
    NSNumber * proxyPortValue = proxy[(NSString *)kCFProxyPortNumberKey];
    
    if(proxyUsername)
      error =
        curl_easy_setopt(
          myCURL, CURLOPT_PROXYUSERNAME, [proxyUsername UTF8String]);
    else
      error = curl_easy_setopt(myCURL, CURLOPT_PROXYUSERNAME, NULL);
      
    if(error != CURLE_OK)
      @throw
        NewCURLException(
          __FILE__, __LINE__, @"CURLOPT_PROXYUSERNAME", error);

    if(proxyPassword)
      error =
        curl_easy_setopt(
          myCURL, CURLOPT_PROXYPASSWORD, [proxyPassword UTF8String]);
    else
      error = curl_easy_setopt(myCURL, CURLOPT_PROXYPASSWORD, NULL);
    
    if(error != CURLE_OK)
      @throw
        NewCURLException(
          __FILE__, __LINE__, @"CURLOPT_PROXYPASSWORD", error);

    if(proxyHostname)
      error =
        curl_easy_setopt(myCURL, CURLOPT_PROXY, [proxyHostname UTF8String]);
    else
      error = curl_easy_setopt(myCURL, CURLOPT_PROXY, NULL);

    if(error != CURLE_OK)
      @throw
        NewCURLException(
          __FILE__, __LINE__, @"CURLOPT_PROXY", error);

    if(proxyPortValue)
      error = curl_easy_setopt(
        myCURL, CURLOPT_PROXYPORT, [proxyPortValue longValue]);
    
    else
      error = curl_easy_setopt(myCURL, CURLOPT_PROXYPORT, NULL);

    if(error != CURLE_OK)
      @throw
        NewCURLException(
          __FILE__, __LINE__, @"CURLOPT_PROXYPORT", error);
    }
  @catch(CURLException * exception)
    {
    NSLog(@"Failed to setup proxy: %@", exception.description);
    
    return NO;
    }
  @catch(...)
    {
    NSLog(@"Failed to setup proxy: Unknown error");
    
    return NO;
    }
  
  return YES;
  }

// Clear proxy configuration.
- (void) clearProxy
  {
  @try
    {
    CURLcode error = curl_easy_setopt(myCURL, CURLOPT_HTTPPROXYTUNNEL, 0);

    if(error != CURLE_OK)
      @throw
        NewCURLException(
          __FILE__, __LINE__, @"CURLOPT_HTTPPROXYTUNNEL", error);

    error = curl_easy_setopt(myCURL, CURLOPT_PROXYUSERNAME, NULL);
    
    if(error != CURLE_OK)
      @throw
        NewCURLException(
          __FILE__, __LINE__, @"CURLOPT_PROXYUSERNAME", error);

    error = curl_easy_setopt(myCURL, CURLOPT_PROXYPASSWORD, NULL);
    
    if(error != CURLE_OK)
      @throw
        NewCURLException(
          __FILE__, __LINE__, @"CURLOPT_PROXYPASSWORD", error);

    error = curl_easy_setopt(myCURL, CURLOPT_PROXY, NULL);
    
    if(error != CURLE_OK)
      @throw
        NewCURLException(
          __FILE__, __LINE__, @"CURLOPT_PROXY", error);

    error = curl_easy_setopt(myCURL, CURLOPT_PROXYPORT, NULL);
    
    if(error != CURLE_OK)
      @throw
        NewCURLException(
          __FILE__, __LINE__, @"CURLOPT_PROXYPORT", error);
    }
  @catch(CURLException * exception)
    {
    NSLog(@"Failed to setup proxy: %@", exception.description);
    }
  @catch(...)
    {
    NSLog(@"Failed to setup proxy: Unknown error");
    }
  }

// Send a request.
- (void) setupRequest
  {
  }

// Send a request.
- (CURLcode) sendRequest
  {
  // Specify URL to get.
  CURLcode error = CURLE_OK;
  
  struct curl_slist * list = NULL;

  @try
    {
    error = curl_easy_setopt(myCURL, CURLOPT_URL, [self.url UTF8String]);
   
    if(error != CURLE_OK)
      @throw
        NewCURLException(
          __FILE__, __LINE__, @"CURLOPT_URL", error);

    if([self.headers count] > 0)
      {
      for(NSString * key in self.headers)
        {
        NSString * value = [self.headers objectForKey: key];
        
        NSString * header =
          [NSString stringWithFormat: @"%@: %@", key, value];
        
        list = curl_slist_append(list, [header UTF8String]);
        }
        
      error = curl_easy_setopt(myCURL, CURLOPT_HTTPHEADER, list);

      if(error != CURLE_OK)
        @throw
          NewCURLException(
            __FILE__, __LINE__, @"CURLOPT_HTTPHEADER", error);
      }

    [self setupRequest];
    
    // Send all data to this function.
    error = curl_easy_setopt(myCURL, CURLOPT_WRITEFUNCTION, callback);
   
    if(error != CURLE_OK)
      @throw
        NewCURLException(
          __FILE__, __LINE__, @"CURLOPT_WRITEFUNCTION", error);

    void * block =
      (__bridge void *)^size_t (void * buffer, size_t size)
        {
        [myPendingResponse appendBytes: buffer length: size];
        
        return size;
        };
    
    error = curl_easy_setopt(myCURL, CURLOPT_WRITEDATA, block);

    if(error != CURLE_OK)
      @throw
        NewCURLException(
          __FILE__, __LINE__, @"CURLOPT_WRITEDATA", error);

    // Send it!
    error = curl_easy_perform(myCURL);

    if(error != CURLE_OK)
      @throw
        NewCURLException(
          __FILE__, __LINE__, @"perform", error);
    }
  @catch(CURLException * exception)
    {
    NSLog(@"Failed to send request: %@", exception.description);
    }
  @catch(...)
    {
    NSLog(@"Failed to send request: Unknown error");
    }
  @finally
    {
    if(list != NULL)
      curl_slist_free_all(list);
    }
    
  return error;
  }

@end

static size_t callback(
  void * contents, size_t size, size_t nmemb, void * context)
  {
  size_t (^block)(void *, size_t) =
    (__bridge size_t (^)(void *, size_t))context;
  
  size_t result = block(contents, size * nmemb);
  
  return result;
  }

// A HEAD request.
@implementation HEAD : CURLRequest

// Constructor with URL (which could be either an NSString or NSURL).
- (instancetype) init: (id) url
  {
  self = [super init: url];
  
  if(self)
    {
    CURLcode error =
      curl_easy_setopt(self.cURL, CURLOPT_CUSTOMREQUEST, "HEAD");
  
    if(error == CURLE_OK)
      return self;
    }
    
  return nil;
  }

@end

// A GET request.
@implementation GET : CURLRequest

@end

// A PUT request.
@implementation PUT : CURLRequest

// Send a request.
- (void) setupRequest
  {
  [super setupRequest];
  
  // Send all data to this function.
  curl_easy_setopt(self.cURL, CURLOPT_READFUNCTION, callback);

  // Set the length of data.
  curl_easy_setopt(
    self.cURL, CURLOPT_INFILESIZE_LARGE, (curl_off_t)[self.data length]);

  // Setup a block to curl the data.
  __block NSUInteger offset = 0;
  __block NSUInteger remaining = [self.data length];
  __block NSUInteger amountWritten = 0;
  
  void * block =
    (__bridge void *)^size_t (void * buffer, size_t size)
      {
      NSUInteger length = size;
      
      // Don't copy too much data.
      if(length > remaining)
        length = remaining;
      
      // Don't do anything if at end of data.
      if(length)
        {
        // Copy the next chunk of data.
        NSRange range = NSMakeRange(offset, length);
        
        [self.data getBytes: buffer range: range];
        
        offset += length;
        remaining -= length;
        amountWritten += length;
        }
      
      return length;
      };
  
  curl_easy_setopt(self.cURL, CURLOPT_READDATA, block);
  
  // Enable uploading.
  curl_easy_setopt(self.cURL, CURLOPT_UPLOAD, 1L);
  
  curl_easy_setopt(self.cURL, CURLOPT_PUT, 1L);
  }

@end

// A POST request.
@implementation POST : CURLRequest

// Send a request.
- (void) setupRequest
  {
  [super setupRequest];
  
  CURLcode error = CURLE_OK;
  
  if([self.data length] > 0)
    {
    // Set the data.
    error =
      curl_easy_setopt(self.cURL, CURLOPT_POSTFIELDS, [self.data bytes]);

    if(error != CURLE_OK)
      @throw
        NewCURLException(
          __FILE__, __LINE__, @"CURLOPT_POSTFIELDS", error);

    // Set the length of data.
    error =
      curl_easy_setopt(
        self.cURL,
        CURLOPT_POSTFIELDSIZE_LARGE,
        (curl_off_t)[self.data length]);
    
    if(error != CURLE_OK)
      @throw
        NewCURLException(
          __FILE__, __LINE__, @"CURLOPT_POSTFIELDSIZE_LARGE", error);
    }
  else if([self.parameters count] > 0)
    {
    NSString * postFields = [CURLRequest joinParameters: self.parameters];
  
    error =
      curl_easy_setopt(
        self.cURL, CURLOPT_POSTFIELDS, [postFields UTF8String]);

    if(error != CURLE_OK)
      @throw
        NewCURLException(
          __FILE__, __LINE__, @"CURLOPT_POSTFIELDS", error);

    error =
      curl_easy_setopt(
        self.cURL,
        CURLOPT_POSTFIELDSIZE_LARGE,
        (curl_off_t)[postFields length]);

    if(error != CURLE_OK)
      @throw
        NewCURLException(
          __FILE__, __LINE__, @"CURLOPT_POSTFIELDSIZE_LARGE", error);
    }
  }

@end

// A DELETE request.
@implementation DELETE : CURLRequest

// Constructor with URL (which could be either an NSString or NSURL).
- (instancetype) init: (id) url
  {
  self = [super init: url];
  
  if(self)
    {
    CURLcode error =
      curl_easy_setopt(self.cURL, CURLOPT_CUSTOMREQUEST, "DELETE");
  
    if(error == CURLE_OK)
      return self;
    }
    
  return nil;
  }

@end

// An OPTIONS request.
@implementation OPTIONS : CURLRequest

// Constructor with URL (which could be either an NSString or NSURL).
- (instancetype) init: (id) url
  {
  self = [super init: url];
  
  if(self)
    {
    CURLcode error =
      curl_easy_setopt(self.cURL, CURLOPT_CUSTOMREQUEST, "OPTIONS");
  
    if(error == CURLE_OK)
      return self;
    }
    
  return nil;
  }

@end

@implementation CURLException

@end

CURLException * NewCURLException(
  const char * file, int line, NSString * description, CURLcode error)
  {
  return
    [[CURLException alloc]
      initWithName: @"CURLException"
      reason:
        [NSString
          stringWithFormat:
            @"CURL failure %s:%d - %@, (%d) %s",
            file,
            line,
            description,
            error,
            curl_easy_strerror(error)]
      userInfo: nil];
  }

