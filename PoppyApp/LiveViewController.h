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

@interface LiveViewController : UIViewController
{
    GPUImageVideoCamera *videoCamera;
    GPUImageMovieWriter *movieWriter;
    GPUImageView *uberView;
    GPUImagePicture *blankImage;
}

@end
