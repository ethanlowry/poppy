//
//  GalleryViewController.h
//  Poppy
//
//  Created by Ethan Lowry on 1/3/14.
//  Copyright (c) 2014 Ethan Lowry. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "RBVolumeButtons.h"
#import <AudioToolbox/AudioToolbox.h>
#import <MediaPlayer/MediaPlayer.h>

@interface GalleryViewController : UIViewController

@property (nonatomic, strong) NSMutableArray *galleryArray;
@property (nonatomic, strong) UIView *galleryListView;
@property (nonatomic, strong) UIView *displayView;
@property (nonatomic, strong) UIImageView *imgView;
@property (nonatomic, strong) UIView *viewLoadingLabel;
@property (nonatomic, strong) UIView *viewViewerControls;
@property (nonatomic) float frameHeight;
@property (nonatomic) float frameWidth;

@property (nonatomic) BOOL showPopular;

@property (nonatomic, strong) RBVolumeButtons *buttonStealer;

@property (nonatomic, strong) NSMutableArray *imageArray;

@end
