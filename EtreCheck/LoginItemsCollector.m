/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "LoginItemsCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"
#import "SubProcess.h"
#import "XMLBuilder.h"

// Collect login items.
@implementation LoginItemsCollector

@synthesize loginItems = myLoginItems;

// Constructor.
- (id) init
  {
  self = [super initWithName: @"loginitems"];
  
  if(self)
    {
    myLoginItems = [NSMutableArray new];
    
    return self;
    }
    
  return nil;
  }

// Destructor.
- (void) dealloc
  {
  [myLoginItems release];
  
  [super dealloc];
  }

// Perform the collection.
- (void) performCollection
  {
  [self updateStatus: NSLocalizedString(@"Checking login items", NULL)];

  [self collectOldLoginItems];
  [self collectModernLoginItems];
  
  NSUInteger machItemCount = 0;
  
  machItemCount +=
    [self collectMachInitFiles: @"/etc/mach_init_per_login_session.d"];
  machItemCount +=
    [self collectMachInitFiles: @"/etc/mach_init_per_user.d"];

  NSUInteger loginHookCount = 0;
  
  //loginHookCount += [self collectLoginHooks];
  loginHookCount += [self collectOldLoginHooks];

  NSUInteger count = 0;
  
  if(machItemCount > 0)
    {
    [self.XML addAttribute: @"severity" value: @"warning"];
    [self.XML
      addElement: @"severity_explanation" value: @"machinitdeprecated"];
    }
    
  if(loginHookCount > 0)
    {
    [self.XML addAttribute: @"severity" value: @"warning"];
    [self.XML
      addElement: @"severity_explanation" value: @"loginhookdeprecated"];
    }

  for(NSDictionary * loginItem in self.loginItems)
    if([self printLoginItem: loginItem count: count])
      ++count;
    
  if(machItemCount > 0)
    {
    [self.result
      appendString: NSLocalizedString(@"machinitdeprecated", NULL)
      attributes:
        @{
          NSForegroundColorAttributeName : [[Utilities shared] red],
        }];
    }
    
  if(loginHookCount > 0)
    {
    [self.result
      appendString: NSLocalizedString(@"loginhookdeprecated", NULL)
      attributes:
        @{
          NSForegroundColorAttributeName : [[Utilities shared] red],
        }];
    }
    
  if(count > 0)
    [self.result appendCR];
  }

// Collect Mach init files.
- (NSUInteger) collectMachInitFiles: (NSString *) path
  {
  NSArray * machInitFiles = [Utilities checkMachInit: path];
  
  for(NSString * file in machInitFiles)
    {
    NSString * name = [file lastPathComponent];
    
    NSDictionary * item =
      [NSDictionary dictionaryWithObjectsAndKeys:
        name, @"name",
        file, @"path",
        @"MachInit", @"kind",
        @"Hidden", @"hidden",
        nil];
      
    [self.loginItems addObject: item];
    }
    
  return [machInitFiles count];
  }

// Collect Login hooks.
- (NSUInteger) collectLoginHooks
  {
  NSUInteger hooks = 0;
  
  NSUserDefaults * defaults = [[NSUserDefaults alloc] init];
  
  // Bummer. This needs root.
  NSDictionary * settings =
    [defaults
      persistentDomainForName:
        @"/var/root/Library/Preferences/com.apple.loginwindow.plist"];

  [defaults release];

  NSString * loginHook = [settings objectForKey: @"LoginHook"];
  NSString * logoutHook = [settings objectForKey: @"LogoutHook"];
  
  if([loginHook length])
    {
    NSDictionary * item =
      [NSDictionary dictionaryWithObjectsAndKeys:
        @"com.apple.loginwindow", @"name",
        loginHook, @"path",
        @"LoginHook", @"kind",
        @"Hidden", @"hidden",
        nil];
      
    [self.loginItems addObject: item];
    
    ++hooks;
    }
    
  if([logoutHook length])
    {
    NSDictionary * item =
      [NSDictionary dictionaryWithObjectsAndKeys:
        @"com.apple.loginwindow", @"name",
        logoutHook, @"path",
        @"LogoutHook", @"kind",
        @"Hidden", @"hidden",
        nil];
      
    [self.loginItems addObject: item];
    
    ++hooks;
    }

  return hooks;
  }

// Collect old Login hooks.
- (NSUInteger) collectOldLoginHooks
  {
  NSUInteger hooks = 0;

  NSData * tty = [NSData dataWithContentsOfFile: @"/etc/ttys"];
   
  NSArray * lines = [Utilities formatLines: tty];

  NSString * loginHook = nil;
  NSString * logoutHook = nil;
  
  for(NSString * line in lines)
    {
    NSRange tagRange = [line rangeOfString: @"-LoginHook"];
    
    if(tagRange.location != NSNotFound)
      {
      NSString * script = [line substringFromIndex: tagRange.location];
      
      NSScanner * scanner = [NSScanner scannerWithString: script];
      
      [scanner scanString: @"-LoginHook" intoString: NULL];
      [scanner
        scanUpToCharactersFromSet:
          [NSCharacterSet whitespaceAndNewlineCharacterSet]
        intoString: & loginHook];
        
      if([loginHook length] > 0)
        loginHook = [loginHook substringToIndex: [loginHook length] - 1];
      }
      
    tagRange = [line rangeOfString: @"-LogoutHook"];
    
    if(tagRange.location != NSNotFound)
      {
      NSString * script = [line substringFromIndex: tagRange.location];
      
      NSScanner * scanner = [NSScanner scannerWithString: script];
      
      [scanner scanString: @"-LogoutHook" intoString: NULL];
      [scanner
        scanUpToCharactersFromSet:
          [NSCharacterSet whitespaceAndNewlineCharacterSet]
        intoString: & logoutHook];
        
      if([logoutHook length] > 0)
        logoutHook = [logoutHook substringToIndex: [logoutHook length] - 1];
      }
    }
    
  if([loginHook length])
    {
    NSDictionary * item =
      [NSDictionary dictionaryWithObjectsAndKeys:
        @"/etc/ttys", @"name",
        loginHook, @"path",
        @"LoginHook", @"kind",
        @"Hidden", @"hidden",
        nil];
      
    [self.loginItems addObject: item];
    
    ++hooks;
    }
    
  if([logoutHook length])
    {
    NSDictionary * item =
      [NSDictionary dictionaryWithObjectsAndKeys:
        @"/etc/ttys", @"name",
        logoutHook, @"path",
        @"LogoutHook", @"kind",
        @"Hidden", @"hidden",
        nil];
      
    [self.loginItems addObject: item];
    
    ++hooks;
    }

  return hooks;
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
  // TODO: Does not work in sandbox.
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
  
  if([path length] > 0)
    modificationDateString = [self modificationDateString: path];
    
  if(count == 0)
    [self.result appendAttributedString: [self buildTitle]];
    
  BOOL highlight = NO;
  
  [self.XML startElement: @"loginitem"];
  
  if([path rangeOfString: @"/.Trash/"].location != NSNotFound)
    {
    [self.XML addAttribute: @"severity" value: @"warning"];
    [self.XML
      addElement: @"severity_explanation" value: @"loginitemtrashed"];
    highlight = YES;
    }
    
  if([kind isEqualToString: @"MachInit"])
    highlight = YES;
  
  if([kind isEqualToString: @"LoginHook"])
    highlight = YES;

  if([kind isEqualToString: @"LogoutHook"])
    highlight = YES;

  [self.XML addAttribute: @"hidden" boolValue: isHidden];
  
  [self.XML addElement: @"name" value: safeName];
  [self.XML addElement: @"type" value: kind];
  [self.XML addElement: @"path" value: safePath];
   
   NSDate * modificationDate = [self modificationDate: path];

  if(modificationDate)
    [self.XML addElement: @"date" date: modificationDate];
  
  // Flag a login item if it is in the trash.
  if(highlight)
    [self.result
      appendString:
        [NSString
          stringWithFormat:
            @"    %@    %@ %@%@\n        (%@)\n",
            safeName,
            kind,
            isHidden ? NSLocalizedString(@"Hidden ", NULL) : @" ",
            modificationDateString,
            safePath]
      attributes:
        [NSDictionary
          dictionaryWithObjectsAndKeys:
            [NSColor redColor], NSForegroundColorAttributeName, nil]];
  else
    [self.result
      appendString:
        [NSString
          stringWithFormat:
            @"    %@    %@ %@%@\n        (%@)\n",
            safeName,
            kind,
            isHidden ? NSLocalizedString(@"Hidden ", NULL) : @" ",
            modificationDateString,
            safePath]];
    
  [self.XML endElement: @"loginitem"];
  
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
  
  if(appRange.location == NSNotFound)
    appRange = [path rangeOfString: @".app/Contents/Library/LoginItems/"];

  if(appRange.location != NSNotFound)
    {
    path = [path substringToIndex: appRange.location + 4];

    return [Utilities modificationDate: path];
    }
    
  return nil;
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
