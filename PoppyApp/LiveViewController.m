//
//  LiveViewController.m
//  PoppyApp
//
//  Created by Ethan Lowry on 10/1/13.
//  Copyright (c) 2013 Ethan Lowry. All rights reserved.
//

// TAGGED VIEWS:
// 100 = the view containing the camera (capture mode) controls
// 101 = the toggle label
// 102 = the "recording" light
// 103 = the movie player view
// 104 = the view containing the view controls (camera button)
// 105 = the "no media available" label view
// 106 = the "saving" label view
// 107 = the "welcome" label view

#import "LiveViewController.h"
#import "RBVolumeButtons.h"
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

int next = 1;
int prev = -1;

float cropFactor = 0.7;
float perspectiveFactor = 0.25;

bool didFinishEffect = NO;
bool isRecording = NO;
bool isVideo = YES;
bool isWatching = NO;
bool isSaving = NO;
bool ignoreVolumeDown = NO;
bool isViewActive;

NSTimer *timerDimmer;
ALAssetsGroup *assetsGroup;
ALAssetsLibrary *assetLibrary;

UIImageView *imgFocusSquare;

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
    xOffset = [[NSUserDefaults standardUserDefaults] floatForKey:@"xOffset"];
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
                [self startRecording];
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
    [mainMoviePlayer stop];
    [[self.view viewWithTag:103] removeFromSuperview]; //remove the movie player
    [[self.view viewWithTag:104] removeFromSuperview]; //remove the camera button
}

- (void)activateView
{
    // Create a Poppy album if it doesn't already exist
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
    
    // NOTE: immediately steals volume button events. maybe we want to only do this in landscape mode
    [buttonStealer startStealingVolumeButtonEvents];

    
    imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.height, self.view.frame.size.width)];
    [imgView setContentMode: UIViewContentModeScaleAspectFill];
    
    [self.view addSubview:imgView];
    
    uberView = (GPUImageView *)self.view;
    uberView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
    
    // set crop factor based on device
    cropFactor = [self setCropFactor];
    
    // set up gestures
    UIView *touchView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.height, self.view.frame.size.width)];
    [self addGestures:touchView];
    [self.view addSubview:touchView];
    
    [self activateCamera];
    
    NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"beep" ofType:@"wav"];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)([NSURL fileURLWithPath: soundPath]), &videoBeep);
}

- (void)viewDidAppear:(BOOL)animated
{
    if (isViewActive) {
        [self activateView];
        if (!calibrateFirst) {
            [self showWelcomeAlert];
            calibrateFirst = NO;
        } else {
            [self showCameraControls];
        }
    } else {
        //make the default view less ugly
        [self.view setBackgroundColor:[UIColor blackColor]];
        CalibrationViewController *cvc = [[CalibrationViewController alloc] initWithNibName:@"LiveView" bundle:nil];
        [self presentViewController:cvc animated:NO completion:nil];
    }
}

- (void)addGestures:(UIView *)touchView
{
    UITapGestureRecognizer *handleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapAction:)];
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
            [self showViewerControls];
            [self dimView:0.0 withAlpha:0.1 withView:[self.view viewWithTag:104] withTimer:NO];
        }
        isWatching = YES; // we're in view mode, not capture mode
        [self hideView:[self.view viewWithTag:100]]; // hide the capture mode controls
        
        [mainMoviePlayer stop];
        [[self.view viewWithTag:103] removeFromSuperview];
        
        NSLog(@"Current index before = %d", currentIndex);
        
        if (direction == prev) {
            if (currentIndex > 0) {
                currentIndex = currentIndex - 1;
            } else {
                currentIndex = assetCount - 1;
            }
        } else {
            if (currentIndex < assetCount - 1) {
                currentIndex = currentIndex + 1;
            } else {
                currentIndex = 0;
            }
        }
        NSLog(@"Current index after = %d", currentIndex);
        
        [assetsGroup enumerateAssetsAtIndexes:[NSIndexSet indexSetWithIndex:currentIndex] options:0 usingBlock: ^(ALAsset *asset, NSUInteger index, BOOL *stop)
             {
                 if (asset) {
                     NSLog(@"got the asset: %d", index);
                     ALAssetRepresentation *assetRepresentation = [asset defaultRepresentation];
                     UIImage *fullScreenImage = [UIImage imageWithCGImage:[assetRepresentation fullScreenImage] scale:[assetRepresentation scale] orientation:UIImageOrientationLeft];
                     NSLog(@"image stuff, wide: %f height: %f", fullScreenImage.size.width, fullScreenImage.size.height);
                     
                     [imgView setImage:fullScreenImage];
                     [imgView setHidden:NO];
                     
                     if ([asset valueForProperty:ALAssetPropertyType] == ALAssetTypeVideo) {
                         NSLog(@"It's a video");
                         [self playMovie:asset];
                     } else {
                         NSLog(@"It's a photo");
                     }
                     *stop = YES;
                 }
             }];
    } else {
        NSLog(@"NO IMAGES IN THE ALBUM");
        [self showNoMediaAlert];
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

- (void)showWelcomeAlert
{
    UIView *viewWelcome = [[UIView alloc] initWithFrame:CGRectMake(0, (self.view.bounds.size.height - 75)/2, self.view.bounds.size.width, 75)];
    [viewWelcome setAutoresizingMask: UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin];
    [viewWelcome setTag:107];
    
    UIView *viewShadow = [[UIView alloc] initWithFrame:CGRectMake(0,0,viewWelcome.frame.size.width, viewWelcome.frame.size.height)];
    [viewShadow setBackgroundColor:[UIColor blackColor]];
    [viewShadow setAlpha:0.3];
    
    UILabel *labelWelcome = [[UILabel alloc] initWithFrame:CGRectMake(0,0,viewWelcome.frame.size.width, viewWelcome.frame.size.height)];
    [labelWelcome setTextColor:[UIColor whiteColor]];
    [labelWelcome setBackgroundColor:[UIColor clearColor]];
    [labelWelcome setTextAlignment:NSTextAlignmentCenter];
    [labelWelcome setFont:[UIFont boldSystemFontOfSize:24]];
    [labelWelcome setTextAlignment:NSTextAlignmentCenter];
    [labelWelcome setText:@"Put me in Poppy!"];
    
    [viewWelcome addSubview:viewShadow];
    [viewWelcome addSubview:labelWelcome];
    
    [self.view addSubview:viewWelcome];
    
    [UIView animateWithDuration:0.5 delay:0.0
                        options: (UIViewAnimationOptionCurveEaseInOut & UIViewAnimationOptionBeginFromCurrentState)
                     animations:^{
                         viewWelcome.alpha = 1.0;
                     }
                     completion:^(BOOL complete){
                         [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(welcomeTimerFired:) userInfo:nil repeats:NO];
                     }];
}

- (void)welcomeTimerFired:(NSTimer *)timer
{
    UIView *welcomeView = [self.view viewWithTag:107];
    [UIView animateWithDuration:0.5 delay:0.0
                        options: (UIViewAnimationOptionCurveEaseInOut & UIViewAnimationOptionBeginFromCurrentState)
                     animations:^{
                         welcomeView.alpha = 0.0;
                     }
                     completion:^(BOOL complete){
                         [self showCameraControls];
                         [welcomeView removeFromSuperview];
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
    
    [self.view bringSubviewToFront:[self.view viewWithTag:104]];
    
}

- (void)moviePlayBackDidFinish:(id)sender {
    NSLog(@"Movie playback finished");
    [mainMoviePlayer stop];
    [[self.view viewWithTag:103] removeFromSuperview];
}


- (void)activateCamera
{
    if (isVideo) {
        // video camera setup
        if ([self deviceModelNumber] == 40) {
            videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionBack];
        } else {
            videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionBack];
        }
        videoCamera.outputImageOrientation = UIInterfaceOrientationLandscapeLeft;
        videoCamera.horizontallyMirrorRearFacingCamera = NO;
        [self showFilteredDisplay:videoCamera];
    } else {
        //still camera setup
        if ([self deviceModelNumber] == 40) {
            stillCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionBack];
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
    if([camera isKindOfClass:[GPUImageStillCamera class]] && [self deviceModelNumber] == 41) {
        finalCropRect = CGRectMake(xOffset + (1.0 - cropFactor)/2, (1.0 - cropFactor)/2 + cropFactor * .175, cropFactor, cropFactor * .65);
    } else {
        finalCropRect = CGRectMake(xOffset + (1.0 - cropFactor)/2, (1.0 - cropFactor)/2, cropFactor, cropFactor);
    }
    
    displayFilter = [[GPUImageCropFilter alloc] initWithCropRegion:finalCropRect];
    [camera addTarget:displayFilter];
    [displayFilter addTarget:uberView];
    [camera startCameraCapture];
}

- (void)applyFilters:(id)camera
{
    @autoreleasepool {
        CGRect finalCropRect;
        if([camera isKindOfClass:[GPUImageStillCamera class]] && [self deviceModelNumber] == 41) {
            finalCropRect = CGRectMake((1.0 - cropFactor)/2, (1.0 - cropFactor)/2 + cropFactor * .175, cropFactor, cropFactor * .65);
        } else {
            finalCropRect = CGRectMake((1.0 - cropFactor)/2, (1.0 - cropFactor)/2, cropFactor, cropFactor);
        }
        
        finalFilter = [[GPUImageCropFilter alloc] initWithCropRegion:finalCropRect];
        
        GPUImageFilter *initialFilter = [[GPUImageFilter alloc] init];
        GPUImageCropFilter *cropLeft = [[GPUImageCropFilter alloc] init];
        GPUImageCropFilter *cropRight = [[GPUImageCropFilter alloc] init];
        
        if([camera isKindOfClass:[GPUImageStillCamera class]] && [self deviceModelNumber] == 41) {
            NSLog(@"still output for iPhone 4S");
            [initialFilter forceProcessingAtSize:CGSizeMake(1920, 1440)];
        }

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
    NSLog(@"show camera controls");
    
    UIView *viewControls = (id)[self.view viewWithTag:100];
    
    if (!viewControls)
    {
        // add the toggle button
        UIView *viewCameraControls = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 75, self.view.bounds.size.width, 75)];
        
        [viewCameraControls setTag:100];
        
        [self addCameraControlsContentWithView:viewCameraControls];
        
        [self.view addSubview:viewCameraControls];
        
        viewControls = viewCameraControls;
    }
    [self.view bringSubviewToFront:viewControls];
    [self dimView:0.5 withAlpha:1.0 withView:viewControls withTimer:YES];

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
    
    UILabel *labelCaptureMode = [[UILabel alloc] initWithFrame:CGRectMake(controlsView.frame.size.width - 230, 10, 50, 20)];
    [labelCaptureMode setTag: 101];
    [labelCaptureMode setTextColor:[UIColor whiteColor]];
    [labelCaptureMode setBackgroundColor:[UIColor clearColor]];
    [labelCaptureMode setTextAlignment:NSTextAlignmentCenter];
    
    UISwitch *switchCaptureMode = [[UISwitch alloc] initWithFrame:CGRectMake(controlsView.frame.size.width - 230, 35, 50, 20)];
    [switchCaptureMode addTarget: self action: @selector(toggleCaptureMode:) forControlEvents:UIControlEventValueChanged];
    
    if(isVideo){
        [labelCaptureMode setText:@"Video"];
        [switchCaptureMode setOn: YES];
    } else {
        [labelCaptureMode setText:@"Photo"];
        [switchCaptureMode setOn: NO];
    }
    
    [controlsView addSubview: viewShadow];
    [controlsView addSubview: labelCaptureMode];
    [controlsView addSubview: switchCaptureMode];
    
    // add the switch to viewer button
    NSLog(@"adding the viewer button");
    UIButton *buttonViewer = [[UIButton alloc] initWithFrame: CGRectMake(controlsView.frame.size.width - 150, 0, 70, 75)];
    [buttonViewer setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
    [buttonViewer addTarget:self action:@selector(switchToViewerMode:) forControlEvents:UIControlEventTouchUpInside];
    [controlsView addSubview: buttonViewer];
    
    // add the shutter button
    NSLog(@"adding the shutter button");
    UIButton *buttonShutter = [[UIButton alloc] initWithFrame: CGRectMake(controlsView.frame.size.width - 70, 0, 70, 75)];
    [buttonShutter setImage:[UIImage imageNamed:@"shutter"] forState:UIControlStateNormal];
    [buttonShutter setImage:[UIImage imageNamed:@"shutterPressed"] forState:UIControlStateHighlighted];
    [buttonShutter addTarget:self action:@selector(shutterButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [controlsView addSubview: buttonShutter];
    
    [viewContainer addSubview: controlsView];
}

- (void) showViewerControls
{
    NSLog(@"show viewer controls");
    
    if (isRecording) {
        [self stopRecording];
    }
    
    UIView *viewControls = (id)[self.view viewWithTag:104];
    
    if (!viewControls)
    {
        NSLog(@"add the camera button");
        UIView *viewViewerControls = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 75, self.view.bounds.size.width, 75)];
        [viewViewerControls setAutoresizingMask: UIViewAutoresizingFlexibleTopMargin];
        [viewViewerControls setTag:104];
        [self addViewerControlsContentWithView:viewViewerControls];
        [self.view addSubview:viewViewerControls];
        
        viewControls = viewViewerControls;
    }
    [self.view bringSubviewToFront:viewControls];
    [self dimView:0.5 withAlpha:1.0 withView:viewControls withTimer:YES];
    
}

- (void) addViewerControlsContentWithView:(UIView *)viewContainer
{
    UIView *controlsView = [[UIView alloc] initWithFrame:CGRectMake(viewContainer.bounds.size.width/2, 0, viewContainer.bounds.size.width/2, 75)];
    
    UIView *viewShadow = [[UIView alloc] initWithFrame:CGRectMake(controlsView.frame.size.width - 70,0,70,75)];
    [viewShadow setBackgroundColor:[UIColor blackColor]];
    [viewShadow setAlpha:0.3];
    [self addGestures:viewShadow];
    
    UIButton *buttonCamera = [[UIButton alloc] initWithFrame: CGRectMake(controlsView.frame.size.width - 70,0,70,75)];
    [buttonCamera setImage:[UIImage imageNamed:@"camera"] forState:UIControlStateNormal];
    [buttonCamera addTarget:self action:@selector(switchToCameraMode:) forControlEvents:UIControlEventTouchUpInside];
    [controlsView addSubview: viewShadow];
    [controlsView addSubview: buttonCamera];
    [viewContainer addSubview:controlsView];
}

- (void) switchToCameraMode: (id) sender
{
    [self hideView:[self.view viewWithTag:104]];
    [self hideViewer];
    [self showCameraControls];
    currentIndex = -1;
}

- (void) switchToViewerMode: (id) sender
{
    [self showCameraControls];
    [self showMedia:prev];
}

- (void)dimmerTimerFired:(NSTimer *)timer
{
    UIView *cameraControlsView = [self.view viewWithTag:100];
    UIView *viewerControlsView = [self.view viewWithTag:104];
    if (cameraControlsView.alpha > 0.1) {
        [self dimView:0.5 withAlpha:0.1 withView:cameraControlsView withTimer:NO];
    }
    if (viewerControlsView.alpha > 0.1) {
        [self dimView:0.5 withAlpha:0.1 withView:viewerControlsView withTimer:NO];
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
                             timerDimmer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(dimmerTimerFired:) userInfo:nil repeats:NO];
                         }
                     }];
}

- (void)toggleCaptureMode: (id) sender {
    [self showCameraControls];
    UISwitch *toggle = (UISwitch *) sender;
    NSLog(@"%@", toggle.on ? @"Video" : @"Still");
    UILabel *toggleLabel = (id)[self.view viewWithTag:101];
    isVideo = toggle.on;
    
    id camera = toggle.on ? stillCamera : videoCamera;
    [toggleLabel setText: toggle.on ? @"Video" : @"Photo"];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
    ^{
        [camera stopCameraCapture];
        [self activateCamera];
    });
}

- (void)captureStill
{
    NSLog(@"CAPTURING STILL");
    isSaving = YES;
    [self showSavingAlert];
    
    [displayFilter removeAllTargets];
    displayFilter = nil;
    [stillCamera removeAllTargets];

    [self applyFilters:stillCamera];
    [finalFilter prepareForImageCapture];
    
    [stillCamera capturePhotoAsImageProcessedUpToFilter:finalFilter withCompletionHandler:^(UIImage *processedImage, NSError *error) {
        // Save to assets library
        [assetLibrary writeImageToSavedPhotosAlbum:processedImage.CGImage metadata:stillCamera.currentCaptureMetadata completionBlock:^(NSURL *assetURL, NSError *error2) {
             if (error2) {
                 NSLog(@"ERROR: the image failed to be written");
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
    finalFilter = nil;
    [stillCamera removeAllTargets];
    [self showFilteredDisplay:stillCamera];
    isSaving = NO;
    [self hideSavingAlert];
}


- (void)showSavingAlert
{
    UIView *viewSaving = [[UIView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width/2, (self.view.bounds.size.height - 150)/2, self.view.bounds.size.width/2, 75)];
    [viewSaving setAutoresizingMask: UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin];
    [viewSaving setTag:106];
    
    UIView *viewShadow = [[UIView alloc] initWithFrame:CGRectMake(0,0,viewSaving.frame.size.width, viewSaving.frame.size.height)];
    [viewShadow setBackgroundColor:[UIColor blackColor]];
    [viewShadow setAlpha:0.3];
    
    UILabel *labelNoMedia = [[UILabel alloc] initWithFrame:CGRectMake(0,0,viewSaving.frame.size.width, viewSaving.frame.size.height)];
    [labelNoMedia setTextColor:[UIColor whiteColor]];
    [labelNoMedia setBackgroundColor:[UIColor clearColor]];
    [labelNoMedia setTextAlignment:NSTextAlignmentCenter];
    [labelNoMedia setText:@"Saving..."];
    
    [viewSaving addSubview:viewShadow];
    [viewSaving addSubview:labelNoMedia];
    
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
    UIView *viewSaving = [self.view viewWithTag:106];
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
    
    [self dimView:0.5 withAlpha:0.1 withView:[self.view viewWithTag:100] withTimer:NO];
    
    // Show the red "record" light
    UIImageView *imgRecord = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"record"]];
    [imgRecord setFrame:CGRectMake(self.view.bounds.size.width - 45, 20, 25, 25)];
    [imgRecord setAutoresizingMask: UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin];
    [imgRecord setTag:102];
    [self.view addSubview:imgRecord];
    NSLog(@"SHOWED THE RED LIGHT");

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
    videoCamera.audioEncodingTarget = nil;
    [finalFilter removeTarget:movieWriter];
    [movieWriter finishRecording];
    NSLog(@"Movie completed");
    [[self.view viewWithTag:102] removeFromSuperview]; // remove the "recording" light
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

- (void)swipeScreenleft:(UITapGestureRecognizer *)tgr
{
    NSLog(@"SWIPED LEFT");
    [self showMedia:next];
}

- (void)swipeScreenRight:(UITapGestureRecognizer *)tgr
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft);
}

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
