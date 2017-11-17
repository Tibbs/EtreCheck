/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "UbiquityContainerDirectory.h"
#import "UbiquityContainer.h"
#import "XMLBuilder.h"

@implementation UbiquityContainerDirectory

// The container-relative directory name.
@synthesize name = myName;

// The display name.
@synthesize displayName = myDisplayName;

// Pending files.
@synthesize pendingFiles = myPendingFiles;

// Constructor with directory name.
- (instancetype) initWithContainer: (UbiquityContainer *) container 
  directory: (NSString *) name
  {
  self = [super init];
  
  if(self != nil)
    {
    myName = [name retain];
    
    // Special logic for iCloud Drive itself.
    if([container.ubiquityID isEqualToString: @"com.apple.CloudDocs"])
      self.displayName = name;
    else if([name hasPrefix: @"/Documents"])
      self.displayName = [name substringFromIndex: 10];
      
    // Don't keep just a slash.
    if([self.displayName isEqualToString: @"/"])
      self.displayName = @"";
      
    myPendingFiles = [NSMutableArray new];
    }
    
  return self;
  }
  
// Destructor.
- (void) dealloc
  {
  [myName release];
  
  self.displayName = nil;
  self.pendingFiles = nil;
  
  [super dealloc];
  }
  
// Build the XML value.
- (void) buildXMLValue: (XMLBuilder *) xml
  {
  [xml startElement: @"directory"];
    
  [xml addElement: @"name" value: self.name];
  [xml addElement: @"displayname" value: self.displayName];
  
  [xml addArray: @"pendingfiles" values: self.pendingFiles];
  
  [xml endElement: @"directory"];
  }

@end
