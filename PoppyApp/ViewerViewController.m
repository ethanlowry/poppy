//
//  ViewerViewController.m
//  Poppy
//
//  Created by Ethan Lowry on 2/18/14.
//  Copyright (c) 2014 Hack Things LLC. All rights reserved.
//

#import "ViewerViewController.h"
#import "AppDelegate.h"
#import <sys/utsname.h>
#import "PODAssetsManager.h"

@interface ViewerViewController ()
@property (nonatomic, strong) RBVolumeButtons *buttonStealer;
@property (nonatomic, strong) UIView *separatorBar;
@end

@implementation ViewerViewController

@synthesize mainMoviePlayer;
@synthesize imgView;
@synthesize viewViewerControls;
@synthesize viewDeleteAlert;
@synthesize viewNoMedia;

NSTimer *timerDimmer;
ALAssetsGroup *assetsGroup;
ALAssetsLibrary *assetLibrary;
int curIndex = -1;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)orientationChanged:(NSNotification *)notification
{
    // A delay must be added here, otherwise the new view will be swapped in
    // too quickly resulting in an animation glitch
    if (curIndex >= 0) {
        [self performSelector:@selector(updatePortraitView) withObject:nil afterDelay:0];
    }
}

- (void)updatePortraitView
{
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    
    if(deviceOrientation == UIDeviceOrientationPortrait){
        AppDelegate *poppyAppDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        poppyAppDelegate.switchToViewer = YES;
        poppyAppDelegate.currentAssetIndex = curIndex;
        [self dismissViewControllerAnimated:NO completion:^{}];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    // get poppy album
	[[PODAssetsManager assetsManager] ensuredAssetsAlbumNamed:@"Poppy" completion:^(ALAssetsGroup *group, NSError *anError) {
		if (group) {
			assetsGroup = group;
		}
	}];
    
    /*
    if (!assetLibrary) {
        assetLibrary = [[ALAssetsLibrary alloc] init];
        [assetLibrary addAssetsGroupAlbumWithName:@"Poppy"
                                      resultBlock:^(ALAssetsGroup *group) {
                                          if (group) {
                                              //NSLog(@"added album:%@", [group valueForProperty:ALAssetsGroupPropertyName]);
                                          } else {
                                              //NSLog(@"no group created, probably because it already exists");
                                          }
                                          [self loadAlbumWithName:@"Poppy"];
                                      }
                                     failureBlock:^(NSError *error) {
                                         NSLog(@"error adding album");
                                     }];
    }
     */
    self.buttonStealer = [[RBVolumeButtons alloc] init];
    
    __weak __typeof__(self) weakSelf = self;
    self.buttonStealer.upBlock = ^{
        [weakSelf plusVolumeButtonPressedAction];
    };
    self.buttonStealer.downBlock = ^{
        [weakSelf minusVolumeButtonPressedAction];
    };
    curIndex = -1;
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationChanged:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
}


- (void)minusVolumeButtonPressedAction {
    [self showMedia:YES];
}

- (void)plusVolumeButtonPressedAction {
    [self launchCamera];
}

- (void)viewDidAppear:(BOOL)animated
{
    AppDelegate *poppyAppDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [poppyAppDelegate makeScreenBrightnessMax];
    
    int64_t delayInSeconds = 0.01;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self.buttonStealer startStealingVolumeButtonEvents];
    });
    
    if (!imgView) {
        imgView = [[UIImageView alloc] initWithFrame:self.view.bounds];
        [imgView setContentMode: UIViewContentModeScaleAspectFill];
        [self.view addSubview:imgView];
    }
    
    if (!self.separatorBar) {
        self.separatorBar = [[UIView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width/2 - 2,0,4,self.view.bounds.size.height)];
        [self.separatorBar setBackgroundColor:[UIColor blackColor]];
        [self.view addSubview:self.separatorBar];
        self.separatorBar.layer.zPosition = MAXFLOAT;
    }
    
    UIView *touchView = [[UIView alloc] initWithFrame:self.view.bounds];
    [self addGestures:touchView];
    [self.view addSubview:touchView];
    
    [self showViewerControls];
    [self showMedia:YES];
}

- (void)launchCamera
{
    self.imgView = nil;
    [self hideViewer];
    
    AppDelegate *poppyAppDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    poppyAppDelegate.switchToCamera = YES;
    
    [self dismissAction:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) showViewerControls
{
    //NSLog(@"show viewer controls");

    if (!viewViewerControls)
    {
        viewViewerControls = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 75, self.view.bounds.size.width, self.view.bounds.size.height)];
        [viewViewerControls setAutoresizingMask: UIViewAutoresizingFlexibleTopMargin];
        [self addViewerControlsContentWithView:viewViewerControls];
        [self.view addSubview:viewViewerControls];
    }
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

- (void)hideViewer
{
    // clear away the view mode UI
    
    [self.mainMoviePlayer stop];
    [mainMoviePlayer.view removeFromSuperview]; //remove the movie player
    self.mainMoviePlayer = nil;
    curIndex = -1;
    [viewNoMedia removeFromSuperview];
    [viewViewerControls removeFromSuperview]; //remove the camera button
}

- (void) goHome
{
    self.imgView = nil;
    [self hideViewer];
    [self dismissAction:YES];
}

- (void) dismissAction:(BOOL)animated
{
    if (![self isBeingDismissed]) {
        [self dismissViewControllerAnimated:animated completion:^{}];
    }
}


- (void)showMedia:(BOOL)next
{
    // show image or play video
    int assetCount = [assetsGroup numberOfAssets];
    //NSLog(@"album count %d", assetCount);
    [self showViewerControls];

    if (assetCount > 0) {
        [viewNoMedia removeFromSuperview];
        
        if(curIndex == -1) {
            curIndex = assetCount;
        }
        
        if (next) {
            curIndex = curIndex - 1;
        } else {
            curIndex = curIndex + 1;
        }
        //NSLog(@"CURRENT INDEX: %d", currentIndex);
        
        AppDelegate *poppyAppDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        if (poppyAppDelegate.currentAssetIndex >= 0) {
            curIndex = poppyAppDelegate.currentAssetIndex;
            poppyAppDelegate.currentAssetIndex = -1;
        }
        
        if(curIndex >= 0 && curIndex < assetCount) {
            [mainMoviePlayer stop];
            [mainMoviePlayer.view removeFromSuperview];
            self.mainMoviePlayer = nil;
            
            UIImage *tempImage = imgView.image;
            [imgView setImage:nil];
            
            [assetsGroup enumerateAssetsAtIndexes:[NSIndexSet indexSetWithIndex:curIndex] options:0 usingBlock: ^(ALAsset *asset, NSUInteger index, BOOL *stop)
             {
                 if (asset) {
                     //NSLog(@"got the asset: %d", index);
                     ALAssetRepresentation *assetRepresentation = [asset defaultRepresentation];
                     UIImageOrientation orientation = UIImageOrientationUp;
                     NSNumber* orientationValue = [asset valueForProperty:@"ALAssetPropertyOrientation"];
                     if (orientationValue != nil) {
                         orientation = [orientationValue intValue];
                     }
                     UIImage *fullScreenImage = [UIImage imageWithCGImage:[assetRepresentation fullScreenImage] scale:[assetRepresentation scale] orientation:orientation];
                     //NSLog(@"image stuff, wide: %f height: %f", fullScreenImage.size.width, fullScreenImage.size.height);
                     
                     [imgView setImage:fullScreenImage];
                     [imgView setHidden:NO];
                     
                     if ([asset valueForProperty:ALAssetPropertyType] == ALAssetTypeVideo) {
                         [self playMovie:asset];
                     }
                     [self showViewerControls];
                     
                     // Animate the old image away
                     if (tempImage) {
                         float xPosition = next ? -imgView.frame.size.width : imgView.frame.size.width;
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
            //[self showViewerControls];
        } else {
            if (curIndex < 0) {
                curIndex = 0;
            } else {
                curIndex = assetCount - 1;
            }
        }
        
    } else {
        //NSLog(@"NO IMAGES IN THE ALBUM");
        [self showNoMediaAlert];
        imgView.image = [self imageWithColor:[UIColor darkGrayColor]];
        [imgView setHidden:NO];
    }
    
}

- (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (void)showNoMediaAlert
{
    if (!viewNoMedia){
        viewNoMedia = [[UIView alloc] initWithFrame:CGRectMake(0, (self.view.bounds.size.height - 150)/2, self.view.bounds.size.width, 75)];
        [viewNoMedia setAutoresizingMask: UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin];
        [viewNoMedia setAlpha:0.0];
        
        UIView *viewShadow = [[UIView alloc] initWithFrame:viewNoMedia.bounds];
        [viewShadow setBackgroundColor:[UIColor blackColor]];
        [viewShadow setAlpha:0.3];
        
        UILabel *labelNoMediaL = [[UILabel alloc] initWithFrame:CGRectMake(0,0,viewNoMedia.frame.size.width/2, viewNoMedia.frame.size.height)];
        [labelNoMediaL setTextColor:[UIColor whiteColor]];
        [labelNoMediaL setBackgroundColor:[UIColor clearColor]];
        [labelNoMediaL setTextAlignment:NSTextAlignmentCenter];
        [labelNoMediaL setText:@"Nothing to play!"];
        UILabel *labelNoMediaR = [[UILabel alloc] initWithFrame:CGRectMake(viewNoMedia.frame.size.width/2,0,viewNoMedia.frame.size.width/2, viewNoMedia.frame.size.height)];
        [labelNoMediaR setTextColor:[UIColor whiteColor]];
        [labelNoMediaR setBackgroundColor:[UIColor clearColor]];
        [labelNoMediaR setTextAlignment:NSTextAlignmentCenter];
        [labelNoMediaR setText:@"Nothing to play!"];
        
        [viewNoMedia addSubview:viewShadow];
        [viewNoMedia addSubview:labelNoMediaL];
        [viewNoMedia addSubview:labelNoMediaR];
    }
    
    [self.view addSubview:viewNoMedia];
    
    [UIView animateWithDuration:0.5 delay:0.0
                        options: (UIViewAnimationOptionCurveEaseInOut & UIViewAnimationOptionBeginFromCurrentState)
                     animations:^{
                         viewNoMedia.alpha = 1.0;
                     }
                     completion:^(BOOL complete){
                         //[NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(noMediaTimerFired:) userInfo:nil repeats:NO];
                     }];
}

- (void)noMediaTimerFired:(NSTimer *)timer
{
    [UIView animateWithDuration:0.5 delay:0.0
                        options: (UIViewAnimationOptionCurveEaseInOut & UIViewAnimationOptionBeginFromCurrentState)
                     animations:^{
                         viewNoMedia.alpha = 0.0;
                     }
                     completion:^(BOOL complete){
                         [viewNoMedia removeFromSuperview];
                     }];
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
            
            UILabel *deleteLabelL = [[UILabel alloc] initWithFrame:CGRectMake(0.0,(viewDeleteAlert.frame.size.height - 120)/2,viewDeleteAlert.frame.size.width/2,60)];
            [deleteLabelL setTextAlignment:NSTextAlignmentCenter];
            [deleteLabelL setBackgroundColor:[UIColor blackColor]];
            [deleteLabelL setTextColor:[UIColor whiteColor]];
            CALayer *bottomBorderL = [CALayer layer];
            bottomBorderL.frame = CGRectMake(40, 59, deleteLabelL.frame.size.width-80, 1.0);
            bottomBorderL.backgroundColor = [UIColor whiteColor].CGColor;
            [deleteLabelL.layer addSublayer:bottomBorderL];
            
            UILabel *deleteLabelR = [[UILabel alloc] initWithFrame:CGRectMake(viewDeleteAlert.frame.size.width/2,(viewDeleteAlert.frame.size.height - 120)/2,viewDeleteAlert.frame.size.width/2,60)];
            [deleteLabelR setTextAlignment:NSTextAlignmentCenter];
            [deleteLabelR setBackgroundColor:[UIColor blackColor]];
            [deleteLabelR setTextColor:[UIColor whiteColor]];
            CALayer *bottomBorderR = [CALayer layer];
            bottomBorderR.frame = CGRectMake(40, 59, deleteLabelR.frame.size.width-80, 1.0);
            bottomBorderR.backgroundColor = [UIColor whiteColor].CGColor;
            [deleteLabelR.layer addSublayer:bottomBorderR];
            
            [viewDeleteAlert addSubview:deleteLabelL];
            [viewDeleteAlert addSubview:deleteLabelR];
            [assetsGroup enumerateAssetsAtIndexes:[NSIndexSet indexSetWithIndex:curIndex] options:0 usingBlock: ^(ALAsset *asset, NSUInteger index, BOOL *stop) {
                if (asset) {
                    if (asset.editable) {
                        [deleteLabelL setText: @"Delete this photo?"];
                        [deleteLabelR setText: @"Delete this photo?"];
                        [self addDeleteButtons:0.0 withDelete:YES];
                        [self addDeleteButtons:viewDeleteAlert.frame.size.width/2 withDelete:YES];
                        *stop = YES;
                    } else {
                        [deleteLabelL setText: @"This photo can't be deleted"];
                        [deleteLabelR setText: @"This photo can't be deleted"];
                        [self addDeleteButtons:0.0 withDelete:NO];
                        [self addDeleteButtons:viewDeleteAlert.frame.size.width/2 withDelete:NO];
                        *stop = YES;
                    }
                }
            }];
        }
        
        [self.view addSubview:viewDeleteAlert];
        [self.view bringSubviewToFront:viewDeleteAlert];
    }
}

- (void)addDeleteButtons:(float)offset withDelete:(BOOL)showDelete
{
    UIButton *buttonCancelDelete = [[UIButton alloc] init];
    [buttonCancelDelete addTarget:self action:@selector(dismissDeleteAlert) forControlEvents:UIControlEventTouchUpInside];
    [buttonCancelDelete.titleLabel setTextAlignment:NSTextAlignmentRight];
    [buttonCancelDelete setBackgroundColor:[UIColor blackColor]];
    [viewDeleteAlert addSubview:buttonCancelDelete];
    
    if(showDelete){
        [buttonCancelDelete setFrame:CGRectMake(offset + viewDeleteAlert.frame.size.width/4, viewDeleteAlert.frame.size.height/2, viewDeleteAlert.frame.size.width/4, 60)];
        [buttonCancelDelete setTitle:@"Cancel" forState:UIControlStateNormal];
        
        UIButton *buttonConfirmDelete = [[UIButton alloc] initWithFrame:CGRectMake(offset,viewDeleteAlert.frame.size.height/2, viewDeleteAlert.frame.size.width/4, 60)];
        [buttonConfirmDelete setTitle:@"Delete" forState:UIControlStateNormal];
        [buttonConfirmDelete addTarget:self action:@selector(deleteAsset) forControlEvents:UIControlEventTouchUpInside];
        [buttonConfirmDelete setBackgroundColor:[UIColor blackColor]];
        [viewDeleteAlert addSubview:buttonConfirmDelete];
    } else {
        [buttonCancelDelete setFrame:CGRectMake(offset, viewDeleteAlert.frame.size.height/2, viewDeleteAlert.frame.size.width/2, 60)];
        [buttonCancelDelete setTitle:@"Dismiss" forState:UIControlStateNormal];
    }
}

- (void)dismissDeleteAlert
{
    [viewDeleteAlert removeFromSuperview];
    viewDeleteAlert = nil;
}

- (void)deleteAsset
{
    //NSLog(@"DELETE!!");
    int assetCount = [assetsGroup numberOfAssets];
    [assetsGroup enumerateAssetsAtIndexes:[NSIndexSet indexSetWithIndex:curIndex] options:0 usingBlock: ^(ALAsset *asset, NSUInteger index, BOOL *stop) {
        if (asset) {
            if (asset.editable) {
                [asset setImageData:nil metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
                    if (error) {
                        NSLog(@"Asset url %@ should be deleted. (Error %@)", assetURL, error);
                    } else {
                        if (assetCount == 1) {
                            dispatch_async(dispatch_get_main_queue(),
                                           ^{
                                               [self showMedia:YES];
                                           });
                        }
                    }
                }];
            }
        }
    }];
    [self dismissDeleteAlert];
    [self showMedia:YES];
}

/*
- (void)loadAlbumWithName:(NSString *)name
{
    [assetLibrary enumerateGroupsWithTypes:ALAssetsGroupAlbum
                                usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                                    if ([[group valueForProperty:ALAssetsGroupPropertyName] isEqualToString:name]) {
                                        //NSLog(@"found album %@", [group valueForProperty:ALAssetsGroupPropertyName]);
                                        assetsGroup = group;
                                        //NSLog(@"assetGroup is now %@", [assetsGroup valueForProperty:ALAssetsGroupPropertyName]);
                                    }
                                }
                              failureBlock:^(NSError* error) {
                                  NSLog(@"failed to enumerate albums:\nError: %@", [error localizedDescription]);
                              }];
}
 */

- (void)playMovie:(ALAsset*)asset {
    mainMoviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:[[asset defaultRepresentation] url]];
    mainMoviePlayer.shouldAutoplay=YES;
    mainMoviePlayer.controlStyle = MPMovieControlStyleNone;
    [mainMoviePlayer setMovieSourceType: MPMovieSourceTypeFile];
    [mainMoviePlayer setFullscreen:YES animated:YES];
    [mainMoviePlayer prepareToPlay];
    [mainMoviePlayer.view setFrame: CGRectMake(0, 0, self.view.frame.size.height, self.view.frame.size.width)];
    [mainMoviePlayer setScalingMode:MPMovieScalingModeAspectFill];
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
    //NSLog(@"Movie playback finished");
    [mainMoviePlayer stop];
    [mainMoviePlayer.view removeFromSuperview];
    self.mainMoviePlayer = nil;
}

- (void)dimmerTimerFired:(NSTimer *)timer
{
    if (viewViewerControls.alpha > 0.1) {
        [self dimView:0.5 withAlpha:0.1 withView:viewViewerControls withTimer:NO];
    }
}

- (void)dimView:(float)duration withAlpha:(float)alpha withView:(UIView *)view withTimer:(BOOL)showTimer
{
    //NSLog(@"dim the view");
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

- (void)swipeScreenleft:(UISwipeGestureRecognizer *)sgr
{
    //NSLog(@"SWIPED LEFT");
    [self showMedia:YES];
}

- (void)swipeScreenRight:(UISwipeGestureRecognizer *)sgr
{
    //NSLog(@"SWIPED RIGHT");
    [self showMedia:NO];
}

- (void)handleTapAction:(UITapGestureRecognizer *)tgr
{
    if (tgr.state == UIGestureRecognizerStateRecognized) {
        //NSLog(@"VIEWER TAPPED!");
        [self showViewerControls];
        if (mainMoviePlayer) {
            if(mainMoviePlayer.playbackState == MPMoviePlaybackStatePlaying) {
                [mainMoviePlayer pause];
            } else {
                [mainMoviePlayer play];
            }
        }
    }
}

-(void) handleDoubleTapAction:(UITapGestureRecognizer *)tgr
{
        [self showViewerControls];
        CGPoint location = [tgr locationInView:self.view];
        if (location.x < self.view.frame.size.height/2) {
            [self showMedia:NO];
        } else {
            [self showMedia:YES];
        }
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
    int64_t delayInSeconds = 0.01;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self.buttonStealer stopStealingVolumeButtonEvents];
    });
}

- (void)dealloc {
	self.buttonStealer.upBlock = nil;
	self.buttonStealer.downBlock = nil;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscapeLeft;
}


@end
