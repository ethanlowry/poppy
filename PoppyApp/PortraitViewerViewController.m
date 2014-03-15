//
//  PortraitViewerViewController.m
//  Poppy
//
//  Created by Ethan Lowry on 2/25/14.
//  Copyright (c) 2014 Ethan Lowry. All rights reserved.
//

#import "PortraitViewerViewController.h"
#import "PODAssetsManager.h"
#import "WiggleViewController.h"
#import "UIImage+Resize.h"
#import "AppDelegate.h"

@interface PortraitViewerViewController ()
@property (nonatomic, strong) ALAssetsGroup *assetsGroup;
@property (nonatomic, strong) UIImageView *imgView;
@property (nonatomic, strong) UIButton *btnWiggle;
@property (nonatomic, strong) UIButton *btnShare;
@property (nonatomic, strong) UIButton *btnHome;
@property (nonatomic, strong) UIButton *btnDelete;
@property (nonatomic, strong) UIView *viewDeleteAlert;
@property (nonatomic) int minGoodAsset;
@property (nonatomic) int maxGoodAsset;
@end

@implementation PortraitViewerViewController
int curIndex;

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
        [self performSelector:@selector(updateLandscapeView) withObject:nil afterDelay:0];
    }
}

- (void)updateLandscapeView
{
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    
    if(deviceOrientation == UIDeviceOrientationLandscapeRight){
        AppDelegate *poppyAppDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        poppyAppDelegate.switchToViewer = YES;
        poppyAppDelegate.currentAssetIndex = curIndex;
        [self dismissViewControllerAnimated:NO completion:^{}];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    // get poppy album
	[[PODAssetsManager assetsManager] ensuredAssetsAlbumNamed:@"Poppy" completion:^(ALAssetsGroup *group, NSError *anError) {
		if (group) {
			self.assetsGroup = group;
		}
	}];
    curIndex = -1;
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationChanged:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    AppDelegate *poppyAppDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [poppyAppDelegate makeScreenBrightnessNormal];
    
    [self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"background"]]];
    UIImageView *imgLogo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo_white"]];
    [imgLogo setFrame:CGRectMake((self.view.bounds.size.width -200)/2,20,200,40)];
    [self.view addSubview:imgLogo];
    
    if (!self.btnHome) {
        self.btnHome = [[UIButton alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - 60,self.view.bounds.size.height - 60,60,60)];
        [self.btnHome setImage:[UIImage imageNamed:@"home"] forState:UIControlStateNormal];
        [self.btnHome addTarget:self action:@selector(dismissAction) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:self.btnHome];
    }
    if(!self.btnShare) {
        self.btnShare = [[UIButton alloc] initWithFrame:CGRectMake(0,self.view.bounds.size.height - 60,60,60)];
        [self.btnShare setImage:[UIImage imageNamed:@"sharing"] forState:UIControlStateNormal];
        [self.btnShare addTarget:self action:@selector(showSharingLink) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:self.btnShare];
    }
    if(!self.btnDelete) {
        self.btnDelete = [[UIButton alloc] initWithFrame: CGRectMake((self.view.bounds.size.width - 60)/2,self.view.bounds.size.height - 60,60,60)];
        [self.btnDelete  setImage:[UIImage imageNamed:@"trash"] forState:UIControlStateNormal];
        [self.btnDelete  addTarget:self action:@selector(showDeleteAssetAlert) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:self.btnDelete];
    }
    
    if (!self.imgView) {
        self.imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0,80,320,280)];
        [self.imgView setContentMode: UIViewContentModeScaleAspectFill];
        //[self.imgView setClipsToBounds:YES];
        [self.view addSubview:self.imgView];
        [self addGestures:self.imgView];
        self.imgView.userInteractionEnabled = YES;
    }
    if (!self.btnWiggle) {
        float topOfButton = self.imgView.bounds.origin.y + self.imgView.bounds.size.height + (self.view.bounds.size.height - self.imgView.bounds.size.height - self.btnHome.bounds.size.height + 20)/2;
        CGRect wiggleFrame = CGRectMake((self.view.bounds.size.width - 240)/2,topOfButton, 240, 60);
        UIView *wiggleShadowView = [[UIView alloc] initWithFrame:wiggleFrame];
        [wiggleShadowView setBackgroundColor:[UIColor grayColor]];
        [wiggleShadowView setAlpha:0.3];
        [self.view addSubview:wiggleShadowView];
        
        self.btnWiggle = [[UIButton alloc] initWithFrame:wiggleFrame];
        [self.btnWiggle addTarget:self action:@selector(makeWiggle) forControlEvents:UIControlEventTouchUpInside];
        //[self.btnWiggle setBackgroundColor:[UIColor blackColor]];
        [self.btnWiggle setTitle:@"Make a Poppy GIF" forState:UIControlStateNormal];
        [self.view addSubview:self.btnWiggle];
    }
    
    if (curIndex == -1) {
        [self showMedia:YES];
    }
}

- (void)showDeleteAssetAlert
{
    if(self.assetsGroup.numberOfAssets > 0) {
        if (!self.viewDeleteAlert) {
            self.viewDeleteAlert = [[UIView alloc] initWithFrame:self.view.bounds];
            
            UIView *viewShadow = [[UIView alloc] initWithFrame:self.view.bounds];
            viewShadow.backgroundColor = [UIColor blackColor];
            viewShadow.alpha = 0.6;
            UITapGestureRecognizer *handleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissDeleteAlert)];
            [viewShadow addGestureRecognizer:handleTap];
            [self.viewDeleteAlert addSubview:viewShadow];
            
            UILabel *deleteLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0,(self.viewDeleteAlert.frame.size.height - 120)/2,self.viewDeleteAlert.frame.size.width,60)];
            [deleteLabel setTextAlignment:NSTextAlignmentCenter];
            [deleteLabel setBackgroundColor:[UIColor blackColor]];
            [deleteLabel setTextColor:[UIColor whiteColor]];
            CALayer *bottomBorder = [CALayer layer];
            bottomBorder.frame = CGRectMake(40, 59, deleteLabel.frame.size.width-80, 1.0);
            bottomBorder.backgroundColor = [UIColor whiteColor].CGColor;
            [deleteLabel.layer addSublayer:bottomBorder];

            
            [self.viewDeleteAlert addSubview:deleteLabel];
            [self.assetsGroup enumerateAssetsAtIndexes:[NSIndexSet indexSetWithIndex:curIndex] options:0 usingBlock: ^(ALAsset *asset, NSUInteger index, BOOL *stop) {
                if (asset) {
                    if (asset.editable && ([asset valueForProperty:ALAssetPropertyType] == ALAssetTypePhoto)) {
                        [deleteLabel setText: @"Delete this photo?"];
                        [self addDeleteButtons:YES];
                        *stop = YES;
                    } else {
                        [deleteLabel setText: @"This photo can't be deleted"];
                        [self addDeleteButtons:NO];
                        *stop = YES;
                    }
                }
            }];
        }
        
        [self.view addSubview:self.viewDeleteAlert];
        [self.view bringSubviewToFront:self.viewDeleteAlert];
    }
}

- (void)addDeleteButtons:(BOOL)showDelete
{
    UIButton *buttonCancelDelete = [[UIButton alloc] init];
    [buttonCancelDelete addTarget:self action:@selector(dismissDeleteAlert) forControlEvents:UIControlEventTouchUpInside];
    [buttonCancelDelete.titleLabel setTextAlignment:NSTextAlignmentRight];
    [buttonCancelDelete setBackgroundColor:[UIColor blackColor]];
    [self.viewDeleteAlert addSubview:buttonCancelDelete];
    
    if(showDelete){
        [buttonCancelDelete setFrame:CGRectMake(self.viewDeleteAlert.frame.size.width/2, self.viewDeleteAlert.frame.size.height/2, self.viewDeleteAlert.frame.size.width/2, 60)];
        [buttonCancelDelete setTitle:@"Cancel" forState:UIControlStateNormal];
        
        UIButton *buttonConfirmDelete = [[UIButton alloc] initWithFrame:CGRectMake(0,self.viewDeleteAlert.frame.size.height/2, self.viewDeleteAlert.frame.size.width/2, 60)];
        [buttonConfirmDelete setTitle:@"Delete" forState:UIControlStateNormal];
        [buttonConfirmDelete addTarget:self action:@selector(deleteAsset) forControlEvents:UIControlEventTouchUpInside];
        [buttonConfirmDelete setBackgroundColor:[UIColor blackColor]];
        [self.viewDeleteAlert addSubview:buttonConfirmDelete];
    } else {
        [buttonCancelDelete setFrame:CGRectMake(0, self.viewDeleteAlert.frame.size.height/2, self.viewDeleteAlert.frame.size.width, 60)];
        [buttonCancelDelete setTitle:@"Dismiss" forState:UIControlStateNormal];
    }
}

- (void)dismissDeleteAlert
{
    [self.viewDeleteAlert removeFromSuperview];
}

- (void)deleteAsset
{
    [self.assetsGroup enumerateAssetsAtIndexes:[NSIndexSet indexSetWithIndex:curIndex] options:0 usingBlock: ^(ALAsset *asset, NSUInteger index, BOOL *stop) {
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
    [self dismissDeleteAlert];
    [self showMedia:YES];
}


-(void)showSharingLink
{
    [self.assetsGroup enumerateAssetsAtIndexes:[NSIndexSet indexSetWithIndex:curIndex] options:0 usingBlock: ^(ALAsset *asset, NSUInteger index, BOOL *stop)
     {
         if (asset) {
             //NSLog(@"got the asset: %d", index);
             ALAssetRepresentation *assetRepresentation = [asset defaultRepresentation];
             UIImageOrientation orientation = UIImageOrientationUp;
             NSNumber* orientationValue = [asset valueForProperty:@"ALAssetPropertyOrientation"];
             if (orientationValue != nil) {
                 orientation = [orientationValue intValue];
             }
             UIImage *stereoImage = [UIImage imageWithCGImage:[assetRepresentation fullResolutionImage] scale:[assetRepresentation scale] orientation:orientation];
             
             NSMutableArray *sharingItems = [NSMutableArray new];
             [sharingItems addObject:stereoImage];
             [sharingItems addObject:@"#poppy3d"];
             UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:sharingItems applicationActivities:nil];
             [self presentViewController:activityController animated:YES completion:nil];
         }
     }];
}

-(void)dismissAction
{
    [self dismissViewControllerAnimated:YES completion:^{}];
}

- (void)makeWiggle
{
    [self.assetsGroup enumerateAssetsAtIndexes:[NSIndexSet indexSetWithIndex:curIndex] options:0 usingBlock: ^(ALAsset *asset, NSUInteger index, BOOL *stop)
     {
         if (asset) {
             //NSLog(@"got the asset: %d", index);
             ALAssetRepresentation *assetRepresentation = [asset defaultRepresentation];
             UIImageOrientation orientation = UIImageOrientationUp;
             NSNumber* orientationValue = [asset valueForProperty:@"ALAssetPropertyOrientation"];
             if (orientationValue != nil) {
                 orientation = [orientationValue intValue];
             }
             UIImage *stereoImage = [UIImage imageWithCGImage:[assetRepresentation fullResolutionImage] scale:[assetRepresentation scale] orientation:orientation];
             
             WiggleViewController *wvc = [[WiggleViewController alloc] initWithNibName:nil bundle:nil];
             wvc.stereoImage = stereoImage;
             wvc.assetURL = [asset valueForProperty:ALAssetPropertyAssetURL];
             [self presentViewController:wvc animated:YES completion:nil];
         }
     }];
}

- (void)showMedia:(BOOL)next
{
    // show images only (no video)
    
    __block int countPhoto;
    
    countPhoto = 0;
    self.minGoodAsset = -1;
    [self.assetsGroup enumerateAssetsUsingBlock:^(ALAsset *asset, NSUInteger index, BOOL *stop)
     {
         if ([asset valueForProperty:ALAssetPropertyType] == ALAssetTypePhoto) {
             countPhoto++;
             if (self.minGoodAsset < 0) {
                 self.minGoodAsset = (int)index;
             }
             self.maxGoodAsset = (int)index;
         }
     }];
    
    if (countPhoto > 0) {
        int assetCount  = (int)[self.assetsGroup numberOfAssets];
        if(curIndex == -1) {
            curIndex = assetCount;
        }
        
        if (next) {
            curIndex = curIndex - 1;
            if (curIndex < self.minGoodAsset) {
                curIndex = self.minGoodAsset;
            }
        } else {
            curIndex = curIndex + 1;
            if (curIndex > self.maxGoodAsset) {
                curIndex = self.maxGoodAsset;
            }
        }
        
        // if we got here through device rotation, overwrite the current index
        AppDelegate *poppyAppDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        if (poppyAppDelegate.currentAssetIndex >= 0) {
            curIndex = poppyAppDelegate.currentAssetIndex;
            poppyAppDelegate.currentAssetIndex = -1;
        }
        
        if(curIndex >= 0 && curIndex < assetCount) {
            UIImage *tempImage = self.imgView.image;
            [self.imgView setImage:nil];
            
            [self.assetsGroup enumerateAssetsAtIndexes:[NSIndexSet indexSetWithIndex:curIndex] options:0 usingBlock: ^(ALAsset *asset, NSUInteger index, BOOL *stop)
             {
                 if (asset) {
                     if ([asset valueForProperty:ALAssetPropertyType] == ALAssetTypePhoto) {
                         //NSLog(@"got the asset: %d", index);
                         ALAssetRepresentation *assetRepresentation = [asset defaultRepresentation];
                         UIImageOrientation orientation = UIImageOrientationUp;
                         NSNumber* orientationValue = [asset valueForProperty:@"ALAssetPropertyOrientation"];
                         if (orientationValue != nil) {
                             orientation = [orientationValue intValue];
                         }
                         UIImage *fullScreenImage = [UIImage imageWithCGImage:[assetRepresentation fullScreenImage] scale:[assetRepresentation scale] orientation:orientation];
                         //NSLog(@"image stuff, wide: %f height: %f", fullScreenImage.size.width, fullScreenImage.size.height);
                         
                         [self.imgView setImage:fullScreenImage];
                         [self.imgView setHidden:NO];
                         
                         // Animate the old image away
                         if (index != self.minGoodAsset && index != self.maxGoodAsset) {
                             if (tempImage) {
                                 float xPosition = next ? -self.imgView.frame.size.width : self.imgView.frame.size.width;
                                 UIImageView *animatedImgView = [[UIImageView alloc] initWithFrame:self.imgView.frame];
                                 [animatedImgView setImage:tempImage];
                                 [animatedImgView setContentMode:UIViewContentModeScaleAspectFill];
                                 [self.view addSubview:animatedImgView];
                                 
                                 CGRect finalFrame = animatedImgView.frame;
                                 finalFrame.origin.x = xPosition;
                                 [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{ animatedImgView.frame = finalFrame; } completion:^(BOOL finished){
                                     [animatedImgView removeFromSuperview];
                                     
                                 }];
                             }
                         }
                         *stop = YES;
                     } else {
                         [self showMedia:next];
                     }
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
    }
    else {
        self.imgView.image = nil;
    }
    
}

- (void)addGestures:(UIView *)touchView
{
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


- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
