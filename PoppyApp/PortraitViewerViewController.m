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

@interface PortraitViewerViewController ()
@property (nonatomic, strong) ALAssetsGroup *assetsGroup;
@property (nonatomic, strong) UIImageView *imgView;
@property (nonatomic, strong) UIButton *btnWiggle;
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
    
}

- (void)viewDidAppear:(BOOL)animated
{
    if (!self.imgView) {
        self.imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0,0,320,240)];
        [self.imgView setContentMode: UIViewContentModeScaleAspectFill];
        [self.view addSubview:self.imgView];
        [self addGestures:self.imgView];
        self.imgView.userInteractionEnabled = YES;
    }
    if (!self.btnWiggle) {
        self.btnWiggle = [[UIButton alloc] initWithFrame:CGRectMake(0,240, 320, 80)];
        [self.btnWiggle addTarget:self action:@selector(makeWiggle) forControlEvents:UIControlEventTouchUpInside];
        [self.btnWiggle setTitle:@"Wiggle" forState:UIControlStateNormal];
        [self.view addSubview:self.btnWiggle];
    }
    if (curIndex == -1) {
        [self showMedia:YES];
    }
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
             [self presentViewController:wvc animated:YES completion:nil];
         }
     }];
}

- (void)showMedia:(BOOL)next
{
    // show images only (no video
    
    __block int countPhoto;
    
    countPhoto = 0;
    [self.assetsGroup enumerateAssetsUsingBlock:^(ALAsset *asset, NSUInteger index, BOOL *stop)
     {
         if ([asset valueForProperty:ALAssetPropertyType] == ALAssetTypePhoto) {
             countPhoto++;
         }
     }];
    
    
    if (countPhoto > 0) {
        if(curIndex == -1) {
            curIndex = countPhoto;
        }
        
        if (next) {
            curIndex = curIndex - 1;
        } else {
            curIndex = curIndex + 1;
        }
        
        if(curIndex >= 0 && curIndex < countPhoto) {
            
            UIImage *tempImage = self.imgView.image;
            [self.imgView setImage:nil];
            
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
                     UIImage *fullScreenImage = [UIImage imageWithCGImage:[assetRepresentation fullScreenImage] scale:[assetRepresentation scale] orientation:orientation];
                     //NSLog(@"image stuff, wide: %f height: %f", fullScreenImage.size.width, fullScreenImage.size.height);
                     
                     [self.imgView setImage:fullScreenImage];
                     [self.imgView setHidden:NO];
                     
                     // Animate the old image away
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
                     
                     *stop = YES;
                 }
             }];
            //[self showViewerControls];
        } else {
            if (curIndex < 0) {
                curIndex = 0;
            } else {
                curIndex = countPhoto - 1;
            }
        }
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
