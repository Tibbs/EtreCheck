/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "UbiquityFile.h"
#import "XMLBuilder.h"

// An iCloud file that needs to be reported.
@implementation UbiquityFile

// The file name.
@synthesize name = myName;

// The status.
@synthesize status = myStatus;

// The progress percentage.
@synthesize progress = myProgress;

// Constructor.
- (instancetype) initWithName: (NSString *) name
  {
  self = [super init];
  
  if(self != nil)
    {
    myName = [name retain];
    }
    
  return self;
  }
  
// Destructor.
- (void) dealloc
  {
  [myName release];
  
  self.status = nil;
  
  [super dealloc];
  }
  
// Build the XML value.
- (void) buildXMLValue: (XMLBuilder *) xml
  {
  [xml startElement: @"file"];
    
  [xml addElement: @"name" safeASCII: self.name];
  [xml addElement: @"status" value: self.status];
  [xml addElement: @"progress" doubleValue: self.progress];
  
  [xml endElement: @"file"];
  }

@end
