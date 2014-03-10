//
//  GalleryViewController.h
//  Poppy
//
//  Created by Ethan Lowry on 1/3/14.
//  Copyright (c) 2014 Hack Things LLC. All rights reserved.
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

@property (nonatomic, strong) UIImageView *imgSourceL;
@property (nonatomic, strong) UILabel *labelAttributionL;
@property (nonatomic, strong) UIImageView *imgSourceR;
@property (nonatomic, strong) UILabel *labelAttributionR;
@property (nonatomic, strong) UIView *viewAttribution;
@property (nonatomic, strong) UILabel *labelLikeCountL;
@property (nonatomic, strong) UILabel *labelLikeCountR;
@property (nonatomic, strong) UIImageView *likeImageL;
@property (nonatomic, strong) UIImageView *likeImageR;

@property (nonatomic, strong) UIButton *buttonFavorite;

@property (nonatomic, strong) UIView *viewBlockAlert;

@property (nonatomic) BOOL showPopular;

@property (nonatomic, strong) NSMutableArray *imageArray;

@end
