//
//  HomeViewController.h
//  Poppy
//
//  Created by Ethan Lowry on 1/13/14.
//  Copyright (c) 2014 Ethan Lowry. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "RBVolumeButtons.h"
#import <AudioToolbox/AudioToolbox.h>

#import <CalibrationViewController.h>
#import <LiveViewController.h>
#import <ViewerViewController.h>
#import <GalleryViewController.h>

@interface HomeViewController : UIViewController

@property (strong, nonatomic) UIView *viewConnectionAlert;
@property (strong, nonatomic) UIView *viewCalibrationAlert;

@end
