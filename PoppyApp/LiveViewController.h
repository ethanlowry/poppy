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

@interface LiveViewController : UIViewController
{
    GPUImageVideoCamera *videoCamera;
    GPUImageStillCamera *stillCamera;
    GPUImageMovieWriter *movieWriter;
    GPUImageView *uberView;
    UIImageView *imgView;
    GPUImagePicture *blankImage;
    GPUImagePicture *saveBlankImage;
    GPUImageAddBlendFilter *finalFilter;
    GPUImageAddBlendFilter *saveFinalFilter;
    RBVolumeButtons *buttonStealer;
    AVCaptureDevice *device;
    MPMoviePlayerController *mainMoviePlayer;
}

@end
