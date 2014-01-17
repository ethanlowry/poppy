//
//  GalleryViewController.m
//  Poppy
//
//  Created by Ethan Lowry on 1/3/14.
//  Copyright (c) 2014 Ethan Lowry. All rights reserved.
//

#import "GalleryViewController.h"
#import "AppDelegate.h"

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

@synthesize imgSourceL;
@synthesize imgSourceR;
@synthesize labelAttributionL;
@synthesize labelAttributionR;
@synthesize viewAttribution;

@synthesize buttonFavorite;

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
    
    AppDelegate *poppyAppDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSLog(@"top count: %d", poppyAppDelegate.topImageArray.count);
    NSLog(@"recent count: %d", poppyAppDelegate.recentImageArray.count);
    
    imageArray = showPopular ? poppyAppDelegate.topImageArray : poppyAppDelegate.recentImageArray;
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
    for (NSMutableDictionary *item in jsonArray) {
        [imageArray addObject:item];
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
    imageIndex = -1;
    
    frameWidth = self.view.frame.size.height/2;
    frameHeight = self.view.frame.size.width;
    [self activateButtonStealer];
    
    displayView = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:displayView];
    
    imgView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    [imgView setContentMode:UIViewContentModeScaleAspectFill];
    [displayView addSubview:imgView];
    
    viewAttribution = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frameWidth * 2, 30)];
    UIView *viewAttrShadow = [[UIView alloc] initWithFrame:viewAttribution.frame];
    [viewAttrShadow setAlpha:0.3];
    [viewAttrShadow setBackgroundColor:[UIColor blackColor]];
    [viewAttribution addSubview:viewAttrShadow];
    
    imgSourceL = [[UIImageView alloc] initWithFrame:CGRectMake(10, 5, 20, 20)];
    imgSourceR = [[UIImageView alloc] initWithFrame:CGRectMake(frameWidth + 10, 5, 20, 20)];
    labelAttributionL = [[UILabel alloc] initWithFrame:CGRectMake(40, 5, frameWidth - 40, 20)];
    labelAttributionR = [[UILabel alloc] initWithFrame:CGRectMake(frameWidth + 40, 5, frameWidth - 40, 20)];
    [labelAttributionL setFont:[UIFont systemFontOfSize:12]];
    [labelAttributionL setTextColor:[UIColor whiteColor]];
    [labelAttributionR setFont:[UIFont systemFontOfSize:12]];
    [labelAttributionR setTextColor:[UIColor whiteColor]];
    [viewAttribution addSubview:imgSourceL];
    [viewAttribution addSubview:imgSourceR];
    [viewAttribution addSubview:labelAttributionL];
    [viewAttribution addSubview:labelAttributionR];
    [displayView addSubview:viewAttribution];
    
    viewLoadingLabel = [[UIView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width/2, (self.view.bounds.size.height - 130)/2, self.view.bounds.size.width/2, 75)];
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
    
    if (imageArray && imageIndex >= 0 && [imageArray[imageIndex][@"favorited"] isEqualToString:@"true"]) {
        [buttonFavorite setImage:[UIImage imageNamed:@"is_favorite"] forState:UIControlStateNormal];
    } else {
        [buttonFavorite setImage:[UIImage imageNamed:@"favorite"] forState:UIControlStateNormal];
    }
    
    NSLog(@"showing viewer controls");
    [self dimView:0.5 withAlpha:1.0 withView:viewAttribution withTimer:NO];
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
    
    buttonFavorite = [[UIButton alloc] initWithFrame: CGRectMake(viewViewerControls.frame.size.width - 230,0,70,75)];
    [buttonFavorite setImage:[UIImage imageNamed:@"favorite"] forState:UIControlStateNormal];
    [buttonFavorite addTarget:self action:@selector(markFavorite) forControlEvents:UIControlEventTouchUpInside];
    [viewViewerControls addSubview: viewShadow];
    [viewViewerControls addSubview: buttonHome];
    [viewViewerControls addSubview: buttonFavorite];
}

- (void)markFavorite
{
    if (imageArray[imageIndex]){
        NSLog(@"There's a pic to Favorite");
        NSString *uuid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        NSString *item_id = imageArray[imageIndex][@"_id"];
        NSString *addText;
        NSString *favorited;
        if ([imageArray[imageIndex][@"favorited"] isEqualToString:@"false"]) {
            addText = @"add";
            favorited = @"true";
        } else {
            addText = @"remove";
            favorited = @"false";
        }
        NSString *urlString = [NSString stringWithFormat:@"http://poppy3d.com/app/action/post.json?uuid=%@&media_item_id=%@&action=favorite&v=%@", uuid, item_id, addText];
        
        NSURL *url = [NSURL URLWithString:urlString];
        
        NSLog(@"URL: %@", url);
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                               cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                           timeoutInterval:30.0];
        
        [request setHTTPMethod:@"POST"];
        NSURLResponse *response;
        [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
        //NSLog(@"RESPONSE: %@", response);
        
        //Now update the "favorited" value to reflect the change
        NSMutableDictionary *newItem = [[NSMutableDictionary alloc] init];
        NSDictionary *oldItem = (NSDictionary *)[imageArray objectAtIndex:imageIndex];
        [newItem addEntriesFromDictionary:oldItem];
        [newItem setObject:favorited forKey:@"favorited"];
        [imageArray replaceObjectAtIndex:imageIndex withObject:newItem];

        [self showViewerControls];
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

- (void)swipeScreenleft:(UISwipeGestureRecognizer *)sgr
{
    NSLog(@"show next");
    [self showMedia:NO];
    [self showViewerControls];
}

- (void)swipeScreenRight:(UISwipeGestureRecognizer *)sgr
{
    NSLog(@"show previous");
    [self showMedia:YES];
    [self showViewerControls];
}

- (void)handleDoubleTapAction:(UITapGestureRecognizer *)tgr
{
    if (tgr.state == UIGestureRecognizerStateRecognized) {
        CGPoint location = [tgr locationInView:self.view];
        if (location.x < self.view.frame.size.height/2) {
            [self showMedia:YES];
        } else {
            [self showMedia:NO];
        }
    }
    [self showViewerControls];
}

- (void)handleTapAction:(UITapGestureRecognizer *)tgr
{
    if (tgr.state == UIGestureRecognizerStateRecognized) {
        [self showViewerControls];
    }
    
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
        [buttonFavorite setImage:[UIImage imageNamed:@"favorite"] forState:UIControlStateNormal];
        NSOperationQueue *queue = [NSOperationQueue new];
        NSInvocationOperation *operation = [[NSInvocationOperation alloc]
                                            initWithTarget:self
                                            selector:@selector(loadAndDisplayCurrentImage)
                                            object:nil];
        [queue addOperation:operation];
        // Now preload the next (or previous) image
        NSInvocationOperation *preload;
        if (previous) {
            preload = [[NSInvocationOperation alloc]
                       initWithTarget:self
                       selector:@selector(loadPreviousImage)
                       object:nil];
        } else {
            preload = [[NSInvocationOperation alloc]
                       initWithTarget:self
                       selector:@selector(loadNextImage)
                       object:nil];
        }
        [queue addOperation:preload];
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
                             timerDimmer = [NSTimer scheduledTimerWithTimeInterval:2.5 target:self selector:@selector(dimmerTimerFired:) userInfo:nil repeats:NO];
                         }
                     }];
}

- (void)dimmerTimerFired:(NSTimer *)timer
{
    if (viewViewerControls.alpha > 0.1) {
        [self dimView:0.5 withAlpha:0.1 withView:viewViewerControls withTimer:NO];
        [self dimView:0.5 withAlpha:0.1 withView:viewAttribution withTimer:NO];
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

- (void)loadAndDisplayCurrentImage
{
    UIImage *image = [self loadImage:imageIndex];
    [self performSelectorOnMainThread:@selector(displayImage:) withObject:image waitUntilDone:NO];
}

- (void)loadNextImage
{
    int index = imageIndex + 1;
    if (index >= imageArray.count) {
        index = 0;
    }
    [self loadImage:index];
}

- (void)loadPreviousImage
{
    int index = imageIndex - 1;
    if (index < 0) {
        index = imageArray.count - 1;
    }
    [self loadImage:index];
}

- (UIImage *)loadImage:(int)index
{
    AppDelegate *poppyAppDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UIImage *image;
    if ([poppyAppDelegate.imageCache objectForKey:imageArray[index][@"_id"]]) {
        // load from the dictionary
        image = [poppyAppDelegate.imageCache objectForKey:imageArray[index][@"_id"]];
    } else {
        // load from the web
        NSURL *imageURL = [NSURL URLWithString:imageArray[index][@"media_url"]];
        NSURL *url = imageURL;
        NSData *imageData = [[NSData alloc] initWithContentsOfURL:url];
        image = [[UIImage alloc] initWithData:imageData];
        [poppyAppDelegate.imageCache setObject:image forKey:imageArray[index][@"_id"]];
    }
    return image;
}

- (void)displayImage:(UIImage *)image {
    [viewLoadingLabel setHidden:YES];
    [imgView setImage:image];
    NSString *sourceImageName = imageArray[imageIndex][@"source"];
    NSString *attributionText = imageArray[imageIndex][@"attribution_name"];
    [imgSourceL setImage:[UIImage imageNamed:sourceImageName]];
    [imgSourceR setImage:[UIImage imageNamed:sourceImageName]];
    [labelAttributionL setText:attributionText];
    [labelAttributionR setText:attributionText];
    NSLog(@"ATTR: %@", attributionText);
    [self showViewerControls];
}


@end
