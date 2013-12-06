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

@interface LiveViewController : UIViewController

{
    GPUImageVideoCamera *videoCamera;
    GPUImageStillCamera *stillCamera;
    GPUImageMovieWriter *movieWriter;
    GPUImageView *uberView;
    UIImageView *imgView;
    GPUImageCropFilter *finalFilter;
    GPUImageCropFilter *displayFilter;
    RBVolumeButtons *buttonStealer;
    MPMoviePlayerController *mainMoviePlayer;
}

@property (nonatomic) BOOL isViewActive;
@property (nonatomic) float xOffset;
@property (nonatomic) BOOL calibrateFirst;

-(void)activateView;

@end
