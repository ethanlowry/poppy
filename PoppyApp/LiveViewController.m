//
//  LiveViewController.m
//  PoppyApp
//
//  Created by Ethan Lowry on 10/1/13.
//  Copyright (c) 2013 Ethan Lowry. All rights reserved.
//

#import "LiveViewController.h"

@interface LiveViewController ()

@end

@implementation LiveViewController

bool didFinishEffect = NO;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    

}

- (void)viewDidAppear:(BOOL)animated
{
    uberView = (GPUImageView *)self.view;
    
    UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cameraViewTapAction:)];
    [uberView addGestureRecognizer:tgr];
    
    //camera setup
    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionBack];
    
    videoCamera.outputImageOrientation = UIInterfaceOrientationLandscapeLeft;
    videoCamera.horizontallyMirrorFrontFacingCamera = NO;
    videoCamera.horizontallyMirrorRearFacingCamera = NO;
    
    // SKEW THE IMAGE FROM BOTH A LEFT AND RIGHT PERSPECTIVE
    CATransform3D perspectiveTransformLeft = CATransform3DIdentity;
    perspectiveTransformLeft.m34 = .4;
    perspectiveTransformLeft = CATransform3DRotate(perspectiveTransformLeft, 0.4, 0.0, 1.0, 0.0);
    GPUImageTransformFilter *filterLeft = [[GPUImageTransformFilter alloc] init];
    [filterLeft setTransform3D:perspectiveTransformLeft];
    
    GPUImageTransformFilter *filterRight = [[GPUImageTransformFilter alloc] init];
    CATransform3D perspectiveTransformRight = CATransform3DIdentity;
    perspectiveTransformRight.m34 = .4;
    perspectiveTransformRight = CATransform3DRotate(perspectiveTransformRight, -0.4, 0.0, 1.0, 0.0);
    [(GPUImageTransformFilter *)filterRight setTransform3D:perspectiveTransformRight];
    
    //CROP THE IMAGE INTO A LEFT AND RIGHT HALF
    GPUImageCropFilter *cropLeft = [[GPUImageCropFilter alloc] init];
    GPUImageCropFilter *cropRight = [[GPUImageCropFilter alloc] init];
    
    CGRect cropRectLeft = CGRectMake(.1, .15, .35, .7);
    CGRect cropRectRight = CGRectMake(.55, .15, .35, .7);
    
    cropLeft = [[GPUImageCropFilter alloc] initWithCropRegion:cropRectLeft];
    cropRight = [[GPUImageCropFilter alloc] initWithCropRegion:cropRectRight];
    
    //SHIFT THE LEFT AND RIGHT HALVES OVER SO THAT THEY CAN BE OVERLAID
    CGAffineTransform landscapeTransformLeft = CGAffineTransformTranslate (CGAffineTransformScale(CGAffineTransformIdentity, 0.5, 1.0), -1.0, 0.0);
    GPUImageTransformFilter *transformLeft = [[GPUImageTransformFilter alloc] init];
    transformLeft.affineTransform = landscapeTransformLeft;

    CGAffineTransform landscapeTransformRight = CGAffineTransformTranslate (CGAffineTransformScale(CGAffineTransformIdentity, 0.5, 1.0), 1.0, 0.0);
    GPUImageTransformFilter *transformRight = [[GPUImageTransformFilter alloc] init];
    transformRight.affineTransform = landscapeTransformRight;
    
    //CREATE A DUMMY FULL-WIDTH IMAGE
    UIImage *blankPic = [UIImage imageNamed:@"blank"];
    blankImage = [[GPUImagePicture alloc] initWithImage: blankPic];
    GPUImageAddBlendFilter *blendImages = [[GPUImageAddBlendFilter alloc] init];

    //STACK ALL THESE FILTERS TOGETHER
    [videoCamera addTarget:filterLeft];
    [filterLeft addTarget:cropLeft];
    [cropLeft addTarget:transformLeft];

    [videoCamera addTarget:filterRight];
    [filterRight addTarget:cropRight];
    [cropRight addTarget:transformRight];
    
    [blankImage addTarget:blendImages];
    [blankImage processImage];
    [transformLeft addTarget:blendImages];
    
    GPUImageAddBlendFilter *blendImages2 = [[GPUImageAddBlendFilter alloc] init];
    [blendImages addTarget:blendImages2];
    [transformRight addTarget:blendImages2];
    
    [blendImages2 addTarget:uberView];
    
    // Record a movie for 10 s and store it in /Documents, visible via iTunes file sharing
    
    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.m4v"];
    unlink([pathToMovie UTF8String]); // If a file already exists, AVAssetWriter won't let you record new frames, so delete the old movie
    NSURL *movieURL = [NSURL fileURLWithPath:pathToMovie];
    movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(1280.0, 720.0)];
    
    
    __unsafe_unretained typeof(self) weakSelf = self;
    
    movieWriter.completionBlock = ^{
        NSLog(@"in the completion block");
        if (didFinishEffect)
        {
            NSLog(@"already called for this video - ignoring");
        } else
        {
            didFinishEffect = YES;
            NSLog(@"GPU FILTER complete");
            [weakSelf writeMovieToLibraryWithPath:movieURL];
        }
    };
    
    [blendImages2 addTarget:movieWriter];
    
    [videoCamera startCameraCapture];
    
    
     double delayToStartRecording = 0.5;
     dispatch_time_t startTime = dispatch_time(DISPATCH_TIME_NOW, delayToStartRecording * NSEC_PER_SEC);
     dispatch_after(startTime, dispatch_get_main_queue(), ^(void){
     NSLog(@"Start recording");
     
     videoCamera.audioEncodingTarget = movieWriter;
     [movieWriter startRecording];
     
     //        NSError *error = nil;
     //        if (![videoCamera.inputCamera lockForConfiguration:&error])
     //        {
     //            NSLog(@"Error locking for configuration: %@", error);
     //        }
     //        [videoCamera.inputCamera setTorchMode:AVCaptureTorchModeOn];
     //        [videoCamera.inputCamera unlockForConfiguration];
     
     double delayInSeconds = 5.0;
     dispatch_time_t stopTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
     dispatch_after(stopTime, dispatch_get_main_queue(), ^(void){
     
     [blendImages2 removeTarget:movieWriter];
     videoCamera.audioEncodingTarget = nil;
     [movieWriter finishRecording];
     NSLog(@"Movie completed");
     });
     });
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)writeMovieToLibraryWithPath:(NSURL *)path
{
    NSLog(@"writing %@ to library", path);
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library writeVideoAtPathToSavedPhotosAlbum:path
                                completionBlock:^(NSURL *assetURL, NSError *error) {
                                    if (error)
                                    {
                                        NSLog(@"Error saving to library%@", [error localizedDescription]);
                                    } else
                                    {
                                        NSLog(@"SAVED %@ to photo lib",path);
                                    }
                                }];
}


- (BOOL)shouldAutorotate
{
    return YES;
}


- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscapeLeft;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}


- (void)cameraViewTapAction:(UITapGestureRecognizer *)tgr
{
    if (tgr.state == UIGestureRecognizerStateRecognized) {
        CGPoint location = [tgr locationInView:uberView];
        
        AVCaptureDevice *device = videoCamera.inputCamera;
        CGPoint pointOfInterest = CGPointMake(.5f, .5f);
        NSLog(@"taplocation x = %f y = %f", location.x, location.y);
        CGSize frameSize = [uberView frame].size;
        
        if ([videoCamera cameraPosition] == AVCaptureDevicePositionFront) {
            location.x = frameSize.width - location.x;
        }
        
        pointOfInterest = CGPointMake(location.y / frameSize.height, 1.f - (location.x / frameSize.width));
        
        if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            NSError *error;
            if ([device lockForConfiguration:&error]) {
                [device setFocusPointOfInterest:pointOfInterest];
                
                [device setFocusMode:AVCaptureFocusModeAutoFocus];
                
                if([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure])
                {
                    
                    [device setExposurePointOfInterest:pointOfInterest];
                    [device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
                }
                
                [device unlockForConfiguration];
                
                NSLog(@"FOCUS OK");
            } else {
                NSLog(@"ERROR = %@", error);
            }  
        }
    }
}


@end
