//
//  HomeViewController.h
//  Poppy
//
//  Created by Ethan Lowry on 1/13/14.
//  Copyright (c) 2014 Hack Things LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "RBVolumeButtons.h"
#import <AudioToolbox/AudioToolbox.h>


@interface HomeViewController : UIViewController

@property (strong, nonatomic) UIView *viewConnectionAlert;
@property (strong, nonatomic) UIView *viewCalibrationAlert;

@end
