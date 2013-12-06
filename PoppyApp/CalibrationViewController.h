//
//  CalibrationViewController.h
//  Poppy
//
//  Created by Ethan Lowry on 12/4/13.
//  Copyright (c) 2013 Ethan Lowry. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPUImage.h"
#import "RBVolumeButtons.h"

@interface CalibrationViewController : UIViewController
{
    GPUImageStillCamera *stillCamera;
    GPUImageView *mainView;
    GPUImageCropFilter *displayFilter;
    RBVolumeButtons *buttonStealer;
}
@end
