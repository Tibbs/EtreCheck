/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "PrintableItem.h"

@interface NetworkProxy : PrintableItem
  {
  // The proxy type.
  NSString * myType;
  
  // The proxy address.
  NSString * myAddress;
  
  // The proxy port.
  NSNumber * myPort;
  
  // The proxy user.
  NSString * myUser;
  }
  
// The proxy type.
@property (strong) NSString * type;

// The proxy address.
@property (strong) NSString * address;

// The proxy port.
@property (strong) NSNumber * port;

// The proxy user.
@property (strong) NSString * user;

// Constructor with property list dictionary.
+ (NSArray *) NetworkProxiesWithPropertyListDictionary: 
  (NSDictionary *) plist;

@end
