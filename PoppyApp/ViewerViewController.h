//
//  ViewerViewController.h
//  Poppy
//
//  Created by Ethan Lowry on 2/18/14.
//  Copyright (c) 2014 Ethan Lowry. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "GPUImage.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "RBVolumeButtons.h"
#import <AudioToolbox/AudioToolbox.h>
#import <MediaPlayer/MediaPlayer.h>
#import <CalibrationViewController.h>

@interface ViewerViewController : UIViewController <UIWebViewDelegate>

{
    RBVolumeButtons *buttonStealer;
}

@property (nonatomic, retain) MPMoviePlayerController *mainMoviePlayer;
@property (nonatomic, retain) UIImageView *imgView;
@property (nonatomic, retain) UIView *viewViewerControls;
@property (nonatomic, retain) UIView *viewDeleteAlert;
@property (nonatomic, retain) UIView *viewNoMedia;

@end