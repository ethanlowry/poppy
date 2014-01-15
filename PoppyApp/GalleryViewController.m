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

@synthesize displayView;
@synthesize imgView;
@synthesize frameHeight;
@synthesize frameWidth;

@synthesize buttonStealer;
@synthesize viewLoadingLabel;
@synthesize imageArray;
@synthesize viewViewerControls;

int imageIndex;
NSTimer *timerDimmer;

@synthesize showPopular;

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
    [self.view setBackgroundColor:[UIColor darkGrayColor]];
    
    imageArray = [[NSMutableArray alloc] init];
    
    NSString *sort = showPopular ? @"top" : @"recent";
    NSString *uuid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];;
    NSString *urlString = [NSString stringWithFormat:@"http://poppy3d.com/app/media_item/get.json?uuid=%@&sort=%@", uuid, sort];
    
    NSURL *url = [NSURL URLWithString:urlString];
    [self loadJSON:url];
}

- (void) loadJSON:(NSURL *)url
{
    NSURLRequest *request = [NSURLRequest requestWithURL:url
                                             cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                         timeoutInterval:30.0];
    // Get the data
    NSURLResponse *response;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
    
    // Now create an array from the JSON data
    NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];

    // Iterate through the array of dictionaries
    NSLog(@"Array count: %d", jsonArray.count);
    for (NSDictionary *item in jsonArray) {
        NSLog(@"%@", item);
        NSURL *imageURL = [NSURL URLWithString:item[@"media_url"]];
        [imageArray addObject:imageURL];
    }
    imageIndex = -1;
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
            [weakSelf goHome];
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
    [self.view addSubview:displayView];
    
    imgView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    [imgView setContentMode:UIViewContentModeScaleAspectFill];
    [displayView addSubview:imgView];
    
    viewLoadingLabel = [[UIView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width/2, (self.view.bounds.size.height - 150)/2, self.view.bounds.size.width/2, 75)];
    [viewLoadingLabel setAutoresizingMask: UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin];
    UIView *viewShadow = [[UIView alloc] initWithFrame:viewLoadingLabel.bounds];
    [viewShadow setBackgroundColor:[UIColor blackColor]];
    [viewShadow setAlpha:0.3];
    UILabel *loadingLabel = [[UILabel alloc] initWithFrame:viewLoadingLabel.bounds];
    [loadingLabel setText:@"Loading..."];
    [loadingLabel setTextColor:[UIColor whiteColor]];
    [loadingLabel setTextAlignment:NSTextAlignmentCenter];
    [viewLoadingLabel addSubview:viewShadow];
    [viewLoadingLabel addSubview:loadingLabel];
    [viewLoadingLabel setHidden:YES];
    [self.view addSubview:viewLoadingLabel];
    
    UIView *touchView = [[UIView alloc] initWithFrame:self.view.bounds];
    [self addGestures:touchView];
    [displayView addSubview:touchView];
    
    [self showViewerControls];
    
    [self showMedia:NO];
}

- (void)showViewerControls
{
    if (!viewViewerControls)
    {
        viewViewerControls = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 75, self.view.bounds.size.width, self.view.bounds.size.height)];
        [viewViewerControls setAutoresizingMask: UIViewAutoresizingFlexibleTopMargin];
        [self addViewerControlsContent];
        [self.view addSubview:viewViewerControls];
    }
    [self dimView:0.5 withAlpha:1.0 withView:viewViewerControls withTimer:YES];
}

- (void)addViewerControlsContent
{
    UIView *viewShadow = [[UIView alloc] initWithFrame:CGRectMake(viewViewerControls.bounds.size.width/2,0,viewViewerControls.bounds.size.width/2,75)];
    [viewShadow setBackgroundColor:[UIColor blackColor]];
    [viewShadow setAlpha:0.3];
    [self addGestures:viewShadow];
    
    UIButton *buttonHome = [[UIButton alloc] initWithFrame: CGRectMake(viewViewerControls.frame.size.width - 70,0,70,75)];
    [buttonHome setImage:[UIImage imageNamed:@"home"] forState:UIControlStateNormal];
    [buttonHome addTarget:self action:@selector(goHome) forControlEvents:UIControlEventTouchUpInside];
    
    [viewViewerControls addSubview: viewShadow];
    [viewViewerControls addSubview: buttonHome];
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
    [self showMedia:NO];
}

- (void)swipeScreenRight:(UISwipeGestureRecognizer *)sgr
{
    NSLog(@"show previous");
    [self showMedia:YES];
}

- (void)handleTapAction:(UITapGestureRecognizer *)tgr
{
    if (tgr.state == UIGestureRecognizerStateRecognized) {
        CGPoint location = [tgr locationInView:self.view];
        if (location.x < self.view.frame.size.height/2) {
            [self showMedia:YES];
        } else {
            [self showMedia:NO];
        }
    }
    [self dimView:0.5 withAlpha:1.0 withView:viewViewerControls withTimer:YES];
}

- (void) showMedia:(BOOL)previous
{
    if (imageArray && imageArray.count > 0) {
        if (previous) {
            imageIndex = imageIndex - 1;
            if (imageIndex < 0) {
                imageIndex = imageArray.count - 1;
            }
        } else {
            imageIndex = imageIndex + 1;
            if (imageIndex >= imageArray.count) {
                imageIndex = 0;
            }
        }
        NSLog(@"Image Index: %d", imageIndex);
        
        [viewLoadingLabel setHidden:NO];
        NSOperationQueue *queue = [NSOperationQueue new];
        NSInvocationOperation *operation = [[NSInvocationOperation alloc]
                                            initWithTarget:self
                                            selector:@selector(loadImage)
                                            object:nil];
        [queue addOperation:operation];
    } else {
        NSLog(@"NO MEDIA");
    }
}

- (void)goHome
{
    [buttonStealer stopStealingVolumeButtonEvents];
    [self dismissViewControllerAnimated:YES completion:^{}];
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

- (void)dimmerTimerFired:(NSTimer *)timer
{
    if (viewViewerControls.alpha > 0.1) {
        [self dimView:0.5 withAlpha:0.1 withView:viewViewerControls withTimer:NO];
    }
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscapeLeft;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadImage {
    NSURL* url = imageArray[imageIndex];
    NSData* imageData = [[NSData alloc] initWithContentsOfURL:url];
    UIImage* image = [[UIImage alloc] initWithData:imageData];
    [self performSelectorOnMainThread:@selector(displayImage:) withObject:image waitUntilDone:NO];
}

- (void)displayImage:(UIImage *)image {
    [viewLoadingLabel setHidden:YES];
    [imgView setImage:image];
}


@end
