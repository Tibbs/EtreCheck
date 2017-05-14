/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import <QuartzCore/CAAnimation.h>
#import <QuartzCore/CoreImage.h>

#import "SlideshowView.h"

@implementation SlideshowView

@synthesize maskView = myMaskView;

// Destructor.
- (void) dealloc
  {
  [myMaskView release];
  
  [super dealloc];
  }

// Set the transition style.
- (void) updateSubviewsWithTransition: (NSString *) transition
  {
  [self
    updateSubviewsWithTransition: transition
    subType: kCATransitionFromLeft];
  }

// Set the transition style with subtype.
- (void) updateSubviewsWithTransition: (NSString *) transition
  subType: (NSString *) subtype
  {
  CIFilter * transitionFilter = [CIFilter filterWithName: transition];
    
  [transitionFilter setDefaults];
    
	CATransition * newTransition = [CATransition animation];
    
  // We want to specify one of Core Animation's built-in transitions.
  //[newTransition setFilter:transitionFilter];
  [newTransition setType: transition];
  [newTransition setSubtype: subtype];

  // Specify an explicit duration for the transition.
  [newTransition setDuration: 0.2];

  // Associate the CATransition with the "subviews" key for this
  // SlideshowView instance, so that when we swap ImageView instances in
  // the -transitionToImage: method below (via -replaceSubview:with:).
	[self
    setAnimations:
      [NSDictionary
        dictionaryWithObject: newTransition forKey: @"subviews"]];
  }

// Create a new NSImageView and swap it into the view in place of the
// previous NSImageView. This will trigger the transition animation wired
// up in -updateSubviewsTransition, which fires on changes in the "subviews"
// property.
- (void) transitionToImage: (NSImage *) newImage
  {
  NSImageView * newImageView = nil;
  
  if(newImage)
	  {
    newImageView = [[NSImageView alloc] initWithFrame: [self bounds]];
    [newImageView setImage: newImage];
    [newImageView
      setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
    }
   
  [self transitionToView: newImageView];
  [newImageView release];
  }

// Swap a new NSView into the view in place of the previous NSView. This
// will trigger the transition animation wired up in
// -updateSubviewsTransition, which fires on changes in the "subviews"
// property.
- (void) transitionToView: (NSView *) newView
  {
  if(currentView && newView)
    [[self animator] replaceSubview: currentView with: newView];
    
	else
	  {
    if(currentView)
			[[currentView animator] removeFromSuperview];
    
    NSView * maskView = self.maskView;
    
    if(!maskView)
      maskView = self;
      
    if(newView)
      {
      if(currentView)
        [[self animator]
          addSubview: newView
          positioned: NSWindowBelow
          relativeTo: maskView];
      else
        [self addSubview: newView];
      }
    }
    
  currentView = newView;
  }

@end
