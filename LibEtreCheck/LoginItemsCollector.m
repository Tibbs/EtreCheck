/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014-2017. All rights reserved.
 **********************************************************************/

#import "LoginItemsCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"
#import "SubProcess.h"
#import "XMLBuilder.h"
#import "LocalizedString.h"
#import "NSNumber+Etresoft.h"
#import "NSString+Etresoft.h"
#import "NSDictionary+Etresoft.h"
#import "NSDate+Etresoft.h"

// Collect login items.
@implementation LoginItemsCollector

@synthesize loginItems = myLoginItems;

// Constructor.
- (id) init
  {
  self = [super initWithName: @"loginitems"];
  
  if(self != nil)
    {
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
- (void) performCollect
  {
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
  
  for(NSDictionary * loginItem in self.loginItems)
    if([self printLoginItem: loginItem count: count])
      ++count;
    
  if(machItemCount > 0)
    {
    [self.result
      appendString: ECLocalizedString(@"machinitdeprecated")
      attributes:
        @{
          NSForegroundColorAttributeName : [[Utilities shared] red],
        }];
    }
    
  if(loginHookCount > 0)
    {
    [self.result
      appendString: ECLocalizedString(@"loginhookdeprecated")
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
  
  if(self.simulating && ([machInitFiles count] == 0))
    machInitFiles = 
      [NSArray arrayWithObject: @"/Library/Application Support/SimMacInit"];
    
  for(NSString * file in machInitFiles)
    {
    NSString * developer = [self getDeveloper: path];
      
    if([developer length] == 0)
      developer = @"";
      
    NSString * name = [file lastPathComponent];
    
    NSDictionary * item =
      [NSDictionary dictionaryWithObjectsAndKeys:
        name, @"name",
        file, @"path",
        @"MachInit", @"kind",
        [NSNumber numberWithBool: YES], @"hidden",
        developer, @"developer",
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
  
  if([NSString isValid: loginHook])
    {
    NSDictionary * item =
      [NSDictionary dictionaryWithObjectsAndKeys:
        @"com.apple.loginwindow", @"name",
        loginHook, @"path",
        @"LoginHook", @"kind",
        [NSNumber numberWithBool: YES], @"hidden",
        nil];
      
    [self.loginItems addObject: item];
    
    ++hooks;
    }
    
  NSString * logoutHook = [settings objectForKey: @"LogoutHook"];

  if([NSString isValid: logoutHook])
    {
    NSDictionary * item =
      [NSDictionary dictionaryWithObjectsAndKeys:
        @"com.apple.loginwindow", @"name",
        logoutHook, @"path",
        @"LogoutHook", @"kind",
        [NSNumber numberWithBool: YES], @"hidden",
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

  NSString * loginHooks = nil;
  
  if(self.simulating)
    {
    NSMutableArray * simulatedLines = 
      [NSMutableArray arrayWithArray: lines];
      
    [simulatedLines 
      addObject: 
        @"#console "
        @"\"dummy -LoginHook /Library/App\\ Support/SimLoginHook/ "
        @"-LogoutHook /Library/App\\ Support/SimLogoutHook/\" "
        @"vt100 on dummy "];
        
    lines = simulatedLines;
    }
    
  for(NSString * line in lines)
    {
    NSRange tagRange = [line rangeOfString: @"-LoginHook"];
    
    if(tagRange.location != NSNotFound)
      tagRange = [line rangeOfString: @"-LogoutHook"];
    
    if(tagRange.location != NSNotFound)
      loginHooks = line;
    }
    
  if([loginHooks length])
    {
    NSDictionary * item =
      [NSDictionary dictionaryWithObjectsAndKeys:
        @"/etc/ttys", @"name",
        loginHooks, @"path",
        @"LoginHook", @"kind",
        [NSNumber numberWithBool: YES], @"hidden",
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
            NSString * developer = [self getDeveloper: path];
              
            if([developer length] == 0)
              developer = @"";
              
            NSDictionary * item =
              [NSDictionary dictionaryWithObjectsAndKeys:
                name, @"name",
                path, @"path",
                @"SMLoginItem", @"kind",
                [NSNumber numberWithBool: YES], @"hidden",
                developer, @"developer",
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
      else 
        {
        BOOL checkFlags = NO;
        
        if([trimmedLine hasPrefix: @"flags:"])
          checkFlags = YES;
          
        if([trimmedLine hasPrefix: @"bundle flags:"])
          checkFlags = YES;

        if(checkFlags)
          {
          NSRange range = [trimmedLine rangeOfString: @"bg-only"];
          
          if(range.location != NSNotFound)
            backgroundItem = YES;
            
          range = [trimmedLine rangeOfString: @"ui-element"];
          
          if(range.location != NSNotFound)
            backgroundItem = YES;
          }
        }
      }

    // Avoid adding any login item from an external drive if there is
    // already one on an internal drive.
    NSMutableDictionary * bestLoginItems = [NSMutableDictionary new];
    
    for(NSString * path in loginItems)
      {
      NSDictionary * loginItem = [loginItems objectForKey: path];
      
      if([NSDictionary isValid: loginItem])
        {
        NSString * name = [loginItem objectForKey: @"name"];
        
        NSDictionary * currentLoginItem = 
          [bestLoginItems objectForKey: name];
        
        if(![NSDictionary isValid: currentLoginItem])
          [bestLoginItems setObject: loginItem forKey: name];

        else
          {
          NSString * currentPath = [currentLoginItem objectForKey: @"path"];
          
          if([NSString isValid: currentPath])
            if([currentPath hasPrefix: @"/Volumes/"])
              [bestLoginItems setObject: loginItem forKey: name];
          }
        }
      }
      
    [self.loginItems addObjectsFromArray: [bestLoginItems allValues]];
    
    [bestLoginItems release];
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
    
    NSMutableDictionary * loginItem = [self.loginItems lastObject];
    
    if([key isEqualToString: @"name"])
      {
      loginItem = [NSMutableDictionary dictionary];
      [self.loginItems addObject: loginItem];
      }
    else if([key isEqualToString: @"path"])
      {
      NSString * developer = [self getDeveloper: value];
        
      if([developer length] > 0)
        [loginItem setObject: developer forKey: @"developer"];
      }
    
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
  NSNumber * hidden = [loginItem objectForKey: @"hidden"];
  NSString * developer = [loginItem objectForKey: @"developer"];
  
  if(![NSString isValid: name])
    name = @"-";
    
  if(![NSString isValid: path])
    return NO;
    
  if(![NSString isValid: kind])
    return NO;

  if([kind isEqualToString: @"UNKNOWN"])
    if([path isEqualToString: @"missing value"])
      return NO;
    
  NSString * safeName = [self cleanPath: name];
  
  if(![NSString isValid: safeName])
    safeName = name;
    
  NSString * safePath = [self cleanPath: path];
  
  if(![NSString isValid: safePath])
    return NO;
    
  bool isHidden = NO;
  
  if([NSNumber isValid: hidden])
    [hidden boolValue];
  
  [self.xml startElement: @"loginitem"];
  
  [self.xml addElement: @"name" value: name];
  [self.xml addElement: @"type" value: kind];
  
  if(isHidden)
    [self.xml addElement: @"hidden" boolValue: isHidden];
  
  [self.xml addElement: @"signature" value: developer];
  
  NSString * modificationDateString = @"";
  
  NSDate * modificationDate = [self modificationDate: path];
  
  if([NSDate isValid: modificationDate])
    {
    [self.xml addElement: @"installdate" date: modificationDate];

    modificationDateString =
      [Utilities installDateAsString: modificationDate];
    }
    
  [self.xml addElement: @"path" value: path];

  [self.xml endElement: @"loginitem"];
  
  if(count == 0)
    [self.result appendAttributedString: [self buildTitle]];
    
  BOOL highlight = NO;
  
  if([path rangeOfString: @"/.Trash/"].location != NSNotFound)
    highlight = YES;
    
  if([kind isEqualToString: @"MachInit"])
    highlight = YES;
  
  if([kind isEqualToString: @"LoginHook"])
    highlight = YES;

  if([kind isEqualToString: @"LogoutHook"])
    highlight = YES;

  if(![NSString isValid: developer])
    {
    NSString * crc = [Utilities crcFile: path];
    
    if([crc length] > 0)
      developer = [NSString stringWithFormat: @"? %@", crc];
    }
    
  if(![NSString isValid: developer])
    developer = ECLocalizedString(@"Unknown");
    
  NSString * appInfo = @"";
  
  if([NSString isValid: modificationDateString])
    appInfo =
      [NSString
        stringWithFormat: @"(%@ - %@)", developer, modificationDateString];

  // Flag a login item if it is in the trash.
  if(highlight)
    [self.result
      appendString:
        [NSString
          stringWithFormat:
            @"    %@    %@%@ %@\n        (%@)\n",
            safeName,
            kind,
            isHidden ? ECLocalizedString(@" - Hidden") : @"",
            appInfo,
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
            @"    %@    %@%@ %@\n        (%@)\n",
            safeName,
            kind,
            isHidden ? ECLocalizedString(@" - Hidden") : @"",
            appInfo,
            safePath]];
    
  return YES;
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

// Get the developer name.
- (NSString *) getDeveloper: (NSString *) path
  {
  NSRange range = [path rangeOfString: @".app"];
  
  if(range.location != NSNotFound)
    {
    NSString * signature = [Utilities checkExecutable: path];
  
    if([signature isEqualToString: kSignatureValid])
      return [Utilities queryDeveloper: path];
      
    if([signature isEqualToString: kShell])
      {
      NSString * crc = [Utilities crcFile: path];
      
      if([crc length] == 0)
        crc = @"0";
        
      return
        [NSString
          stringWithFormat:
            @"%@ %@", ECLocalizedString(@"Shell Script"), crc];
      }
    }
    
  return nil;
  }

@end
