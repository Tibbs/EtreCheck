/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "NetworkProxy.h"
#import "XMLBuilder.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "NSDictionary+Etresoft.h"
#import "NSString+Etresoft.h"

@implementation NetworkProxy

// The proxy type.
@synthesize type = myType;

// The proxy address.
@synthesize address = myAddress;

// The proxy port.
@synthesize port = myPort;

// The proxy user.
@synthesize user = myUser;

// Factory method with property list dictionary.
+ (NSArray *) NetworkProxiesWithPropertyListDictionary: 
  (NSDictionary *) plist
  {
  if(![NSDictionary isValid: plist])
    return nil;
    
  NSMutableArray * proxies = [NSMutableArray array];
  
  NSArray * types = 
    [[NSArray alloc] 
      initWithObjects: 
        @"HTTP", @"HTTPS", @"RTSP", @"SOCKS", @"FTP", @"Gopher", nil];
        
  for(NSString * type in types)
    {
    NSString * enabledKey = [type stringByAppendingString: @"Enable"];
    NSString * proxyKey = [type stringByAppendingString: @"Proxy"];
    NSString * portKey = [type stringByAppendingString: @"Port"];
    NSString * userKey = [type stringByAppendingString: @"User"];
    
    NSString * enabled = [plist objectForKey: enabledKey];
    
    if([NSString isValid: enabled])
      if([enabled isEqualToString: @"yes"])
        {
        NetworkProxy * proxy = [NetworkProxy new];
        
        proxy.type = type;
        proxy.address = [plist objectForKey: proxyKey];
        proxy.port = [plist objectForKey: portKey];
        proxy.user = [plist objectForKey: userKey];
        
        [proxies addObject: proxy];
        
        [proxy release];
        }
    }
    
  [types release];
  
  if(proxies.count > 0)
    return proxies;
  
  return nil;
  }
  
// Destructor.
- (void) dealloc
  {
  self.type = nil;
  self.address = nil;
  self.port = nil;
  self.user = nil;
  
  [super dealloc];
  }
  
// Build the XML value.
- (void) buildXMLValue: (XMLBuilder *) xml
  {
  [xml startElement: @"proxy"];
    
  [xml addElement: @"type" value: self.type];
  [xml addElement: @"address" value: self.address];
  [xml addElement: @"port" number: self.port];
  [xml addElement: @"user" value: self.user];
  
  [xml endElement: @"proxy"];
  }

@end
