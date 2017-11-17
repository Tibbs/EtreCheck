/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "PrintableItem.h"

@interface NetworkInterface : PrintableItem
  {
  // The interface name.
  NSString * myName;
  
  // The interface code.
  NSString * myInterface;
  
  // IPv4 addresses.
  NSArray * myIPv4Addresses;
  
  // IPv6 addresses.
  NSArray * myIPv6Addresses;
  
  // Proxies. 
  NSArray * myProxies;
  
  // Is proxy auto discovery enabled?
  BOOL myProxyAutoDiscovery;
  
  // Is proxy auto config enabled?
  BOOL myProxyAutoConfig;
  
  // Proxy auto config URL. 
  NSString * myProxyAutoConfigURLString;
  }
  
// The interface name.
@property (strong) NSString * name;

// The interface code.
@property (strong) NSString * interface;

// IPv4 addresses.
@property (strong) NSArray * IPv4Addresses;

// IPv6 addresses.
@property (strong) NSArray * IPv6Addresses;

// Proxies. 
@property (strong) NSArray * proxies;

// Is proxy auto discovery enabled?
@property (assign) BOOL proxyAutoDiscovery;

// Is proxy auto config enabled?
@property (assign) BOOL proxyAutoConfig;

// Proxy auto config URL. 
@property (strong) NSString * proxyAutoConfigURLString;

// Constructor with property list dictionary.
+ (instancetype) NetworkInterfaceWithPropertyListDictionary: 
  (NSDictionary *) plist;

@end
