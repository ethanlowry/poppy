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

@interface LiveViewController : UIViewController
{
    GPUImageVideoCamera *videoCamera;
    GPUImageStillCamera *stillCamera;
    GPUImageMovieWriter *movieWriter;
    GPUImageView *uberView;
    GPUImagePicture *blankImage;
    GPUImageAddBlendFilter *finalFilter;
    RBVolumeButtons *buttonStealer;
    AVCaptureDevice *device;
}

@end
