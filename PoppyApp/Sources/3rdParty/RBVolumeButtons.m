//
//  RBVolumeButtons.m
//  VolumeSnap
//
//  Created by Randall Brown on 11/17/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "RBVolumeButtons.h"
#import <AudioToolbox/AudioToolbox.h>
#import <MediaPlayer/MediaPlayer.h>

@interface RBVolumeButtons()

@property BOOL isStealingVolumeButtons;
@property BOOL suspended;
@property (nonatomic, strong) UIView *volumeView;
@property (nonatomic, readwrite) float launchVolume;

@property (nonatomic) BOOL hadToLowerVolume;
@property (nonatomic) BOOL hadToRaiseVolume;

@property (nonatomic) NSInteger listenerRegistrationCount;

@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
@implementation RBVolumeButtons

void volumeListenerCallback (
                             void                      *inClientData,
                             AudioSessionPropertyID    inID,
                             UInt32                    inDataSize,
                             const void                *inData
                             );
void volumeListenerCallback (
                             void                      *inClientData,
                             AudioSessionPropertyID    inID,
                             UInt32                    inDataSize,
                             const void                *inData
                             ){
	RBVolumeButtons *volumeButtons = (__bridge RBVolumeButtons*)inClientData;
	const float *volumePointer = inData;
	float volume = *volumePointer;
	float launchVolume = [volumeButtons launchVolume];
	DEBUGLOG(@"%s volume: %0.3f vs. launch: %0.3f",__FUNCTION__,volume,launchVolume);

	// ignore big steps in volume as they are not representing button presses
	float volumeDifference = ABS(volume - launchVolume);
	if (volumeDifference < 0.2) {
		if( volume > launchVolume)
		{
			[volumeButtons volumeChangeWasUp:YES];
		}
		else if( volume < launchVolume )
		{
			[volumeButtons volumeChangeWasUp:NO];
		}
	} else {
		DEBUGLOG(@"%s ignored volume change due to too big of a difference: %0.3f",__FUNCTION__,volumeDifference);
	}
}

- (void)addMyListener {
	if (self.listenerRegistrationCount > 0) {
		//NSLog(@"%s over registering! (%ld)",__FUNCTION__,(long)self.listenerRegistrationCount);
	}
	AudioSessionAddPropertyListener(kAudioSessionProperty_CurrentHardwareOutputVolume, volumeListenerCallback, (__bridge void *)(self));
	self.listenerRegistrationCount++;
}

- (void)removeMyListener {
	AudioSessionRemovePropertyListenerWithUserData(kAudioSessionProperty_CurrentHardwareOutputVolume, volumeListenerCallback, (__bridge void *)(self));
	self.listenerRegistrationCount--;
}

- (void)volumeChangeWasUp:(BOOL)isUp {
	[self removeMyListener];
	[[MPMusicPlayerController applicationMusicPlayer] setVolume:self.launchVolume];
	
	[self performSelector:@selector(initializeVolumeButtonStealer) withObject:self afterDelay:0.1];
	
	// early exit
	if (self.ignoreNextVolumeChange) {
		self.ignoreNextVolumeChange = NO;
		return;
	}

	dispatch_block_t volumeBlock = isUp ? self.upBlock : self.downBlock;
	if (volumeBlock) {
		dispatch_async(dispatch_get_main_queue(), volumeBlock);
	}
}

-(id)init
{
   self = [super init];
   if( self )
   {
      self.isStealingVolumeButtons = NO;
      self.suspended = NO;
   }
   return self;
}

-(void)startStealingVolumeButtonEvents
{
	NSAssert([[NSThread currentThread] isMainThread], @"This must be called from the main thread");
	
	if(self.isStealingVolumeButtons) {
		return;
	}
    
    self.isStealingVolumeButtons = YES;
	
	AudioSessionInitialize(NULL, NULL, NULL, NULL);

	UInt32 sessionCategory = kAudioSessionCategory_AmbientSound;
	AudioSessionSetProperty (
							 kAudioSessionProperty_AudioCategory,
							 sizeof (sessionCategory),
							 &sessionCategory
							 );
	
	AudioSessionSetActive(YES);
	
	CGRect frame = CGRectMake(0, -10, 1, 1);
	self.volumeView = [[MPVolumeView alloc] initWithFrame:frame];
	[[[[UIApplication sharedApplication] windows] objectAtIndex:0] insertSubview:self.volumeView atIndex:0];
	
	self.launchVolume = [[MPMusicPlayerController applicationMusicPlayer] volume];
	BOOL hadToLowerVolume = self.launchVolume == 1.0;
	BOOL hadToRaiseVolume = self.launchVolume == 0.0;
	
    // Avoid flashing the volume indicator
    if (hadToLowerVolume || hadToRaiseVolume)
    {
		double delayInSeconds = 0.01;
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
		dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            if( hadToLowerVolume )
            {
                [[MPMusicPlayerController applicationMusicPlayer] setVolume:0.95];
                self.launchVolume = 0.95;
            }
            
            if( hadToRaiseVolume )
            {
                [[MPMusicPlayerController applicationMusicPlayer] setVolume:0.05];
                self.launchVolume = 0.05;
            }
		});
    }
	self.hadToLowerVolume = hadToLowerVolume;
	self.hadToRaiseVolume = hadToRaiseVolume;
	
	
	[self initializeVolumeButtonStealer];
	
    if (!self.suspended)
    {
        // Observe notifications that trigger suspend
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(suspendStealingVolumeButtonEvents:)
                                                     name:UIApplicationWillResignActiveNotification     // -> Inactive
                                                   object:nil];
        
        // Observe notifications that trigger resume
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(resumeStealingVolumeButtonEvents:)
                                                     name:UIApplicationDidBecomeActiveNotification      // <- Active
                                                   object:nil];
    }
}

- (void)suspendStealingVolumeButtonEvents:(NSNotification *)notification
{
    if(self.isStealingVolumeButtons)
    {
        self.suspended = YES; // Call first!
        [self stopStealingVolumeButtonEvents];
    }
}

- (void)resumeStealingVolumeButtonEvents:(NSNotification *)notification
{
    if(self.suspended)
    {
        [self startStealingVolumeButtonEvents];
        self.suspended = NO; // Call last!
		[self initializeVolumeButtonStealer]; // wasn't executing before because we were suspended
    }
}

-(void)stopStealingVolumeButtonEvents
{
   NSAssert([[NSThread currentThread] isMainThread], @"This must be called from the main thread");
   
   if(!self.isStealingVolumeButtons)
   {
      return;
   }
    
    // Stop observing all notifications
    if (!self.suspended)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }

	[self removeMyListener];
   
   if( self.hadToLowerVolume )
   {
      [[MPMusicPlayerController applicationMusicPlayer] setVolume:1.0];
   }
   
   if( self.hadToRaiseVolume )
   {
      [[MPMusicPlayerController applicationMusicPlayer] setVolume:0.0];
   }
   
   [self.volumeView removeFromSuperview];
   self.volumeView = nil;
   
   AudioSessionSetActive(NO);
   
   self.isStealingVolumeButtons = NO;
}

-(void)dealloc
{
    self.suspended = NO;
   [self stopStealingVolumeButtonEvents];
    
}

-(void)initializeVolumeButtonStealer
{
	if (!self.suspended && self.isStealingVolumeButtons) {
		[self addMyListener];
	}
}

@end

#pragma clang diagnostic pop
