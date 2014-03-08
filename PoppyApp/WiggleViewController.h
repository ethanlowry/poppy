//
//  WiggleViewController.h
//  wiggle_test
//
//  Created by Ethan Lowry on 2/3/14.
//  Copyright (c) 2014 Ethan Lowry. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@interface WiggleViewController : UIViewController <MFMailComposeViewControllerDelegate>
@property (nonatomic, strong) UIImage *stereoImage;
@property (nonatomic, strong) NSURL *assetURL;
@end
