/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "LoginItemsCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"
#import "SubProcess.h"

// Collect login items.
@implementation LoginItemsCollector

@synthesize loginItems = myLoginItems;

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    self.name = @"loginitems";
    self.title = NSLocalizedStringFromTable(self.name, @"Collectors", NULL);
    myLoginItems = [NSMutableArray new];
    }
    
  return self;
  }

// Destructor.
- (void) dealloc
  {
  [myLoginItems release];
  
  [super dealloc];
  }

// Perform the collection.
- (void) collect
  {
  [self updateStatus: NSLocalizedString(@"Checking login items", NULL)];

  [self collectOldLoginItems];
  [self collectModernLoginItems];
  
  NSUInteger count = 0;
  
  for(NSDictionary * loginItem in self.loginItems)
    if([self printLoginItem: loginItem count: count])
      ++count;
    
  if(count > 0)
    [self.result appendCR];

  dispatch_semaphore_signal(self.complete);
  }

// Collect old login items.
- (void) collectOldLoginItems
  {
  NSArray * args =
    @[
      @"-e",
      @"tell application \"System Events\" to get the properties of every login item"
    ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  if([subProcess execute: @"/usr/bin/osascript" arguments: args])
    [self collectASLoginItems: subProcess.standardOutput];
    
  [subProcess release];
  }

// Collect modern login items.
- (void) collectModernLoginItems
  {
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  BOOL success =
    [subProcess
      execute:
        @"/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister"
      arguments: @[ @"-dump"]];
    
  if(success)
    {
    NSMutableDictionary * loginItems = [NSMutableDictionary new];
  
    NSArray * lines = [Utilities formatLines: subProcess.standardOutput];

    BOOL loginItem = NO;
    BOOL backgroundItem = NO;
    NSString * path = nil;
    NSString * resolvedPath = nil;
    NSString * name = nil;
    NSString * identifier = nil;
    
    for(NSString * line in lines)
      {
      NSString * trimmedLine =
        [line
          stringByTrimmingCharactersInSet:
            [NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
      if([trimmedLine isEqualToString: @""])
        continue;

      BOOL check =
        [trimmedLine
          isEqualToString:
            @"--------------------------------------------------------------------------------"];
        
      if(check)
        {
        if(path && resolvedPath && loginItem && backgroundItem)
          if([self SMLoginItemActive: identifier])
            {
            NSDictionary * item =
              [NSDictionary dictionaryWithObjectsAndKeys:
                name, @"name",
                path, @"path",
                @"SMLoginItem", @"kind",
                @"Hidden", @"hidden",
                nil];
              
            [loginItems setObject: item forKey: path];
            }

        loginItem = NO;
        backgroundItem = NO;
        path = nil;
        resolvedPath = nil;
        name = nil;
        }
      else if([trimmedLine hasPrefix: @"path:"])
        {
        NSString * value = [trimmedLine substringFromIndex: 5];
        
        path =
          [value
            stringByTrimmingCharactersInSet:
              [NSCharacterSet whitespaceAndNewlineCharacterSet]];
          
        NSRange range =
          [path rangeOfString: @"/Contents/Library/LoginItems/"];
          
        if(range.location != NSNotFound)
          if([[NSFileManager defaultManager] fileExistsAtPath: path])
            loginItem = YES;
        }
      else if([trimmedLine hasPrefix: @"name:"])
        {
        NSString * value = [trimmedLine substringFromIndex: 5];
        
        name =
          [value
            stringByTrimmingCharactersInSet:
              [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        }
      else if([trimmedLine hasPrefix: @"identifier:"])
        {
        NSString * value = [trimmedLine substringFromIndex: 11];
        
        value =
          [value
            stringByTrimmingCharactersInSet:
              [NSCharacterSet whitespaceAndNewlineCharacterSet]];
 
        NSRange range = [value rangeOfString: @" ("];
        
        if(range.location != NSNotFound)
          {
          identifier = [value substringToIndex: range.location];
          
          resolvedPath =
            [[NSWorkspace sharedWorkspace]
              absolutePathForAppBundleWithIdentifier: identifier];
          }
        }
      else if([trimmedLine hasPrefix: @"flags:"])
        {
        NSRange range = [trimmedLine rangeOfString: @"bg-only"];
        
        if(range.location != NSNotFound)
          backgroundItem = YES;
          
        range = [trimmedLine rangeOfString: @"ui-element"];
        
        if(range.location != NSNotFound)
          backgroundItem = YES;
        }
      }

    [self.loginItems addObjectsFromArray: [loginItems allValues]];
    
    [loginItems release];
    }
    
  [subProcess release];
  }

// Is an SMLoginItem active?
- (BOOL) SMLoginItemActive: (NSString *) identifier
  {
  BOOL active = NO;
  
  NSArray * args =
    @[
      @"list",
      identifier
    ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  if([subProcess execute: @"/bin/launchctl" arguments: args])
    {
    NSArray * lines = [Utilities formatLines: subProcess.standardOutput];

    for(NSString * line in lines)
      {
      NSString * trimmedLine =
        [line
          stringByTrimmingCharactersInSet:
            [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
      if([trimmedLine hasPrefix: @"\"Label\" = \""])
        {
        NSString * label =
          [trimmedLine
            substringWithRange: NSMakeRange(11, [trimmedLine length] - 13)];
          
        if([label isEqualToString: identifier])
          active = YES;
        }
      }
    }
    
  [subProcess release];
  
  return active;
  }
  
// Format the comma-delimited list of login items.
- (void) collectASLoginItems: (NSData *) data
  {
  if(!data)
    return;
  
  NSString * string =
    [[NSString alloc]
      initWithBytes: [data bytes]
      length: [data length]
      encoding: NSUTF8StringEncoding];
  
  if(!string)
    return;

  NSArray * parts = [string componentsSeparatedByString: @","];
  
  [string release];
  
  for(NSString * part in parts)
    {
    NSArray * keyValue = [self parseKeyValue: part];
    
    if(!keyValue)
      continue;
      
    NSString * key = [keyValue objectAtIndex: 0];
    NSString * value = [keyValue objectAtIndex: 1];
    
    if([key isEqualToString: @"name"])
      [self.loginItems addObject: [NSMutableDictionary dictionary]];
    else if([key isEqualToString: @"path"])
      value = [Utilities cleanPath: value];
    
    NSMutableDictionary * loginItem = [self.loginItems lastObject];
    
    [loginItem setObject: value forKey: key];
    }
  }

// Print a login item.
- (bool) printLoginItem: (NSDictionary *) loginItem
  count: (NSUInteger) count
  {
  NSString * name = [loginItem objectForKey: @"name"];
  NSString * path = [loginItem objectForKey: @"path"];
  NSString * kind = [loginItem objectForKey: @"kind"];
  NSString * hidden = [loginItem objectForKey: @"hidden"];
  
  if(![name length])
    name = @"-";
    
  if(![path length])
    return NO;
    
  if(![kind length])
    return NO;

  if([kind isEqualToString: @"UNKNOWN"])
    if([path isEqualToString: @"missing value"])
      return NO;
    
  if([path length] == 0)
    return NO;
    
  NSString * safeName = [Utilities cleanPath: name];
  
  if([safeName length] == 0)
    safeName = name;
    
  NSString * safePath = [Utilities cleanPath: path];
  
  if([safePath length] == 0)
    return NO;
    
  bool isHidden = [hidden isEqualToString: @"true"];
  
  NSString * modificationDateString = @"";
  
  if([kind isEqualToString: @"Application"])
    [self modificationDateString: path];
    
  if(count == 0)
    [self.result appendAttributedString: [self buildTitle]];
    
  BOOL trashed = [path rangeOfString: @"/.Trash/"].location != NSNotFound;
  
  // Flag a login item if it is in the trash.
  if(trashed)
    [self.result
      appendString:
        [NSString
          stringWithFormat:
            @"    %@    %@ %@ (%@)%@\n",
            safeName,
            kind,
            isHidden ? NSLocalizedString(@"Hidden", NULL) : @"",
            safePath,
            modificationDateString]
      attributes:
        [NSDictionary
          dictionaryWithObjectsAndKeys:
            [NSColor redColor], NSForegroundColorAttributeName, nil]];
  else
    [self.result
      appendString:
        [NSString
          stringWithFormat:
            @"    %@    %@ %@ (%@)%@\n",
            safeName,
            kind,
            isHidden ? NSLocalizedString(@"Hidden", NULL) : @"",
            safePath,
            modificationDateString]];
    
  return YES;
  }

// Get the modification date string of a path.
- (NSString *) modificationDateString: (NSString *) path
  {
  NSDate * modificationDate = [self modificationDate: path];
  
  if(modificationDate)
    return
      [NSString
        stringWithFormat:
          @" (%@)",
          [Utilities dateAsString: modificationDate format: @"yyyy-MM-dd"]];
    
  return @"";
  }

// Get the modification date of a file.
- (NSDate *) modificationDate: (NSString *) path
  {
  NSRange appRange = [path rangeOfString: @".app/Contents/MacOS/"];
  
  if(appRange.location != NSNotFound)
    path = [path substringToIndex: appRange.location + 4];

  return [Utilities modificationDate: path];
  }

// Parse a key/value from a login item result.
- (NSArray *) parseKeyValue: (NSString *) part
  {
  NSArray * keyValue = [part componentsSeparatedByString: @":"];
  
  if([keyValue count] < 2)
    return nil;
    
  NSString * key =
    [[keyValue objectAtIndex: 0]
      stringByTrimmingCharactersInSet:
        [NSCharacterSet whitespaceAndNewlineCharacterSet]];

  NSString * value = 
    [[keyValue objectAtIndex: 1]
      stringByTrimmingCharactersInSet:
        [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
  return @[key, value];
  }

@end
