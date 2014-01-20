//
//  LiveViewController.m
//  PoppyApp
//
//  Created by Ethan Lowry on 10/1/13.
//  Copyright (c) 2013 Ethan Lowry. All rights reserved.
//

// TAGGED VIEWS:
// 103 = the movie player view
// 105 = the "no media available" label view
// 107 = the "welcome" label view

#import "LiveViewController.h"
#import "GalleryViewController.h"
#import "AppDelegate.h"
#import <sys/utsname.h>


CATransform3D CATransform3DRotatedWithPerspectiveFactor(double factor) {
    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = fabs(factor);
    return CATransform3DRotate(transform, factor, 0.0, 1.0, 0.0);
}


@interface LiveViewController ()
@end

@implementation LiveViewController

@synthesize isViewActive;
@synthesize xOffset;
@synthesize calibrateFirst;

@synthesize mainMoviePlayer;
@synthesize videoCamera;
@synthesize stillCamera;
@synthesize movieWriter;
@synthesize uberView;
@synthesize imgView;
@synthesize galleryWebView;
@synthesize finalFilter;
@synthesize displayFilter;
@synthesize viewDeleteAlert;

@synthesize viewCameraControls;
@synthesize buttonShutter;
@synthesize viewSaving;
@synthesize isWatching;
@synthesize viewViewerControls;

int next = 1;
int prev = -1;
BOOL directionNext;

float cropFactor = 0.7;
float perspectiveFactor = 0.267;

bool didFinishEffect = NO;
bool isRecording = NO;
bool isVideo = NO;
bool isSaving = NO;
bool ignoreVolumeDown = NO;
bool isViewActive;

NSTimer *timerDimmer;
ALAssetsGroup *assetsGroup;
ALAssetsLibrary *assetLibrary;

UIImageView *imgFocusSquare;

UIView *demoClearView;

SystemSoundID videoBeep;


int currentIndex = -1;


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
    if (!assetLibrary) {
        assetLibrary = [[ALAssetsLibrary alloc] init];
        [assetLibrary addAssetsGroupAlbumWithName:@"Poppy"
                                      resultBlock:^(ALAssetsGroup *group) {
                                          if (group) {
                                              NSLog(@"added album:%@", [group valueForProperty:ALAssetsGroupPropertyName]);
                                          } else {
                                              NSLog(@"no group created, probably because it already exists");
                                          }
                                          [self loadAlbumWithName:@"Poppy"];
                                      }
                                     failureBlock:^(NSError *error) {
                                         NSLog(@"error adding album");
                                     }];
    }
    
    xOffset = [[NSUserDefaults standardUserDefaults] floatForKey:@"xOffset"];
    NSLog(@"xOffset: %f", xOffset);
    
    [self.view setBackgroundColor:[UIColor darkGrayColor]];
}

- (void) shutterPressed
{
    NSLog(@"SHUTTER PRESSED");
    currentIndex = -1;
    if (isWatching) {
        [self hideViewer];
        [self showCameraControls];
    } else {
        if (isVideo) {
            if (isRecording) {
                [self stopRecording];
            } else {
                if(!isSaving) {
                    [self startRecording];
                }
            }
        } else {
            if(!isSaving) {
                [self captureStill];
            }
        }
    }
}

- (void) shutterButtonPressed: (id) sender
{
    NSLog(@"ON SCREEN SHUTTER BUTTON PRESSED");
    [self showCameraControls];
    //[[MPMusicPlayerController applicationMusicPlayer] setVolume:1.0]; // this uses the volume button stealer as the trigger
    buttonStealer.upBlock();
}

- (void)hideViewer
{
    // clear away the view mode UI
    isWatching = NO;
    [imgView setHidden:YES];
    [galleryWebView removeFromSuperview];
    galleryWebView = nil;
    [self.mainMoviePlayer stop];
    self.mainMoviePlayer = nil;
    currentIndex = -1;
    
    [[self.view viewWithTag:103] removeFromSuperview]; //remove the movie player
    [viewViewerControls removeFromSuperview]; //remove the camera button
    [demoClearView removeFromSuperview];
    demoClearView = nil;
}

- (void)activateView
{
    if (!buttonStealer) {
        [self activateButtonStealer];
    } else {
        [buttonStealer startStealingVolumeButtonEvents];
    }
    
    if (!imgView) {
        imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.height, self.view.frame.size.width)];
        [imgView setContentMode: UIViewContentModeScaleAspectFill];
        
        [self.view addSubview:imgView];
    }
    
    if (!uberView) {
        uberView = (GPUImageView *)self.view;
        uberView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
    }
    
    // set crop factor based on device
    cropFactor = [self setCropFactor];
    
    // set up gestures
    UIView *touchView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.height, self.view.frame.size.width)];
    [self addGestures:touchView];
    [self.view addSubview:touchView];
    
    [self activateCamera];
    
    if (!videoBeep) {
        NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"beep" ofType:@"wav"];
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)([NSURL fileURLWithPath: soundPath]), &videoBeep);
    }
}

- (void)activateButtonStealer
{
    __weak typeof(self) weakSelf = self;
    buttonStealer = [[RBVolumeButtons alloc] init];
    buttonStealer.upBlock = ^{
        // + volume button pressed
        if (!ignoreVolumeDown) {
            NSLog(@"VOLUME UP!");
            [weakSelf shutterPressed];
        }
    };
    buttonStealer.downBlock = ^{
        // - volume button pressed
        
         if (!ignoreVolumeDown) {
         NSLog(@"VOLUME DOWN!");
         [weakSelf showMedia:prev];
         }
    };
    
    [buttonStealer startStealingVolumeButtonEvents];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self activateView];
    if (isWatching) {
        NSLog(@"RETURNING TO THE VIEWER");
        imgView.image = nil;
        [buttonStealer startStealingVolumeButtonEvents];
        [self switchToViewerMode:self];
    } else {
        [self showCameraControls];
    }
}

- (void)addGestures:(UIView *)touchView
{
    UITapGestureRecognizer *handleDoubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTapAction:)];
    handleDoubleTap.numberOfTapsRequired = 2;
    [touchView addGestureRecognizer:handleDoubleTap];
    
    UITapGestureRecognizer *handleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapAction:)];
    handleTap.numberOfTapsRequired = 1;
    [touchView addGestureRecognizer:handleTap];
    
    UISwipeGestureRecognizer *swipeLeftGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeScreenleft:)];
    swipeLeftGesture.numberOfTouchesRequired = 1;
    swipeLeftGesture.direction = (UISwipeGestureRecognizerDirectionLeft);
    [touchView addGestureRecognizer:swipeLeftGesture];
    
    UISwipeGestureRecognizer *swipeRightGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeScreenRight:)];
    swipeRightGesture.numberOfTouchesRequired = 1;
    swipeRightGesture.direction = (UISwipeGestureRecognizerDirectionRight);
    [touchView addGestureRecognizer:swipeRightGesture];
}


- (void)showMedia:(int)direction
{
    // show image or play video
    int assetCount = [assetsGroup numberOfAssets];
    NSLog(@"album count %d", assetCount);
    if (assetCount > 0) {
        if (!isWatching) {
            isWatching = YES; // we're in view mode, not capture mode
            [self showViewerControls];
            //tear down everything about capture mode
            [videoCamera stopCameraCapture];
            self.videoCamera = nil;
            [stillCamera stopCameraCapture];
            self.stillCamera = nil;
            [finalFilter removeAllTargets];
            [displayFilter removeAllTargets];
            [self hideView:viewCameraControls];
        }
        
        [mainMoviePlayer stop];
        [[self.view viewWithTag:103] removeFromSuperview];
        
        if (direction == prev) {
            directionNext = NO;
            if (currentIndex > 0) {
                currentIndex = currentIndex - 1;
            } else {
                currentIndex = assetCount - 1;
            }
        } else {
            directionNext = YES;
            if (currentIndex < assetCount - 1) {
                currentIndex = currentIndex + 1;
            } else {
                currentIndex = 0;
            }
        }
        
        UIImage *tempImage = imgView.image;
        [imgView setImage:nil];
        
        [assetsGroup enumerateAssetsAtIndexes:[NSIndexSet indexSetWithIndex:currentIndex] options:0 usingBlock: ^(ALAsset *asset, NSUInteger index, BOOL *stop)
             {
                 if (asset) {
                     NSLog(@"got the asset: %d", index);
                     ALAssetRepresentation *assetRepresentation = [asset defaultRepresentation];
                     UIImageOrientation orientation = UIImageOrientationUp;
                     NSNumber* orientationValue = [asset valueForProperty:@"ALAssetPropertyOrientation"];
                     if (orientationValue != nil) {
                         orientation = [orientationValue intValue];
                     }
                     UIImage *fullScreenImage = [UIImage imageWithCGImage:[assetRepresentation fullScreenImage] scale:[assetRepresentation scale] orientation:orientation];
                     NSLog(@"image stuff, wide: %f height: %f", fullScreenImage.size.width, fullScreenImage.size.height);
                     
                     // Animate the appearance of the next/prev image
                     /*
                     float xPosition = directionNext ? imgView.frame.size.width : -imgView.frame.size.width;
                     UIImageView *animatedImgView = [[UIImageView alloc] initWithFrame:CGRectMake(xPosition, 0, imgView.frame.size.width, imgView.frame.size.height)];
                     [animatedImgView setImage:fullScreenImage];
                     [animatedImgView setContentMode:UIViewContentModeScaleAspectFill];
                     [self.view addSubview:animatedImgView];
                     CGRect finalFrame = animatedImgView.frame;
                     finalFrame.origin.x = 0;
                     [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{ animatedImgView.frame = finalFrame; }
                         completion:^(BOOL finished){
                             [imgView setImage:fullScreenImage];
                             [imgView setHidden:NO];
                             [animatedImgView removeFromSuperview];
                             if ([asset valueForProperty:ALAssetPropertyType] == ALAssetTypeVideo) {
                                 [self playMovie:asset];
                         }
                     }];
                      */
                     
                     [imgView setImage:fullScreenImage];
                     [imgView setHidden:NO];
                     
                     if ([asset valueForProperty:ALAssetPropertyType] == ALAssetTypeVideo) {
                         [self playMovie:asset];
                     }
                     
                     // Animate the old image away
                     if (tempImage) {
                         float xPosition = directionNext ? -imgView.frame.size.width : imgView.frame.size.width;
                         UIImageView *animatedImgView = [[UIImageView alloc] initWithFrame:imgView.frame];
                         [animatedImgView setImage:tempImage];
                         [animatedImgView setContentMode:UIViewContentModeScaleAspectFill];
                         [self.view addSubview:animatedImgView];
                         
                         CGRect finalFrame = animatedImgView.frame;
                         finalFrame.origin.x = xPosition;
                         [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{ animatedImgView.frame = finalFrame; } completion:^(BOOL finished){
                             [animatedImgView removeFromSuperview];

                         }];
                     }

                     *stop = YES;
                 }
             }];
        NSLog(@"GOT HERE");
        [self showViewerControls];
    } else {
        NSLog(@"NO IMAGES IN THE ALBUM");
        [self showNoMediaAlert];
        //UNCOMMENT THE NEXT LINE FOR SIMULATOR TESTING PURPOSES ONLY. SHOW VIEWERCONTROLS EVEN WHEN THERE ARE NO PHOTOS
        //[self showViewerControls];
    }

}

- (void)showNoMediaAlert
{
    UIView *viewNoMedia = [[UIView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width/2, (self.view.bounds.size.height - 150)/2, self.view.bounds.size.width/2, 75)];
    [viewNoMedia setAutoresizingMask: UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin];
    [viewNoMedia setTag:105];
    
    UIView *viewShadow = [[UIView alloc] initWithFrame:CGRectMake(0,0,viewNoMedia.frame.size.width, viewNoMedia.frame.size.height)];
    [viewShadow setBackgroundColor:[UIColor blackColor]];
    [viewShadow setAlpha:0.3];
    
    UILabel *labelNoMedia = [[UILabel alloc] initWithFrame:CGRectMake(0,0,viewNoMedia.frame.size.width, viewNoMedia.frame.size.height)];
    [labelNoMedia setTextColor:[UIColor whiteColor]];
    [labelNoMedia setBackgroundColor:[UIColor clearColor]];
    [labelNoMedia setTextAlignment:NSTextAlignmentCenter];
    [labelNoMedia setText:@"Nothing to play!"];
    
    [viewNoMedia addSubview:viewShadow];
    [viewNoMedia addSubview:labelNoMedia];
    
    [self.view addSubview:viewNoMedia];
    
    [UIView animateWithDuration:0.5 delay:0.0
                        options: (UIViewAnimationOptionCurveEaseInOut & UIViewAnimationOptionBeginFromCurrentState)
                     animations:^{
                         viewNoMedia.alpha = 1.0;
                     }
                     completion:^(BOOL complete){
                         [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(noMediaTimerFired:) userInfo:nil repeats:NO];
                     }];
}

- (void)noMediaTimerFired:(NSTimer *)timer
{
    UIView *noMediaView = [self.view viewWithTag:105];
    [UIView animateWithDuration:0.5 delay:0.0
                        options: (UIViewAnimationOptionCurveEaseInOut & UIViewAnimationOptionBeginFromCurrentState)
                     animations:^{
                         noMediaView.alpha = 0.0;
                     }
                     completion:^(BOOL complete){
                         [noMediaView removeFromSuperview];
                     }];
}

- (void)loadAlbumWithName:(NSString *)name
{
    [assetLibrary enumerateGroupsWithTypes:ALAssetsGroupAlbum
                                usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                                    if ([[group valueForProperty:ALAssetsGroupPropertyName] isEqualToString:name]) {
                                        NSLog(@"found album %@", [group valueForProperty:ALAssetsGroupPropertyName]);
                                        assetsGroup = group;
                                        NSLog(@"assetGroup is now %@", [assetsGroup valueForProperty:ALAssetsGroupPropertyName]);
                                     }
                                }
                              failureBlock:^(NSError* error) {
                                  NSLog(@"failed to enumerate albums:\nError: %@", [error localizedDescription]);
                              }];
}

- (void)playMovie:(ALAsset*)asset {
    mainMoviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:[[asset defaultRepresentation] url]];
    mainMoviePlayer.shouldAutoplay=YES;
    mainMoviePlayer.controlStyle = MPMovieControlStyleNone;
    [mainMoviePlayer setMovieSourceType: MPMovieSourceTypeFile];
    [mainMoviePlayer setFullscreen:YES animated:YES];
    [mainMoviePlayer prepareToPlay];
    [mainMoviePlayer.view setFrame: CGRectMake(0, 0, self.view.frame.size.height, self.view.frame.size.width)];
    [mainMoviePlayer setScalingMode:MPMovieScalingModeAspectFill];
    [mainMoviePlayer.view setTag:103];
    [self.view addSubview: mainMoviePlayer.view];
    mainMoviePlayer.repeatMode = MPMovieRepeatModeOne;
    [mainMoviePlayer play];
    
    //now add gesture controls
    UIView *touchView = [[UIView alloc] initWithFrame:mainMoviePlayer.view.bounds];
    [self addGestures:touchView];
    [mainMoviePlayer.view addSubview:touchView];
    
    [self.view bringSubviewToFront:viewViewerControls];
}

- (void)moviePlayBackDidFinish:(id)sender {
    NSLog(@"Movie playback finished");
    [mainMoviePlayer stop];
    [[self.view viewWithTag:103] removeFromSuperview];
}


- (void)activateCamera
{
    if (isVideo) {
        NSLog(@"VIDEO");
        // video camera setup
        if ([self deviceModelNumber] == 40) {
            videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPresetiFrame960x540 cameraPosition:AVCaptureDevicePositionBack];
        } else {
            videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionBack];
        }
        videoCamera.outputImageOrientation = UIInterfaceOrientationLandscapeLeft;
        videoCamera.horizontallyMirrorRearFacingCamera = NO;
        [self showFilteredDisplay:videoCamera];
    } else {
        NSLog(@"STILL");
        //still camera setup
        if ([self deviceModelNumber] == 40) {
            stillCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPresetiFrame960x540 cameraPosition:AVCaptureDevicePositionBack];
        } else if ([self deviceModelNumber] == 41) {
            stillCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720  cameraPosition:AVCaptureDevicePositionBack];
        } else {
            stillCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPresetPhoto  cameraPosition:AVCaptureDevicePositionBack];
        }

        stillCamera.outputImageOrientation = UIInterfaceOrientationLandscapeLeft;
        stillCamera.horizontallyMirrorRearFacingCamera = NO;
        [self showFilteredDisplay:stillCamera];
    }
}

- (void)showFilteredDisplay:(id)camera
{

    CGRect finalCropRect;
//    if([camera isKindOfClass:[GPUImageStillCamera class]] && [self deviceModelNumber] == 41) {
//        finalCropRect = CGRectMake(xOffset + (1.0 - cropFactor)/2, (1.0 - cropFactor)/2 + cropFactor * .175, cropFactor, cropFactor * .65);
//    } else {
        finalCropRect = CGRectMake(xOffset + (1.0 - cropFactor)/2, (1.0 - cropFactor)/2, cropFactor, cropFactor);
//    }
    
    displayFilter = [[GPUImageCropFilter alloc] initWithCropRegion:finalCropRect];
    [camera addTarget:displayFilter];
    [displayFilter addTarget:uberView];
    [camera startCameraCapture];
}

- (void)applyFilters:(id)camera
{
    @autoreleasepool {
        CGRect finalCropRect;
//        if([camera isKindOfClass:[GPUImageStillCamera class]] && [self deviceModelNumber] == 41) {
//            finalCropRect = CGRectMake((1.0 - cropFactor)/2, (1.0 - cropFactor)/2 + cropFactor * .175, cropFactor, cropFactor * .65);
//        } else {
            finalCropRect = CGRectMake((1.0 - cropFactor)/2, (1.0 - cropFactor)/2, cropFactor, cropFactor);
//        }
        
        finalFilter = [[GPUImageCropFilter alloc] initWithCropRegion:finalCropRect];
        
        GPUImageFilter *initialFilter = [[GPUImageFilter alloc] init];
        GPUImageCropFilter *cropLeft;
        GPUImageCropFilter *cropRight;
        
        //if([camera isKindOfClass:[GPUImageStillCamera class]] && [self deviceModelNumber] == 41) {
        //    NSLog(@"still output for iPhone 4S");
        //    //[initialFilter forceProcessingAtSize:CGSizeMake(1920, 1440)];
        //}

        // SPLIT THE IMAGE IN HALF
        //take into account the xOffset
        NSLog(@"XOFFSET: %f", xOffset);
        
        float frameWidth = 0.5 - fabs(xOffset);
        if (xOffset > 0) {
            cropLeft = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0.0, 0.0, frameWidth, 1.0)];
        } else {
            cropLeft = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0.0 - 2*xOffset, 0.0, frameWidth, 1.0)];
        }
        cropRight = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0.5 - xOffset, 0.0, frameWidth, 1.0)];
        // SKEW THE IMAGE FROM BOTH A LEFT AND RIGHT PERSPECTIVE
        GPUImageTransformFilter *filterLeft = [[GPUImageTransformFilter alloc] init];
        filterLeft.transform3D = CATransform3DRotatedWithPerspectiveFactor(perspectiveFactor);
        GPUImageTransformFilter *filterRight = [[GPUImageTransformFilter alloc] init];
        filterRight.transform3D = CATransform3DRotatedWithPerspectiveFactor(-perspectiveFactor);
        
        //SHIFT THE LEFT AND RIGHT HALVES OVER SO THAT THEY CAN BE OVERLAID
        CGAffineTransform landscapeTransformLeft = CGAffineTransformTranslate (CGAffineTransformScale(CGAffineTransformIdentity, frameWidth, 1.0), -1.0, 0.0);
        GPUImageTransformFilter *transformLeft = [[GPUImageTransformFilter alloc] init];
        transformLeft.affineTransform = landscapeTransformLeft;
        
        CGAffineTransform landscapeTransformRight = CGAffineTransformTranslate (CGAffineTransformScale(CGAffineTransformIdentity, frameWidth, 1.0), 1.0, 0.0);
        GPUImageTransformFilter *transformRight = [[GPUImageTransformFilter alloc] init];
        transformRight.affineTransform = landscapeTransformRight;
        
        // BLEND FIRST WITH A BLANK IMAGE, THEN WITH THE RIGHT HALF
        GPUImageBrightnessFilter *blankFilter = [[GPUImageBrightnessFilter alloc] init];
        blankFilter.brightness = -1.0;
        GPUImageAddBlendFilter *blendImages = [[GPUImageAddBlendFilter alloc] init];
        GPUImageAddBlendFilter *finalBlend = [[GPUImageAddBlendFilter alloc] init];
        
        //FILTER CHAIN: STACK ALL THESE FILTERS TOGETHER
        
        [camera addTarget:initialFilter];
        [initialFilter addTarget:cropLeft];
        [initialFilter addTarget:cropRight];
        
        [cropLeft addTarget:filterLeft];
        [filterLeft addTarget:transformLeft];
        [cropRight addTarget:filterRight];
        [filterRight addTarget:transformRight];
        
        [initialFilter addTarget:blankFilter];
        [blankFilter addTarget:blendImages];
        
        //[transformRight addTarget:blendImages];
        [transformLeft addTarget:blendImages];
        
        [blendImages addTarget:finalBlend];
        [transformRight addTarget:finalBlend];
         
        [finalBlend addTarget:finalFilter];
        //[blendImages addTarget:finalFilter];
    }
}

- (float)setCropFactor
{
    NSLog(@"MODEL: %i", [self deviceModelNumber]);
    int phoneModel = [self deviceModelNumber];
    float modelCropFactor;
    
    switch (phoneModel) {
        case 40:
            modelCropFactor = 0.8;
            break;
        case 41:
            modelCropFactor = 0.8;
            break;
        case 50:
            modelCropFactor = 0.7;
            break;
        case 51:
            modelCropFactor = 0.7;
            break;
        case 52:
            modelCropFactor = 0.7;
            break;
        case 99:
            modelCropFactor = 0.8;
            break;
        default:
            modelCropFactor = 0.7;
            break;
    }
    return modelCropFactor;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    AppDelegate *poppyAppDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [poppyAppDelegate.imageCache removeAllObjects];
    
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

- (void) showCameraControls
{
    if (!(stillCamera || videoCamera)){
        [self activateCamera];
    }
    
    isWatching = NO;
    NSLog(@"show camera controls");
    
    if (!viewCameraControls)
    {
        // add the camera control buttons
        viewCameraControls = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 75, self.view.bounds.size.width, 75)];
        
        [self addCameraControlsContentWithView:viewCameraControls];
        
        [self.view addSubview:viewCameraControls];
    } else {
        NSLog(@"FOO!");
        [self setShutterButtonImage];
    }
    [self.view bringSubviewToFront:viewCameraControls];
    [self dimView:0.5 withAlpha:1.0 withView:viewCameraControls withTimer:YES];
}

- (void) setShutterButtonImage
{
    if(isVideo) {
        if(isRecording) {
            [buttonShutter setImage:[UIImage imageNamed:@"shutter_recording"] forState:UIControlStateNormal];
        } else {
            [buttonShutter setImage:[UIImage imageNamed:@"shutter_video"] forState:UIControlStateNormal];
        }
    } else {
        [buttonShutter setImage:[UIImage imageNamed:@"shutter"] forState:UIControlStateNormal];
    }
}

- (void) addCameraControlsContentWithView:(UIView *)viewContainer
{
    UIView *controlsView = [[UIView alloc] initWithFrame:CGRectMake(viewContainer.frame.size.width/2, viewContainer.bounds.size.height - 75, viewContainer.bounds.size.width/2, 75)];
    
    UIView *viewShadow = [[UIView alloc] initWithFrame:CGRectMake(0,0,controlsView.frame.size.width, controlsView.frame.size.height)];
    [viewShadow setBackgroundColor:[UIColor blackColor]];
    [viewShadow setAlpha:0.3];
    [self addGestures:viewShadow];
    
    UITapGestureRecognizer *handleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleShadowTapAction:)];
    [viewShadow addGestureRecognizer:handleTap];
    [controlsView addSubview: viewShadow];

    UIButton *buttonToggleMode = [[UIButton alloc] initWithFrame: CGRectMake(controlsView.frame.size.width - 230, 0, 70, 75)];
    
    [self setCameraButtonIcon:buttonToggleMode];

    [buttonToggleMode addTarget:self action:@selector(toggleCaptureMode:) forControlEvents:UIControlEventTouchUpInside];
    [controlsView addSubview: buttonToggleMode];
    
    UIButton *buttonHome = [[UIButton alloc] initWithFrame: CGRectMake(controlsView.frame.size.width - 70, 0, 70, 75)];
    [buttonHome setImage:[UIImage imageNamed:@"home"] forState:UIControlStateNormal];
    [buttonHome addTarget:self action:@selector(goHome) forControlEvents:UIControlEventTouchUpInside];
    [controlsView addSubview: buttonHome];
    
    // add the shutter button
    NSLog(@"adding the shutter button");
    buttonShutter = [[UIButton alloc] initWithFrame: CGRectMake(controlsView.frame.size.width - 150, 0, 70, 75)];
    [buttonShutter setImage:[UIImage imageNamed:@"shutterPressed"] forState:UIControlStateHighlighted];
    [self setShutterButtonImage];
    [buttonShutter addTarget:self action:@selector(shutterButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [controlsView addSubview: buttonShutter];
    
    [viewContainer addSubview: controlsView];
}

- (void) goHome
{
    //TO DO: Fix this ugly, hacky way to clear away everything
    self.uberView = nil;
    self.imgView = nil;
    [self hideViewer];
    if (isRecording) {
        [self stopRecording];
    }
    id camera = isVideo ? videoCamera : stillCamera;
    [camera stopCameraCapture];
    
    [displayFilter removeAllTargets];
    [finalFilter removeAllTargets];
    self.displayFilter = nil;
    self.finalFilter = nil;
    
    self.stillCamera = nil;
    self.videoCamera = nil;
    
    [buttonStealer stopStealingVolumeButtonEvents];
    buttonStealer = nil;
    [self dismissViewControllerAnimated:YES completion:^{}];
}

- (void) showViewerControls
{
    NSLog(@"show viewer controls");
    
    if (isRecording) {
        [self stopRecording];
    }
    
    if (!viewViewerControls)
    {
        viewViewerControls = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 75, self.view.bounds.size.width, self.view.bounds.size.height)];
        [viewViewerControls setAutoresizingMask: UIViewAutoresizingFlexibleTopMargin];
        [self addViewerControlsContentWithView:viewViewerControls];
        [self.view addSubview:viewViewerControls];
    }
    [self hideView:viewCameraControls];
    [self.view bringSubviewToFront:viewViewerControls];
    [self dimView:0.5 withAlpha:1.0 withView:viewViewerControls withTimer:YES];
}

- (void) addViewerControlsContentWithView:(UIView *)viewContainer
{
    UIView *controlsView = [[UIView alloc] initWithFrame:CGRectMake(viewContainer.bounds.size.width/2, 0, viewContainer.bounds.size.width/2, 75)];
    
    UIView *viewShadow = [[UIView alloc] initWithFrame:CGRectMake(0,0,controlsView.frame.size.width,75)];
    [viewShadow setBackgroundColor:[UIColor blackColor]];
    [viewShadow setAlpha:0.3];
    [self addGestures:viewShadow];
    
    UIButton *buttonHome = [[UIButton alloc] initWithFrame: CGRectMake(controlsView.frame.size.width - 70,0,70,75)];
    [buttonHome setImage:[UIImage imageNamed:@"home"] forState:UIControlStateNormal];
    [buttonHome addTarget:self action:@selector(goHome) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *buttonDelete = [[UIButton alloc] initWithFrame: CGRectMake(controlsView.frame.size.width - 230,0,70,75)];
    [buttonDelete setImage:[UIImage imageNamed:@"trash"] forState:UIControlStateNormal];
    [buttonDelete addTarget:self action:@selector(showDeleteAssetAlert) forControlEvents:UIControlEventTouchUpInside];
    
    [controlsView addSubview: viewShadow];
    [controlsView addSubview: buttonHome];
    [controlsView addSubview: buttonDelete];
    [viewContainer addSubview:controlsView];
}

- (void)showDeleteAssetAlert
{
    if(assetsGroup.numberOfAssets > 0) {
        if (!viewDeleteAlert) {
            viewDeleteAlert = [[UIView alloc] initWithFrame:self.view.bounds];
            [viewDeleteAlert setAutoresizingMask: UIViewAutoresizingFlexibleTopMargin];
            
            UIView *viewShadow = [[UIView alloc] initWithFrame:self.view.bounds];
            viewShadow.backgroundColor = [UIColor blackColor];
            viewShadow.alpha = 0.3;
            UITapGestureRecognizer *handleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissDeleteAlert)];
            [viewShadow addGestureRecognizer:handleTap];
            [viewDeleteAlert addSubview:viewShadow];
            
            UILabel *deleteLabel = [[UILabel alloc] initWithFrame:CGRectMake(viewDeleteAlert.frame.size.width/2,(viewDeleteAlert.frame.size.height - 120)/2,viewDeleteAlert.frame.size.width/2,60)];
            [deleteLabel setTextAlignment:NSTextAlignmentCenter];
            [deleteLabel setBackgroundColor:[UIColor blackColor]];
            [deleteLabel setTextColor:[UIColor whiteColor]];
            CALayer *bottomBorder = [CALayer layer];
            bottomBorder.frame = CGRectMake(40, 59, deleteLabel.frame.size.width-80, 1.0);
            bottomBorder.backgroundColor = [UIColor whiteColor].CGColor;
            [deleteLabel.layer addSublayer:bottomBorder];
            
            [viewDeleteAlert addSubview:deleteLabel];
            [assetsGroup enumerateAssetsAtIndexes:[NSIndexSet indexSetWithIndex:currentIndex] options:0 usingBlock: ^(ALAsset *asset, NSUInteger index, BOOL *stop) {
                if (asset) {
                    if (asset.editable) {
                        [deleteLabel setText: @"Delete this photo?"];
                        UIButton *buttonConfirmDelete = [[UIButton alloc] initWithFrame:CGRectMake(viewDeleteAlert.frame.size.width/2,viewDeleteAlert.frame.size.height/2, viewDeleteAlert.frame.size.width/4, 60)];
                        [buttonConfirmDelete setTitle:@"Delete" forState:UIControlStateNormal];
                        [buttonConfirmDelete addTarget:self action:@selector(deleteAsset) forControlEvents:UIControlEventTouchUpInside];
                        //[buttonConfirmDelete.titleLabel setTextAlignment:NSTextAlignmentLeft];
                        [buttonConfirmDelete setBackgroundColor:[UIColor blackColor]];
                        [viewDeleteAlert addSubview:buttonConfirmDelete];
                        
                        UIButton *buttonCancelDelete = [[UIButton alloc] initWithFrame:CGRectMake(viewDeleteAlert.frame.size.width*3/4, viewDeleteAlert.frame.size.height/2, viewDeleteAlert.frame.size.width/4, 60)];
                        [buttonCancelDelete setTitle:@"Cancel" forState:UIControlStateNormal];
                        [buttonCancelDelete addTarget:self action:@selector(dismissDeleteAlert) forControlEvents:UIControlEventTouchUpInside];
                        //[buttonCancelDelete.titleLabel setTextAlignment:NSTextAlignmentRight];
                        [buttonCancelDelete setBackgroundColor:[UIColor blackColor]];
                        [viewDeleteAlert addSubview:buttonCancelDelete];
                        *stop = YES;
                    } else {
                        [deleteLabel setText: @"This photo can't be deleted"];
                        UIButton *buttonCancelDelete = [[UIButton alloc] initWithFrame:CGRectMake(viewDeleteAlert.frame.size.width/2, viewDeleteAlert.frame.size.height/2, viewDeleteAlert.frame.size.width/2, 60)];
                        [buttonCancelDelete setTitle:@"Dismiss" forState:UIControlStateNormal];
                        [buttonCancelDelete addTarget:self action:@selector(dismissDeleteAlert) forControlEvents:UIControlEventTouchUpInside];
                        [buttonCancelDelete.titleLabel setTextAlignment:NSTextAlignmentRight];
                        [buttonCancelDelete setBackgroundColor:[UIColor blackColor]];
                        [viewDeleteAlert addSubview:buttonCancelDelete];
                    }
                }
            }];
        }

        [self.view addSubview:viewDeleteAlert];
        [self.view bringSubviewToFront:viewDeleteAlert];
    }
}

- (void)dismissDeleteAlert
{
    [viewDeleteAlert removeFromSuperview];
    viewDeleteAlert = nil;
}

- (void)deleteAsset
{
    NSLog(@"DELETE!!");
    [self dismissDeleteAlert];
    [assetsGroup enumerateAssetsAtIndexes:[NSIndexSet indexSetWithIndex:currentIndex] options:0 usingBlock: ^(ALAsset *asset, NSUInteger index, BOOL *stop) {
        if (asset) {
            if (asset.editable) {
                [asset setImageData:nil metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
                    if (error) {
                        NSLog(@"Asset url %@ should be deleted. (Error %@)", assetURL, error);
                    }
                }];
            }
        }
    }];
    [self showMedia:prev];
    
}

- (void) switchToCameraMode
{
    [self hideView:viewViewerControls];
    [self hideViewer];
    [self showCameraControls];
    currentIndex = -1;
}

- (void) switchToViewerMode: (id) sender
{
    [self showViewerControls];
    [self showMedia:prev];
}

- (void)dimmerTimerFired:(NSTimer *)timer
{
    if (viewCameraControls.alpha > 0.1) {
        [self dimView:0.5 withAlpha:0.1 withView:viewCameraControls withTimer:NO];
    }
    if (viewViewerControls.alpha > 0.1) {
        [self dimView:0.5 withAlpha:0.1 withView:viewViewerControls withTimer:NO];
    }
}

- (void)hideView:(UIView *)view
{
    [self dimView:0 withAlpha:0 withView:view withTimer:NO];
}

- (void)dimView:(float)duration withAlpha:(float)alpha withView:(UIView *)view withTimer:(BOOL)showTimer
{
    NSLog(@"dim the view");
    [timerDimmer invalidate];
    timerDimmer = nil;

    [UIView animateWithDuration:duration delay:0.0
                        options: (UIViewAnimationOptionCurveEaseInOut & UIViewAnimationOptionBeginFromCurrentState)
                     animations:^{
                         view.alpha = alpha;
                     }
                     completion:^(BOOL complete){
                         if(showTimer){
                             timerDimmer = [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(dimmerTimerFired:) userInfo:nil repeats:NO];
                         }
                     }];
}

- (void)toggleCaptureMode: (id) sender {
    [self showCameraControls];

    if (isRecording) {
        [self stopRecording];
    }
    
    isVideo = !isVideo;
    UIButton *button = (UIButton *) sender;
    [self setCameraButtonIcon:button];
    
    //TO DO:Also update the shutter button to be either the camera or video style

    id camera = isVideo ? videoCamera : stillCamera;
    [camera stopCameraCapture];
    [displayFilter removeAllTargets];
    [finalFilter removeAllTargets];
    self.displayFilter = nil;
    self.finalFilter = nil;
    
    self.stillCamera = nil;
    self.videoCamera = nil;
    
    [self showCameraControls];
    //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
    //^{
    //    [self showCameraControls];
    //});
}

- (void) setCameraButtonIcon:(UIButton *)button
{
    if (isVideo) {
        [button setImage:[UIImage imageNamed:@"camera"] forState:UIControlStateNormal];
    } else {
        [button setImage:[UIImage imageNamed:@"video"] forState:UIControlStateNormal];
    }
}

- (void)captureStill
{
    NSLog(@"CAPTURING STILL");
    isSaving = YES;
    [self showSavingAlert];
    
    [displayFilter removeAllTargets];
    self.displayFilter = nil;
    [stillCamera removeAllTargets];

    [self applyFilters:stillCamera];
    [finalFilter prepareForImageCapture];
    
    [stillCamera capturePhotoAsImageProcessedUpToFilter:finalFilter withCompletionHandler:^(UIImage *processedImage, NSError *error) {
        // Save to assets library
        NSMutableDictionary *captureMetadata = [stillCamera.currentCaptureMetadata mutableCopy];
        // correct the orientation, as it represents the orientation when the photo was taken, and our processed image has a different orientation
        captureMetadata[ALAssetPropertyOrientation] = @(ALAssetOrientationUp);
        captureMetadata[@"Orientation"] = @(UIImageOrientationUp);
        
        // Save to assets library
        [assetLibrary writeImageToSavedPhotosAlbum:processedImage.CGImage metadata:captureMetadata completionBlock:^(NSURL *assetURL, NSError *error2)
        {
             if (error2) {
                 NSLog(@"ERROR: the image failed to be written");
                 [self restartPreview];
             }
             else {
                 NSLog(@"PHOTO SAVED - assetURL: %@", assetURL);
                 
                 [assetLibrary assetForURL:assetURL
                               resultBlock:^(ALAsset *asset) {
                                   // assign the photo to the album
                                   [assetsGroup addAsset:asset];
                                   NSLog(@"Added %@ to %@", [[asset defaultRepresentation] filename], [assetsGroup valueForProperty:ALAssetsGroupPropertyName]);
                                   NSLog(@"SIZE: %f : %f", [asset defaultRepresentation].dimensions.height, [asset defaultRepresentation].dimensions.width);
                                   
                                   [self restartPreview];
                               }
                              failureBlock:^(NSError* error) {
                                  NSLog(@"failed to retrieve image asset:\nError: %@ ", [error localizedDescription]);
                                  [self restartPreview];
                              }];
             }
            
         }];
    }];
}

- (void)restartPreview
{
    [finalFilter removeAllTargets];
    self.finalFilter = nil;
    [stillCamera removeAllTargets];
    [self showFilteredDisplay:stillCamera];
    isSaving = NO;
    [self hideSavingAlert];
}


- (void)showSavingAlert
{
    viewSaving = [[UIView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width/2, (self.view.bounds.size.height - 150)/2, self.view.bounds.size.width/2, 75)];
    [viewSaving setAutoresizingMask: UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin];
    
    UIView *viewShadow = [[UIView alloc] initWithFrame:CGRectMake(0,0,viewSaving.frame.size.width, viewSaving.frame.size.height)];
    [viewShadow setBackgroundColor:[UIColor blackColor]];
    [viewShadow setAlpha:0.3];
    
    UILabel *labelSaving = [[UILabel alloc] initWithFrame:CGRectMake(0,0,viewSaving.frame.size.width, viewSaving.frame.size.height)];
    [labelSaving setTextColor:[UIColor whiteColor]];
    [labelSaving setBackgroundColor:[UIColor clearColor]];
    [labelSaving setTextAlignment:NSTextAlignmentCenter];
    [labelSaving setText:@"Saving..."];
    
    [viewSaving addSubview:viewShadow];
    [viewSaving addSubview:labelSaving];
    
    [self.view addSubview:viewSaving];
    
    [UIView animateWithDuration:0.5 delay:0.0
                        options: (UIViewAnimationOptionCurveEaseInOut & UIViewAnimationOptionBeginFromCurrentState)
                     animations:^{
                         viewSaving.alpha = 1.0;
                     }
                     completion:^(BOOL complete){
                     }];
}

- (void)hideSavingAlert
{
    [UIView animateWithDuration:0.5 delay:0.0
                        options: (UIViewAnimationOptionCurveEaseInOut & UIViewAnimationOptionBeginFromCurrentState)
                     animations:^{
                         viewSaving.alpha = 0.0;
                     }
                     completion:^(BOOL complete){
                         [viewSaving removeFromSuperview];
                     }];
}

- (void)startRecording
{
    isRecording = YES;
    
    // HACK. volume down is getting triggered inadvertently by the button stealer. ignore that if it's soon after we started recording.
    ignoreVolumeDown = YES;
    [NSTimer scheduledTimerWithTimeInterval:1.5 target:self selector:@selector(activateVolumeDown:) userInfo:nil repeats:NO];
    
    [self dimView:0.5 withAlpha:0.1 withView:viewCameraControls withTimer:NO];
    
    // Show the red "record" button
    [self setShutterButtonImage];

    // start recording the movie
    didFinishEffect = NO;
    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.m4v"];
    unlink([pathToMovie UTF8String]); // If a file already exists, AVAssetWriter won't let you record new frames, so delete the old movie
    NSURL *movieURL = [NSURL fileURLWithPath:pathToMovie];
    movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(1280.0, 720.0)];
    
    
    __weak typeof(self) weakSelf = self;
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
    [self applyFilters:videoCamera];
    [finalFilter addTarget:movieWriter];
    
    dispatch_async(dispatch_get_main_queue(),
       ^{
           NSLog(@"Start recording");
           [self playVideoStartSound];
           videoCamera.audioEncodingTarget = movieWriter;
           [movieWriter startRecording];
       });
    
}

- (void)stopRecording
{
    isRecording = NO;
    [self setShutterButtonImage];
    dispatch_async(dispatch_get_main_queue(),
                   ^{
                       videoCamera.audioEncodingTarget = nil;
                       [finalFilter removeTarget:movieWriter];
                       [movieWriter finishRecording];
                       NSLog(@"Movie completed");
                   });
}


- (void)activateVolumeDown:(NSTimer *)timer
{
    NSLog(@"reactivate the volume down button");
    ignoreVolumeDown = NO;
}

- (void)playVideoStartSound
{
    AudioServicesPlaySystemSound (videoBeep);
}

- (void)swipeScreenleft:(UISwipeGestureRecognizer *)sgr
{
    NSLog(@"SWIPED LEFT");
    [self showMedia:next];
}

- (void)swipeScreenRight:(UISwipeGestureRecognizer *)sgr
{
    NSLog(@"SWIPED RIGHT");
    [self showMedia:prev];
}

- (void)handleTapAction:(UITapGestureRecognizer *)tgr
{
    if (tgr.state == UIGestureRecognizerStateRecognized) {
        
        if (isWatching) {
            NSLog(@"VIEWER TAPPED!");
            [self showViewerControls];
        } else {
            NSLog(@"CAMERA TAPPED!");
            [self showCameraControls];
            CGPoint location = [tgr locationInView:uberView];
            [self showFocusSquare:location];
            [self setCameraFocus:location];
        }
    }
}

-(void) handleDoubleTapAction:(UITapGestureRecognizer *)tgr
{
    if (isWatching) {
        [self showViewerControls];
        CGPoint location = [tgr locationInView:uberView];
        if (location.x < uberView.frame.size.height/2) {
            [self showMedia:prev];
        } else {
            [self showMedia:next];
        }
    }
}

- (void)handleShadowTapAction:(UITapGestureRecognizer *)tgr
{
    if (tgr.state == UIGestureRecognizerStateRecognized) {
        [self showCameraControls];
    }
}


- (void)setCameraFocus:(CGPoint)location
{
    AVCaptureDevice *device;
    if (isVideo) {
        device = videoCamera.inputCamera;
    } else {
        device = stillCamera.inputCamera;
    }
    
    CGSize frameSize = [uberView frame].size;
    
    // translate the location to the position in the image coming from the device
    CGPoint pointOfInterest = CGPointMake((1.f + cropFactor)/2 - location.x * cropFactor / frameSize.height, (1.f + cropFactor)/2 - location.y * cropFactor / frameSize.width);
    
    NSLog(@"frame width = %f height = %f", frameSize.width, frameSize.height);
    NSLog(@"location x = %f y = %f", location.x, location.y);
    NSLog(@"POI x = %f y = %f", pointOfInterest.x, pointOfInterest.y);
    
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

- (void)showFocusSquare:(CGPoint)location
{
    if (imgFocusSquare) {
        [imgFocusSquare removeFromSuperview];
    }
    imgFocusSquare = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"focus"]];
    float x = location.x - 65/2;
    float y = location.y - 65/2;
    x = x > 0 ? x : 0;
    x = (x > (uberView.frame.size.height - 65) ? uberView.frame.size.height - 65 : x);
    y = y > 0 ? y : 0;
    y = (y > (uberView.frame.size.width - 140) ? (uberView.frame.size.width - 140) : y);
    
    [imgFocusSquare setFrame:CGRectMake(x, y, 65, 65)];
    [uberView addSubview:imgFocusSquare];
    NSLog(@"uber size: %f, %f", uberView.frame.size.width, uberView.frame.size.height);
    NSLog(@"focus position: %f, %f", x, y);

    [UIView animateWithDuration:0.5 delay:0.0
                        options: (UIViewAnimationOptionCurveEaseInOut & UIViewAnimationOptionBeginFromCurrentState)
                     animations:^{
                         imgFocusSquare.alpha = 1.0;
                     }
                     completion:^(BOOL complete){
                         [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(focusTimerFired:) userInfo:nil repeats:NO];
                     }];
}

- (void)focusTimerFired:(NSTimer *)timer
{
    [UIView animateWithDuration:0.5 delay:0.0
                        options: (UIViewAnimationOptionCurveEaseInOut & UIViewAnimationOptionBeginFromCurrentState)
                     animations:^{
                         imgFocusSquare.alpha = 0.0;
                     }
                     completion:^(BOOL complete){
                         [imgFocusSquare removeFromSuperview];
                     }];
}


- (void)writeMovieToLibraryWithPath:(NSURL *)path
{
    NSLog(@"writing %@ to library", path);
    [assetLibrary writeVideoAtPathToSavedPhotosAlbum:path
                                completionBlock:^(NSURL *assetURL, NSError *error) {
                                    if (error)
                                    {
                                        NSLog(@"Error saving to library%@", [error localizedDescription]);
                                    } else
                                    {
                                        NSLog(@"SAVED %@ to photo lib",path);
                                        [assetLibrary assetForURL:assetURL
                                                      resultBlock:^(ALAsset *asset) {
                                                          // assign the photo to the album
                                                          [assetsGroup addAsset:asset];
                                                          NSLog(@"Added %@ to %@", [[asset defaultRepresentation] filename], [assetsGroup valueForProperty:ALAssetsGroupPropertyName]);
                                                          NSLog(@"SIZE: %f : %f", [asset defaultRepresentation].dimensions.height, [asset defaultRepresentation].dimensions.width);
                                                      }
                                                     failureBlock:^(NSError* error) {
                                                         NSLog(@"failed to retrieve image asset:\nError: %@ ", [error localizedDescription]);
                                                     }];
                                    }
                                }];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    //intercept web links in poppy: scheme
    if ([request.URL.scheme isEqualToString:@"poppy"]) {
        if ([request.URL.host isEqualToString:@"viewer"]) {
            [galleryWebView removeFromSuperview];
            galleryWebView = nil;
            [self showViewerControls];
        }
        return NO;
    }
    return YES;
}

//- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
//{
//    return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft);
//}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    if (isRecording) {
        [self stopRecording];
    }
}

- (int)deviceModelNumber {
    
    struct utsname systemInfo;
    
    uname(&systemInfo);
    
    NSString *machineName = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    NSDictionary *commonNamesDictionary =
    @{
      @"iPhone3,1":    @"40",
      @"iPhone3,2":    @"40",
      @"iPhone3,3":    @"40",
      @"iPhone4,1":    @"41",
      @"iPhone5,1":    @"50",
      @"iPhone5,2":    @"50",
      @"iPhone5,3":    @"51",
      @"iPhone5,4":    @"51",
      @"iPhone6,1":    @"52",
      @"iPhone6,2":    @"53",
      @"iPod5,1":  @"99",
      
      /*
       @"iPhone3,1":    @"iPhone 4",
       @"iPhone3,2":    @"iPhone 4(Rev A)",
       @"iPhone3,3":    @"iPhone 4(CDMA)",
       @"iPhone4,1":    @"iPhone 4S",
       @"iPhone5,1":    @"iPhone 5(GSM)",
       @"iPhone5,2":    @"iPhone 5(GSM+CDMA)",
       @"iPhone5,3":    @"iPhone 5c(GSM)",
       @"iPhone5,4":    @"iPhone 5c(GSM+CDMA)",
       @"iPhone6,1":    @"iPhone 5s(GSM)",
       @"iPhone6,2":    @"iPhone 5s(GSM+CDMA)",
       @"iPod5,1":  @"iPod 5th Gen",
      */
      
      };
    
    NSString *deviceNumber = commonNamesDictionary[machineName];
    
    return deviceNumber.intValue;
}

@end
