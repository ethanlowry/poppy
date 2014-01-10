//
//  GalleryViewController.m
//  Poppy
//
//  Created by Ethan Lowry on 1/3/14.
//  Copyright (c) 2014 Ethan Lowry. All rights reserved.
//

#import "GalleryViewController.h"

@interface GalleryViewController ()

@end

@implementation GalleryViewController

@synthesize galleryArray;
@synthesize galleryListView;
@synthesize displayView;
@synthesize imgView;
@synthesize frameHeight;
@synthesize frameWidth;
@synthesize assetLibrary;
@synthesize assetsGroup;
@synthesize assetCount;
@synthesize currentAsset;
@synthesize mainMoviePlayer;
@synthesize buttonStealer;
@synthesize loadingLabel;

bool odd = YES;

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
    
    assetLibrary = [[ALAssetsLibrary alloc] init];
    
    galleryArray = [[NSMutableArray alloc] initWithObjects: @"WEB", @"Made on Poppy", @"3D Video", @"Miscellaneous", @"Queen", @"Stereo Cards", nil];
    
	// Do any additional setup after loading the view.
}

- (void)activateButtonStealer
{
    NSLog(@"ACTIVATING BUTTON STEALER");
    if (!buttonStealer) {
        __weak typeof(self) weakSelf = self;
        buttonStealer = [[RBVolumeButtons alloc] init];
        buttonStealer.upBlock = ^{
            // + volume button pressed
            NSLog(@"volume button pressed");
            [weakSelf returnToViewer];
        };
    }
    
    [buttonStealer startStealingVolumeButtonEvents];
}

- (void)viewDidAppear:(BOOL)animated
{
    frameWidth = self.view.frame.size.height/2;
    frameHeight = self.view.frame.size.width;
    [self activateButtonStealer];
    
    displayView = [[UIView alloc] initWithFrame:self.view.bounds];
    [displayView setHidden:YES];
    [self.view addSubview:displayView];
    
    imgView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    [displayView addSubview:imgView];
    
    loadingLabel = [[UILabel alloc] initWithFrame:self.view.bounds];
    [loadingLabel setTextColor:[UIColor whiteColor]];
    [self.view addSubview:loadingLabel];
    
    UIView *touchView = [[UIView alloc] initWithFrame:self.view.bounds];
    [self addGestures:touchView];
    [displayView addSubview:touchView];
    
    [self.view setBackgroundColor:[UIColor blackColor]];
    
    galleryListView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frameWidth*2, frameHeight)];
    [self.view addSubview:galleryListView];
    
    for(int j = 0;j < 2;j++){
        //add the Poppy 3D Galleries title
        UILabel *label = [[UILabel alloc] initWithFrame: CGRectMake(frameWidth*j + 30, 20, frameWidth - 30, 40)];
        [label setFont:[UIFont boldSystemFontOfSize:24]];
        [label setTextColor:[UIColor whiteColor]];
        [label setText:@"Poppy Galleries"];
        [galleryListView addSubview:label];
        
        //add the "return to normal" button
        UIButton *button = [[UIButton alloc] initWithFrame: CGRectMake(frameWidth*j + 30, 60, frameWidth - 30, 40)];
        [button setTitle:@"View your images" forState:UIControlStateNormal];
        [button setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
        [button addTarget:self action:@selector(returnToViewer) forControlEvents:UIControlEventTouchUpInside];
        [galleryListView addSubview:button];
        UIImageView *listArrow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"listArrow"]];
        [listArrow setFrame: CGRectMake(frameWidth*(j+1) - 40, 73, 10, 15)];
        [galleryListView addSubview:listArrow];
    }
    
    //add the gallery buttons
    for (int i = 0; i < galleryArray.count; i++) {
        [self addItem:i];
    }
}

- (void)addItem:(int)i
{
    for (int j = 0;j < 2;j++){
        UIImageView *listArrow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"listArrow"]];
        [listArrow setFrame: CGRectMake(frameWidth*(j+1) - 40, i * 40 + 113, 10, 15)];
        [galleryListView addSubview:listArrow];
        UIButton *button = [[UIButton alloc] initWithFrame: CGRectMake(frameWidth*j + 30, i * 40 + 100, frameWidth - 30, 40)];
        [button setTitle:[galleryArray objectAtIndex:i] forState:UIControlStateNormal];
        [button setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
        [button addTarget:self action:@selector(showGallery:) forControlEvents:UIControlEventTouchUpInside];
        [galleryListView addSubview:button];
    }
}

- (void)showGallery:(id)sender
{
    UIButton *button = (UIButton*)sender;
    NSString *title = button.titleLabel.text;
    currentAsset = -1;
    assetCount = 0;
    [self loadAlbumWithName:title];
    [galleryListView setHidden:YES];
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
    
}

- (void)hideGallery
{
    [galleryListView setHidden:NO];
    [displayView setHidden:YES];
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

- (void)swipeScreenleft:(UISwipeGestureRecognizer *)sgr
{
    NSLog(@"show next");
    [self showNext];
}

- (void)swipeScreenRight:(UISwipeGestureRecognizer *)sgr
{
    NSLog(@"show previous");
    [self showPrev];
}

- (void)handleTapAction:(UITapGestureRecognizer *)tgr
{
    if (tgr.state == UIGestureRecognizerStateRecognized) {
        CGPoint location = [tgr locationInView:self.view];
        if (location.x < self.view.frame.size.height/2) {
            [self showPrev];
        } else {
            [self showNext];
        }
    }
}

- (void)showNext {
    if (mainMoviePlayer) {
        [self.mainMoviePlayer stop];
        [self.mainMoviePlayer.view removeFromSuperview];
        self.mainMoviePlayer = nil;
    }
    currentAsset = currentAsset + 1;
    NSLog(@"Current: %d Total: %d", currentAsset, assetCount);
    if (currentAsset >= assetCount) {
        //hide the image, show the list
        if (!assetsGroup) {
            [self showAsset];
        } else {
            [self hideGallery];
        }
    } else {
        [self showAsset];
    }
}

- (void)showPrev {
    if (mainMoviePlayer) {
        [self.mainMoviePlayer stop];
        [self.mainMoviePlayer.view removeFromSuperview];
        self.mainMoviePlayer = nil;
    }
    currentAsset = currentAsset - 1;
    if (currentAsset < 0) {
        //hide the image, show the list
        [self hideGallery];
    } else {
        [self showAsset];
    }
}

- (void) showAsset
{
    if (assetCount > 0) {
        [assetsGroup enumerateAssetsAtIndexes:[NSIndexSet indexSetWithIndex:currentAsset] options:0 usingBlock: ^(ALAsset *asset, NSUInteger index, BOOL *stop)
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
                 
                 [imgView setImage:fullScreenImage];
                 [displayView setHidden:NO];
                 
                 if ([asset valueForProperty:ALAssetPropertyType] == ALAssetTypeVideo) {
                     NSLog(@"It's a video");
                     [self playMovie:asset];
                 } else {
                     NSLog(@"It's a photo");
                 }
             }
         }];
    } else {
        NSLog(@"NO IMAGES IN THE ALBUM");
        if (!assetsGroup) {
            [loadingLabel setText:@"Loading..."];
            NSOperationQueue *queue = [NSOperationQueue new];
            NSInvocationOperation *operation = [[NSInvocationOperation alloc]
                                                initWithTarget:self
                                                selector:@selector(loadImage)
                                                object:nil];
            [queue addOperation:operation];
        }
    }
}

- (void)loadAlbumWithName:(NSString *)name
{
    if ([name isEqualToString:@"WEB"]) {
        NSLog(@"WEB Album");
        assetsGroup = nil;
        assetCount = 0;
        [self showNext];
    } else {
    [assetLibrary enumerateGroupsWithTypes:ALAssetsGroupAlbum
                                usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                                    if ([[group valueForProperty:ALAssetsGroupPropertyName] isEqualToString:name]) {
                                        NSLog(@"found album %@", [group valueForProperty:ALAssetsGroupPropertyName]);
                                        assetsGroup = group;
                                        NSLog(@"assetGroup is now %@", [assetsGroup valueForProperty:ALAssetsGroupPropertyName]);
                                        assetCount = [assetsGroup numberOfAssets];
                                        NSLog(@"ALBUM: %@ COUNT: %d", name, assetCount);
                                        [self showNext];
                                    }
                                }
                              failureBlock:^(NSError* error) {
                                  NSLog(@"failed to enumerate albums:\nError: %@", [error localizedDescription]);
                              }];
    }
}

- (void)returnToViewer
{
    [self.mainMoviePlayer stop];
    self.mainMoviePlayer = nil;
    [buttonStealer stopStealingVolumeButtonEvents];
    //self.buttonStealer = nil;
    [self dismissViewControllerAnimated:YES completion:^{}];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadImage {
    NSString *url;
    if (odd) {
        url = @"http://poppy3d.com.s3.amazonaws.com/gallery/Food/Oreos.jpg";
        odd = NO;
    } else {
        url = @"http://poppy3d.com.s3.amazonaws.com/gallery/Food/Garlic.JPG";
        odd = YES;
    }
    NSData* imageData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:url]];
    UIImage* image = [[UIImage alloc] initWithData:imageData];
    [self performSelectorOnMainThread:@selector(displayImage:) withObject:image waitUntilDone:NO];
}

- (void)displayImage:(UIImage *)image {
    [loadingLabel setText:@""];
    [imgView setImage:image];
    [displayView setHidden:NO];
}


@end
