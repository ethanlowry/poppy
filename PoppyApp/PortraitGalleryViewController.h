//
//  PortraitGalleryViewController.h
//  Poppy
//
//  Created by Ethan Lowry on 3/7/14.
//  Copyright (c) 2014 Ethan Lowry. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AudioToolbox/AudioToolbox.h>
#import <MediaPlayer/MediaPlayer.h>

@interface PortraitGalleryViewController : UIViewController

@property (nonatomic, strong) NSMutableArray *galleryArray;
@property (nonatomic, strong) UIView *galleryListView;
@property (nonatomic, strong) UIView *displayView;
@property (nonatomic, strong) UIImageView *imgView;
@property (nonatomic, strong) UIView *viewLoadingLabel;
@property (nonatomic, strong) UIView *viewViewerControls;
@property (nonatomic) float frameHeight;
@property (nonatomic) float frameWidth;

@property (nonatomic, strong) UIImageView *imgSource;
@property (nonatomic, strong) UILabel *labelAttribution;
@property (nonatomic, strong) UIView *viewAttribution;
@property (nonatomic, strong) UILabel *labelLikeCount;
@property (nonatomic, strong) UIImageView *likeImage;

@property (nonatomic, strong) UIButton *buttonFavorite;

@property (nonatomic, strong) UIView *viewBlockAlert;

@property (nonatomic) BOOL showPopular;

@property (nonatomic, strong) NSMutableArray *imageArray;
    
@end
