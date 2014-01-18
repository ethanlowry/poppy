//
//  LiveViewController.h
//  PoppyApp
//
//  Created by Ethan Lowry on 10/1/13.
//  Copyright (c) 2013 Ethan Lowry. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPUImage.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "RBVolumeButtons.h"
#import <AudioToolbox/AudioToolbox.h>
#import <MediaPlayer/MediaPlayer.h>
#import <CalibrationViewController.h>

@interface LiveViewController : UIViewController <UIWebViewDelegate>

{
    RBVolumeButtons *buttonStealer;
}

@property (nonatomic, retain) MPMoviePlayerController *mainMoviePlayer;
@property (nonatomic, retain) GPUImageVideoCamera *videoCamera;
@property (nonatomic, retain) GPUImageStillCamera *stillCamera;
@property (nonatomic, retain) GPUImageMovieWriter *movieWriter;
@property (nonatomic, retain) GPUImageView *uberView;
@property (nonatomic, retain) UIImageView *imgView;
@property (nonatomic, retain) UIWebView *galleryWebView;
@property (nonatomic, retain) GPUImageCropFilter *finalFilter;
@property (nonatomic, retain) GPUImageCropFilter *displayFilter;

@property (nonatomic, retain) UIView *viewCameraControls;
@property (nonatomic, retain) UIButton *buttonShutter;
@property (nonatomic, retain) UIView *viewSaving;
@property (nonatomic, retain) UIView *viewViewerControls;
@property (nonatomic, retain) UIView *viewDeleteAlert;

@property (nonatomic) BOOL isViewActive;
@property (nonatomic) float xOffset;
@property (nonatomic) BOOL calibrateFirst;
@property (nonatomic) BOOL isWatching;

-(void)activateView;

@end
