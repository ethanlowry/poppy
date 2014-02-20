//
//  PODShowContentViewController.h
//  Poppy Dome
//
//  Created by Dominik Wagner on 09.12.13.
//  Copyright (c) 2013 Dominik Wagner. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface PODShowContentViewController : UIViewController
@property (nonatomic, strong) ALAssetsGroup *assetsGroup;
@property (nonatomic, strong) NSURL *contentDirectoryURL;

@property (nonatomic, strong) IBOutlet UIView *leftView;
@property (nonatomic, strong) IBOutlet UIView *rightView;

@property (nonatomic, strong) IBOutlet UIImageView *imageView;
@end
