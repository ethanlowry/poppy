//
//  LiveViewController.m
//  PoppyApp
//
//  Created by Ethan Lowry on 10/1/13.
//  Copyright (c) 2013 Ethan Lowry. All rights reserved.
//

#import "LiveViewController.h"
#import "RBVolumeButtons.h"

@interface LiveViewController ()

@end

@implementation LiveViewController

bool didFinishEffect = NO;
bool isRecording = NO;
bool isVideo = YES;


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
    // Create a Poppy album if it doesn't already exist
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library addAssetsGroupAlbumWithName:@"Poppy"
                                  resultBlock:^(ALAssetsGroup *group) {
                                      NSLog(@"added album:%@", @"Poppy");
                                  }
                                 failureBlock:^(NSError *error) {
                                     NSLog(@"error adding album");
                                 }];
    
    
    buttonStealer = [[RBVolumeButtons alloc] init];
    buttonStealer.upBlock = ^{
        // + volume button pressed
        NSLog(@"VOLUME UP!");
        if (isVideo) {
            if (isRecording) {
                isRecording = NO;
                [self stopRecording];
            } else {
                isRecording = YES;
                [self startRecording];
            }
        } else {
            [self captureStill];
        }
    };
    buttonStealer.downBlock = ^{
        // - volume button pressed
        NSLog(@"VOLUME DOWN!");
    };
    
    // NOTE: immediately steals volume button events. maybe we want to only do this in landscape mode
    [buttonStealer startStealingVolumeButtonEvents];
}

- (void)viewDidAppear:(BOOL)animated
{
    uberView = (GPUImageView *)self.view;
    
    UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cameraViewTapAction:)];
    [uberView addGestureRecognizer:tgr];
    [self activateCamera];
    [self showToggleButton];

}

- (void)activateCamera
{
    if (isVideo) {
        // video camera setup
        videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionBack];
        videoCamera.outputImageOrientation = UIInterfaceOrientationLandscapeLeft;
        videoCamera.horizontallyMirrorRearFacingCamera = NO;
        [self applyFilters:videoCamera];
        [videoCamera startCameraCapture];
    } else {
        //still camera setup
        stillCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionBack];
        stillCamera.outputImageOrientation = UIInterfaceOrientationLandscapeLeft;
        stillCamera.horizontallyMirrorRearFacingCamera = NO;
        [self applyFilters:stillCamera];
        [stillCamera startCameraCapture];
    }
    [finalFilter addTarget:uberView];
}

- (void)applyFilters:(id)camera
{
    
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
    
    CGRect cropRectLeft = CGRectMake(.2, .15, .3, .7);
    CGRect cropRectRight = CGRectMake(.5, .15, .3, .7);
    
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
    [camera addTarget:filterLeft];
    [filterLeft addTarget:cropLeft];
    [cropLeft addTarget:transformLeft];
    
    [camera addTarget:filterRight];
    [filterRight addTarget:cropRight];
    [cropRight addTarget:transformRight];
    
    [blankImage addTarget:blendImages];
    [blankImage processImage];
    [transformLeft addTarget:blendImages];
    
    finalFilter = [[GPUImageAddBlendFilter alloc] init];
    [blendImages addTarget:finalFilter];
    [transformRight addTarget:finalFilter];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

- (void)showToggleButton
{
    NSLog(@"add the toggle button");
    UIView *viewCaptureMode = [[UIView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - 100, self.view.bounds.size.height - 100, 70, 75)];
    [viewCaptureMode setAutoresizingMask: UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin];
    
    UIView *viewShadow = [[UIView alloc] initWithFrame:CGRectMake(0,0,viewCaptureMode.frame.size.width, viewCaptureMode.frame.size.height)];
    [viewShadow setBackgroundColor:[UIColor blackColor]];
    [viewShadow setAlpha:0.3];
    
    UILabel *labelCaptureMode = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 50, 20)];
    [labelCaptureMode setTag: 100];
    [labelCaptureMode setTextColor:[UIColor whiteColor]];
    [labelCaptureMode setTextAlignment:NSTextAlignmentCenter];
    
    UISwitch *switchCaptureMode = [[UISwitch alloc] initWithFrame:CGRectMake(10, 35, 50, 20)];
    [switchCaptureMode addTarget: self action: @selector(toggleCaptureMode:) forControlEvents:UIControlEventValueChanged];
    
    if(isVideo){
        [labelCaptureMode setText:@"Video"];
        [switchCaptureMode setOn: YES];
    } else {
        [labelCaptureMode setText:@"Photo"];
        [switchCaptureMode setOn: NO];
    }
    
    [viewCaptureMode addSubview: viewShadow];
    [viewCaptureMode addSubview: labelCaptureMode];
    [viewCaptureMode addSubview: switchCaptureMode];
    [self.view addSubview:viewCaptureMode];
    
    [self.view bringSubviewToFront:viewCaptureMode];
    
}

- (void)hideToggleButton
{
    NSLog(@"remove the toggle button");
    [self.view viewWithTag:100];
}

- (IBAction) toggleCaptureMode: (id) sender {
    UISwitch *toggle = (UISwitch *) sender;
    NSLog(@"%@", toggle.on ? @"On" : @"Off");
    UILabel *toggleLabel = (id)[self.view viewWithTag:100];
    isVideo = toggle.on;
    id camera = stillCamera;
    if (toggle.on) {
        [toggleLabel setText: @"Video"];
        
    } else {
        camera = videoCamera;
        [toggleLabel setText: @"Photo"];
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
    ^{
        [camera stopCameraCapture];
        [self activateCamera];
    });
}

- (void)captureStill
{
    NSLog(@"CAPTURING STILL");
    [stillCamera capturePhotoAsJPEGProcessedUpToFilter:finalFilter withCompletionHandler:^(NSData *processedJPEG, NSError *error){
        
        // Save to assets library
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        
        [library writeImageDataToSavedPhotosAlbum:processedJPEG metadata:stillCamera.currentCaptureMetadata completionBlock:^(NSURL *assetURL, NSError *error2)
         {
             if (error2) {
                 NSLog(@"ERROR: the image failed to be written");
             }
             else {
                 NSLog(@"PHOTO SAVED - assetURL: %@", assetURL);
                 [library enumerateGroupsWithTypes:ALAssetsGroupAlbum
                                      usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                                            if ([[group valueForProperty:ALAssetsGroupPropertyName] isEqualToString:@"Poppy"]) {
                                                NSLog(@"found album %@", @"Poppy");
                                                // Now assign the image to the Poppy album
                                                
                                                
                                                [library assetForURL:assetURL
                                                              resultBlock:^(ALAsset *asset) {
                                                                  // assign the photo to the album
                                                                  [group addAsset:asset];
                                                                  NSLog(@"Added %@ to %@", [[asset defaultRepresentation] filename], [group valueForProperty:ALAssetsGroupPropertyName]);
                                                              }
                                                             failureBlock:^(NSError* error) {
                                                                 NSLog(@"failed to retrieve image asset:\nError: %@ ", [error localizedDescription]);
                                                             }];
                                            }
                                        }
                                      failureBlock:^(NSError* error) {
                                          NSLog(@"failed to enumerate albums:\nError: %@", [error localizedDescription]);
                                      }];
             }
             
             runOnMainQueueWithoutDeadlocking(^{
                 //[photoCaptureButton setEnabled:YES];
             });
         }];
    }];
}

- (void)startRecording
{
    didFinishEffect = NO;
    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.m4v"];
    unlink([pathToMovie UTF8String]); // If a file already exists, AVAssetWriter won't let you record new frames, so delete the old movie
    NSURL *movieURL = [NSURL fileURLWithPath:pathToMovie];
    movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(1280.0, 720.0)];
    
    
    //__unsafe_unretained typeof(self) weakSelf = self;
    
    movieWriter.completionBlock = ^{
        NSLog(@"in the completion block");
        if (didFinishEffect)
        {
            NSLog(@"already called for this video - ignoring");
        } else
        {
            didFinishEffect = YES;
            NSLog(@"GPU FILTER complete");
            [self writeMovieToLibraryWithPath:movieURL];
        }
    };
    
    [finalFilter addTarget:movieWriter];
    
    //double delayToStartRecording = 0.1;
    //dispatch_time_t startTime = dispatch_time(DISPATCH_TIME_NOW, delayToStartRecording * NSEC_PER_SEC);
    
    dispatch_async(dispatch_get_main_queue(),
       ^{
           NSLog(@"Start recording");
           
           videoCamera.audioEncodingTarget = movieWriter;
           [movieWriter startRecording];
       });
    
    
    //dispatch_after(startTime, dispatch_get_main_queue(), ^(void){
    //    NSLog(@"Start recording");
    
    //    videoCamera.audioEncodingTarget = movieWriter;
    //    [movieWriter startRecording];
        
        //        NSError *error = nil;
        //        if (![videoCamera.inputCamera lockForConfiguration:&error])
        //        {
        //            NSLog(@"Error locking for configuration: %@", error);
        //        }
        //        [videoCamera.inputCamera setTorchMode:AVCaptureTorchModeOn];
        //        [videoCamera.inputCamera unlockForConfiguration];

    //});
}

-(void)stopRecording
{
    videoCamera.audioEncodingTarget = nil;
    [finalFilter removeTarget:movieWriter];
    [movieWriter finishRecording];
    NSLog(@"Movie completed");
}


- (void)cameraViewTapAction:(UITapGestureRecognizer *)tgr
{
    if (tgr.state == UIGestureRecognizerStateRecognized) {
        
        CGPoint location = [tgr locationInView:uberView];
        
        if (isVideo) {
            device = videoCamera.inputCamera;
        } else {
            device = stillCamera.inputCamera;
        }
        
        CGPoint pointOfInterest = CGPointMake(.5f, .5f);
        NSLog(@"taplocation x = %f y = %f", location.x, location.y);
        CGSize frameSize = [uberView frame].size;
        
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
                                        [library enumerateGroupsWithTypes:ALAssetsGroupAlbum
                                                               usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                                                                   if ([[group valueForProperty:ALAssetsGroupPropertyName] isEqualToString:@"Poppy"]) {
                                                                       NSLog(@"found album %@", @"Poppy");
                                                                       // Now assign the image to the Poppy album
                                                                       
                                                                       
                                                                       [library assetForURL:assetURL
                                                                                resultBlock:^(ALAsset *asset) {
                                                                                    // assign the photo to the album
                                                                                    [group addAsset:asset];
                                                                                    NSLog(@"Added %@ to %@", [[asset defaultRepresentation] filename], [group valueForProperty:ALAssetsGroupPropertyName]);
                                                                                }
                                                                               failureBlock:^(NSError* error) {
                                                                                   NSLog(@"failed to retrieve image asset:\nError: %@ ", [error localizedDescription]);
                                                                               }];
                                                                   }
                                                               }
                                                             failureBlock:^(NSError* error) {
                                                                 NSLog(@"failed to enumerate albums:\nError: %@", [error localizedDescription]);
                                                             }];

                                    }
                                }];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft);
}

@end
