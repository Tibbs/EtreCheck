/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "NetworkInterface.h"
#import "NetworkProxy.h"
#import "XMLBuilder.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "LocalizedString.h"

@implementation NetworkInterface

// The interface name.
@synthesize name = myName;

// The interface code.
@synthesize interface = myInterface;

// IPv4 addresses.
@synthesize IPv4Addresses = myIPv4Addresses;

// IPv6 addresses.
@synthesize IPv6Addresses = myIPv6Addresses;

// Proxies. 
@synthesize proxies = myProxies;

// Is proxy auto discovery enabled?
@synthesize proxyAutoDiscovery = myProxyAutoDiscovery;

// Is proxy auto config enabled?
@synthesize proxyAutoConfig = myProxyAutoConfig;

// Proxy auto config URL. 
@synthesize proxyAutoConfigURLString = myProxyAutoConfigURLString;

// Constructor with property list dictionary.
+ (instancetype) NetworkInterfaceWithPropertyListDictionary: 
  (NSDictionary *) plist
  {
  NetworkInterface * interface = [NetworkInterface new];
  
  interface.name = [plist objectForKey: @"_name"];
  interface.interface = [plist objectForKey: @"interface"];
  
  interface.IPv4Addresses = 
    [[plist objectForKey: @"IPv4"] objectForKey: @"Addresses"];
  interface.IPv6Addresses = 
    [[plist objectForKey: @"IPv6"] objectForKey: @"Addresses"];
  
  NSDictionary * proxies = [plist objectForKey: @"Proxies"];
  
  interface.proxyAutoDiscovery = 
    [[proxies objectForKey: @"ProxyAutoDiscoveryEnable"] 
      isEqualToString: @"yes"];
      
  interface.proxyAutoConfig = 
    [[proxies objectForKey: @"ProxyAutoConfigEnable"] 
      isEqualToString: @"yes"];

  interface.proxyAutoConfigURLString = 
    [proxies objectForKey: @"ProxyAutoConfigURLString"];

  interface.proxies = 
    [NetworkProxy NetworkProxiesWithPropertyListDictionary: proxies];
  
  if((interface.name.length > 0) && (interface.interface.length > 0))
    return [interface autorelease];
    
  [interface release];
  
  return nil;
  }
  
// Destructor.
- (void) dealloc
  {
  self.name = nil;
  self.interface = nil;
  self.IPv4Addresses = nil;
  self.IPv6Addresses = nil;
  self.proxies = nil;
  self.proxyAutoConfigURLString = nil;
  
  [super dealloc];
  }
  
// Build the attributedString value.
- (void) buildAttributedStringValue: 
  (NSMutableAttributedString *) attributedString
  {
  [attributedString
    appendString: 
      [NSString 
        stringWithFormat: 
          ECLocalizedString(@"    Interface %@: %@\n"), 
          self.interface, 
          self.name]];

  if(self.IPv4Addresses.count > 0)
    [attributedString
      appendString: 
        [NSString 
          stringWithFormat: 
            ECLocalizedString(@"        %@\n"), 
            ECLocalizedPluralString(
              self.IPv4Addresses.count, @"IPv4 address")]];
    
  if(self.IPv6Addresses.count > 0)
    [attributedString
      appendString: 
        [NSString 
          stringWithFormat: 
            ECLocalizedString(@"        %@\n"), 
            ECLocalizedPluralString(
              self.IPv6Addresses.count, @"IPv6 address")]];
              
  if(self.proxyAutoDiscovery)
    [attributedString appendString:@"        Proxy Auto Discovery\n"];
    
  if(self.proxyAutoDiscovery)
    [attributedString appendString:@"        Proxy Auto Config\n"];
    
  NSMutableArray * proxyTypes = [NSMutableArray new];
  
  for(NetworkProxy * proxy in self.proxies)
    [proxyTypes addObject: proxy.type];
    
  NSString * proxies = [proxyTypes componentsJoinedByString: @", "];
  
  [proxyTypes release];
  
  if(proxies.length > 0)
    [attributedString
      appendString: 
        [NSString 
          stringWithFormat: 
            ECLocalizedString(@"        Proxies: %@\n"), proxies]];
  }
  
// Build the XML value.
- (void) buildXMLValue: (XMLBuilder *) xml
  {
  [xml startElement: @"networkinterface"];
    
  [xml addElement: @"name" value: self.name];
  [xml addElement: @"interface" value: self.interface];
  
  if(self.IPv4Addresses.count > 0)
    {
    [xml startElement: @"ipv4addresses"];
      
    for(NSString * address in self.IPv4Addresses)
      [xml addElement: @"address" value: address];
      
    [xml endElement: @"ipv4addresses"];
    }
    
  if(self.IPv6Addresses.count > 0)
    {
    [xml startElement: @"ipv6addresses"];
      
    for(NSString * address in self.IPv6Addresses)
      [xml addElement: @"address" value: address];
      
    [xml endElement: @"ipv6addresses"];
    }

  [xml addArray: @"proxies" values: self.proxies];

  [xml 
    addElement: @"proxyautodiscovery" boolValue: self.proxyAutoDiscovery];

  [xml addElement: @"proxyautoconfig" boolValue: self.proxyAutoConfig];
  
  [xml 
    addElement: @"proxyautoconfigurl" value: self.proxyAutoConfigURLString];
  
  [xml endElement: @"networkinterface"];
  }

@end
