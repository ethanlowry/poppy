//
//  GalleryViewController.m
//  Poppy
//
//  Created by Ethan Lowry on 1/3/14.
//  Copyright (c) 2014 Hack Things LLC. All rights reserved.
//

#import "GalleryViewController.h"
#import "AppDelegate.h"

@interface GalleryViewController ()
@property (nonatomic, strong) UIView *separatorBar;
@property (nonatomic, strong) RBVolumeButtons *buttonStealer;
@end

@implementation GalleryViewController

@synthesize displayView;
@synthesize imgView;
@synthesize frameHeight;
@synthesize frameWidth;

@synthesize viewLoadingLabel;
@synthesize imageArray;
@synthesize viewViewerControls;

@synthesize imgSourceL;
@synthesize imgSourceR;
@synthesize labelAttributionL;
@synthesize labelAttributionR;
@synthesize labelLikeCountL;
@synthesize labelLikeCountR;
@synthesize likeImageL;
@synthesize likeImageR;
@synthesize viewAttribution;

@synthesize viewBlockAlert;

@synthesize buttonFavorite;

BOOL directionNext;
BOOL isLoading;
int imageIndex;
NSTimer *timerDimmer;
NSOperationQueue *queue;

NSMutableArray *recentRequests;

@synthesize showPopular;

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
    if (imageIndex >= 0) {
        [self performSelector:@selector(updatePortraitView) withObject:nil afterDelay:0];
    }
}
    
- (void)updatePortraitView
{
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    
    if(deviceOrientation == UIDeviceOrientationPortrait){
        AppDelegate *poppyAppDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        poppyAppDelegate.switchToGallery = YES;
        poppyAppDelegate.currentGalleryImageIndex = imageIndex;
        poppyAppDelegate.showBestGallery = showPopular;
        [self dismissViewControllerAnimated:NO completion:^{}];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor darkGrayColor]];
    imageIndex = -1;
    
    AppDelegate *poppyAppDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    //NSLog(@"top count: %d", poppyAppDelegate.topImageArray.count);
    //NSLog(@"recent count: %d", poppyAppDelegate.recentImageArray.count);
    imageArray = showPopular ? poppyAppDelegate.topImageArray : poppyAppDelegate.recentImageArray;
    queue = [NSOperationQueue new];
    recentRequests = [[NSMutableArray alloc] init];
    
    self.buttonStealer = [[RBVolumeButtons alloc] init];
    
    __weak __typeof__(self) weakSelf = self;
    self.buttonStealer.upBlock = ^{
        [weakSelf plusVolumeButtonPressedAction];
    };
    self.buttonStealer.downBlock = ^{
        [weakSelf minusVolumeButtonPressedAction];
    };
    
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
    [self goHome];
}

- (void)viewDidAppear:(BOOL)animated
{
    //NSLog(@"viewDidAppear");
    
    int64_t delayInSeconds = 0.01;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self.buttonStealer startStealingVolumeButtonEvents];
    });
    
    AppDelegate *poppyAppDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [poppyAppDelegate makeScreenBrightnessMax];
    
    if(!imgView){
        frameWidth = self.view.frame.size.height/2;
        frameHeight = self.view.frame.size.width;
        
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
        labelAttributionL = [[UILabel alloc] initWithFrame:CGRectMake(40, 5, frameWidth - 60, 20)];
        labelAttributionR = [[UILabel alloc] initWithFrame:CGRectMake(frameWidth + 40, 5, frameWidth - 60, 20)];
        [labelAttributionL setFont:[UIFont systemFontOfSize:12]];
        [labelAttributionL setTextColor:[UIColor whiteColor]];
        [labelAttributionR setFont:[UIFont systemFontOfSize:12]];
        [labelAttributionR setTextColor:[UIColor whiteColor]];
        labelLikeCountL = [[UILabel alloc] initWithFrame:CGRectMake(frameWidth - 43, 5, 20, 20)];
        labelLikeCountR = [[UILabel alloc] initWithFrame:CGRectMake(2*frameWidth - 43, 5, 20, 20)];
        [labelLikeCountL setFont:[UIFont systemFontOfSize:12]];
        [labelLikeCountL setTextColor:[UIColor whiteColor]];
        [labelLikeCountL setTextAlignment:NSTextAlignmentRight];
        [labelLikeCountR setFont:[UIFont systemFontOfSize:12]];
        [labelLikeCountR setTextColor:[UIColor whiteColor]];
        [labelLikeCountR setTextAlignment:NSTextAlignmentRight];
        likeImageL = [[UIImageView alloc] initWithFrame:CGRectMake(frameWidth - 22, 11, 12, 9)];
        likeImageR = [[UIImageView alloc] initWithFrame:CGRectMake(frameWidth*2 - 22, 11, 12, 9)];
        
        [viewAttribution addSubview:imgSourceL];
        [viewAttribution addSubview:imgSourceR];
        [viewAttribution addSubview:labelAttributionL];
        [viewAttribution addSubview:labelAttributionR];
        [viewAttribution addSubview:labelLikeCountL];
        [viewAttribution addSubview:labelLikeCountR];
        [viewAttribution addSubview:likeImageL];
        [viewAttribution addSubview:likeImageR];
        [displayView addSubview:viewAttribution];
        
        viewLoadingLabel = [[UIView alloc] initWithFrame:CGRectMake(0, (self.view.bounds.size.height - 130)/2, self.view.bounds.size.width, 75)];
        [viewLoadingLabel setAutoresizingMask: UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin];
        UIView *viewShadow = [[UIView alloc] initWithFrame:viewLoadingLabel.bounds];
        [viewShadow setBackgroundColor:[UIColor blackColor]];
        [viewShadow setAlpha:0.3];
        UILabel *loadingLabelL = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, viewLoadingLabel.frame.size.width/2, viewLoadingLabel.frame.size.height)];
        [loadingLabelL setText:@"Loading..."];
        [loadingLabelL setTextColor:[UIColor whiteColor]];
        [loadingLabelL setTextAlignment:NSTextAlignmentCenter];
        UILabel *loadingLabelR = [[UILabel alloc] initWithFrame:CGRectMake(viewLoadingLabel.frame.size.width/2, 0, viewLoadingLabel.frame.size.width/2, viewLoadingLabel.frame.size.height)];
        [loadingLabelR setText:@"Loading..."];
        [loadingLabelR setTextColor:[UIColor whiteColor]];
        [loadingLabelR setTextAlignment:NSTextAlignmentCenter];
        [viewLoadingLabel addSubview:viewShadow];
        [viewLoadingLabel addSubview:loadingLabelL];
        [viewLoadingLabel addSubview:loadingLabelR];
        [viewLoadingLabel setHidden:YES];
        [self.view addSubview:viewLoadingLabel];
        
        UIView *touchView = [[UIView alloc] initWithFrame:self.view.bounds];
        [self addGestures:touchView];
        [displayView addSubview:touchView];
        
        if (!self.separatorBar) {
            self.separatorBar = [[UIView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width/2 - 2,0,4,self.view.bounds.size.height)];
            [self.separatorBar setBackgroundColor:[UIColor blackColor]];
            [self.view addSubview:self.separatorBar];
            self.separatorBar.layer.zPosition = MAXFLOAT;
        }
    }
    [self showViewerControls];
    if(imageIndex == -1) {
        [self showMedia:YES];
    }
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
    
    buttonFavorite = [[UIButton alloc] initWithFrame: CGRectMake(viewViewerControls.frame.size.width - 150,0,70,75)];
    [buttonFavorite setImage:[UIImage imageNamed:@"favorite"] forState:UIControlStateNormal];
    [buttonFavorite addTarget:self action:@selector(markFavorite) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *buttonBlock = [[UIButton alloc] initWithFrame: CGRectMake(viewViewerControls.frame.size.width - 230,0,70,75)];
    [buttonBlock setImage:[UIImage imageNamed:@"flag"] forState:UIControlStateNormal];
    [buttonBlock addTarget:self action:@selector(showBlockAlert) forControlEvents:UIControlEventTouchUpInside];
    
    [viewViewerControls addSubview: viewShadow];
    [viewViewerControls addSubview: buttonHome];
    [viewViewerControls addSubview: buttonFavorite];
    [viewViewerControls addSubview: buttonBlock];
}

- (void)markFavorite
{
    if (imageArray[imageIndex]){
        //NSLog(@"There's a pic to Favorite");
        NSString *uuid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        NSString *item_id = imageArray[imageIndex][@"_id"];
        NSString *addText;
        NSString *favorited;
        int likeCount = [imageArray[imageIndex][@"display_points"] intValue];
        if ([imageArray[imageIndex][@"favorited"] isEqualToString:@"false"]) {
            addText = @"add";
            favorited = @"true";
            likeCount = likeCount + 1;
        } else {
            addText = @"remove";
            favorited = @"false";
            likeCount = likeCount - 1;
        }
        [self updateLikeLabels:likeCount];
        NSString *urlString = [NSString stringWithFormat:@"http://poppy3d.com/app/action/post.json?uuid=%@&media_item_id=%@&action=favorite&v=%@", uuid, item_id, addText];
        
        NSURL *url = [NSURL URLWithString:urlString];
        
        //NSLog(@"URL: %@", url);
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                               cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                           timeoutInterval:30.0];
        
        [request setHTTPMethod:@"POST"];
        
        [NSURLConnection sendAsynchronousRequest:request
                                           queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                   // TO DO: Look at the response. Currently this is fire and forget
                                   if(error){
                                       NSLog(@"ERROR: %@", error);
                                   }
                               }];
        
        //Now update the "favorited" value to reflect the change
        NSMutableDictionary *newItem = [[NSMutableDictionary alloc] init];
        NSDictionary *oldItem = (NSDictionary *)[imageArray objectAtIndex:imageIndex];
        [newItem addEntriesFromDictionary:oldItem];
        [newItem setObject:favorited forKey:@"favorited"];
        [newItem setObject:[NSNumber numberWithInt:likeCount] forKey:@"display_points"];
        [imageArray replaceObjectAtIndex:imageIndex withObject:newItem];
        
        [self showViewerControls];
    }
}

- (void)showBlockAlert
{
    if(imageArray[imageIndex]) {
        if (!viewBlockAlert) {
            viewBlockAlert = [[UIView alloc] initWithFrame:self.view.bounds];
            [viewBlockAlert setAutoresizingMask: UIViewAutoresizingFlexibleTopMargin];
            UIView *viewShadow = [[UIView alloc] initWithFrame:self.view.bounds];
            viewShadow.backgroundColor = [UIColor blackColor];
            viewShadow.alpha = 0.3;
            UITapGestureRecognizer *handleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissBlockAlert)];
            [viewShadow addGestureRecognizer:handleTap];
            [viewBlockAlert addSubview:viewShadow];
            [self addBlockAlertContent:0.0];
            [self addBlockAlertContent:viewBlockAlert.frame.size.width/2];
        }
        
        [self.view addSubview:viewBlockAlert];
        [self.view bringSubviewToFront:viewBlockAlert];
    }
}

- (void) addBlockAlertContent:(float)offset
{
    UILabel *blockLabel = [[UILabel alloc] initWithFrame:CGRectMake(offset,(viewBlockAlert.frame.size.height - 120)/2,viewBlockAlert.frame.size.width/2,60)];
    [blockLabel setTextAlignment:NSTextAlignmentCenter];
    [blockLabel setBackgroundColor:[UIColor blackColor]];
    [blockLabel setTextColor:[UIColor whiteColor]];
    [blockLabel setText: @"Inappropriate or not 3D?"];
    CALayer *bottomBorder = [CALayer layer];
    bottomBorder.frame = CGRectMake(40, 59, blockLabel.frame.size.width-80, 1.0);
    bottomBorder.backgroundColor = [UIColor whiteColor].CGColor;
    [blockLabel.layer addSublayer:bottomBorder];
    [viewBlockAlert addSubview:blockLabel];
    
    UIButton *buttonConfirmBlock = [[UIButton alloc] initWithFrame:CGRectMake(offset,viewBlockAlert.frame.size.height/2, viewBlockAlert.frame.size.width/4, 60)];
    [buttonConfirmBlock setTitle:@"Report" forState:UIControlStateNormal];
    [buttonConfirmBlock addTarget:self action:@selector(markBlocked) forControlEvents:UIControlEventTouchUpInside];
    //[buttonConfirmBlock.titleLabel setTextAlignment:NSTextAlignmentLeft];
    [buttonConfirmBlock setBackgroundColor:[UIColor blackColor]];
    [viewBlockAlert addSubview:buttonConfirmBlock];
    
    UIButton *buttonCancelBlock = [[UIButton alloc] initWithFrame:CGRectMake(offset + viewBlockAlert.frame.size.width/4, viewBlockAlert.frame.size.height/2, viewBlockAlert.frame.size.width/4, 60)];
    [buttonCancelBlock setTitle:@"Cancel" forState:UIControlStateNormal];
    [buttonCancelBlock addTarget:self action:@selector(dismissBlockAlert) forControlEvents:UIControlEventTouchUpInside];
    //[buttonCancelBlock.titleLabel setTextAlignment:NSTextAlignmentRight];
    [buttonCancelBlock setBackgroundColor:[UIColor blackColor]];
    [viewBlockAlert addSubview:buttonCancelBlock];
}

- (void)dismissBlockAlert
{
    [viewBlockAlert removeFromSuperview];
}

- (void)markBlocked
{
    //NSLog(@"BLOCK!!");
    [self dismissBlockAlert];
    
    // post a block message
    // remove from the imageArray
    // step to the next image
    
    //NSLog(@"There's a pic to Block");
    NSString *uuid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    NSString *item_id = imageArray[imageIndex][@"_id"];
    NSString *urlString = [NSString stringWithFormat:@"http://poppy3d.com/app/action/post.json?uuid=%@&media_item_id=%@&action=flag&v=add", uuid, item_id];
    NSURL *url = [NSURL URLWithString:urlString];
    
    //NSLog(@"URL: %@", url);
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                       timeoutInterval:30.0];
    
    
    
    [request setHTTPMethod:@"POST"];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               // TO DO: Look at the response. Currently this is fire and forget
                               if(error){
                                   NSLog(@"ERROR: %@", error);
                               }
                           }];
    
    //Now remove the blocked photo from the stream
    [imageArray removeObjectAtIndex:imageIndex];
    
    [self showMedia:NO];
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
    //NSLog(@"show next");
    [self showMedia:YES];
}

- (void)swipeScreenRight:(UISwipeGestureRecognizer *)sgr
{
    //NSLog(@"show previous");
    [self showMedia:NO];
}

- (void)handleDoubleTapAction:(UITapGestureRecognizer *)tgr
{
    if (tgr.state == UIGestureRecognizerStateRecognized) {
        CGPoint location = [tgr locationInView:self.view];
        if (location.x < self.view.frame.size.height/2) {
            [self showMedia:NO];
        } else {
            [self showMedia:YES];
        }
    }
}

- (void)handleTapAction:(UITapGestureRecognizer *)tgr
{
    if (tgr.state == UIGestureRecognizerStateRecognized) {
        [self showViewerControls];
    }
    
}

- (void) showMedia:(BOOL)showNext
{
    if (imageArray && imageArray.count > 0) {
        if(!isLoading || showNext != directionNext || imgView.image != nil){
            if (showNext) {
                directionNext = YES;
                imageIndex = imageIndex + 1;
                if (imageIndex > imageArray.count - 5 && !showPopular) {
                    [self loadInfinite];
                }
            } else {
                directionNext = NO;
                imageIndex = imageIndex - 1;
            }
            
            // if we got here through device rotation, overwrite the current index
            AppDelegate *poppyAppDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            if (poppyAppDelegate.currentGalleryImageIndex >= 0) {
                imageIndex = poppyAppDelegate.currentGalleryImageIndex;
                poppyAppDelegate.currentGalleryImageIndex = -1;
                poppyAppDelegate.switchToGallery = NO;
            }
            
            if(imageIndex >= 0 && imageIndex < imageArray.count) {
                // Animate the old image away
                float xPosition = directionNext ? -imgView.frame.size.width : imgView.frame.size.width;
                UIImageView *animatedImgView = [[UIImageView alloc] initWithFrame:imgView.frame];
                [animatedImgView setImage:imgView.image];
                [animatedImgView setContentMode:UIViewContentModeScaleAspectFill];
                [self.view addSubview:animatedImgView];
                [imgView setImage:nil];
                CGRect finalFrame = animatedImgView.frame;
                finalFrame.origin.x = xPosition;
                [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{ animatedImgView.frame = finalFrame; } completion:^(BOOL finished){
                    [animatedImgView removeFromSuperview];
                }];
                
                [buttonFavorite setImage:[UIImage imageNamed:@"favorite"] forState:UIControlStateNormal];
                NSInvocationOperation *operation = [[NSInvocationOperation alloc]
                                                    initWithTarget:self
                                                    selector:@selector(loadAndDisplayCurrentImage)
                                                    object:nil];
                [queue addOperation:operation];
                
                // Now preload some images out in front of us
                // Built-in cache should take care of going backwards.
                // But the cache can get filled, and then you need it when you go back
                int quantityToPreload = 5;
                if (showNext) {
                    int startIndex = imageIndex + 1;
                    for (int i = startIndex; i < startIndex + quantityToPreload; i++) {
                        if (i >= 0 && i < imageArray.count) {
                            [self preloadImage:i usingQueue:queue];
                        }
                    }
                } else {
                    int startIndex = imageIndex - 1;
                    for (int i = startIndex; i > startIndex - quantityToPreload; i--) {
                        if (i >= 0 && i < imageArray.count) {
                            [self preloadImage:i usingQueue:queue];
                        }
                    }
                }
            } else {
                if (imageIndex < 0) {
                    imageIndex = 0;
                } else {
                    imageIndex = imageArray.count - 1;
                }
            }
            
            [self showViewerControls];
        } else {
            NSLog(@"NO MEDIA");
        }
    }
}

- (void)goHome
{
    [self dismissViewControllerAnimated:YES completion:^{}];
}

- (void)dimView:(float)duration withAlpha:(float)alpha withView:(UIView *)view withTimer:(BOOL)showTimer
{
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadAndDisplayCurrentImage
{
    //[self loadImage:imageIndex andDisplay:YES];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self loadImage:imageIndex andDisplay:YES];
    }];
}

- (void)preloadImage:(int)index usingQueue:(NSOperationQueue*)queue
{
    //TEMPORARY: switch to main queue to see if this stops the crash
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self loadImage:(index) andDisplay:NO];
    }];
}

// Create a NSURLRequest manually and make it load only cached values
// See: http://www.raywenderlich.com/31166/25-ios-app-performance-tips-tricks#mainthread
- (NSMutableURLRequest *)imageRequestWithURL:(NSURL *)url {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    request.cachePolicy = NSURLRequestReturnCacheDataElseLoad; // this will make sure the request always returns the cached image
    request.HTTPShouldHandleCookies = NO;
    request.HTTPShouldUsePipelining = YES;
    [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];
    
    return request;
}

- (void)loadImage:(int)index andDisplay:(BOOL)willDisplayImage
{
    if (willDisplayImage){
        dispatch_async(dispatch_get_main_queue(), ^{
            // Set the attribution and score
            NSString *attributionText = [NSString stringWithFormat:@"%@ - %@", imageArray[imageIndex][@"attribution_name"], imageArray[imageIndex][@"time_ago"]];
            [labelAttributionL setText:attributionText];
            [labelAttributionR setText:attributionText];
            NSString *sourceImageName = imageArray[imageIndex][@"source"];
            [imgSourceL setImage:[UIImage imageNamed:sourceImageName]];
            [imgSourceR setImage:[UIImage imageNamed:sourceImageName]];
            int likeCount = [imageArray[imageIndex][@"display_points"] intValue];
            [self updateLikeLabels:likeCount];
            [self showViewerControls];
        });
    }
        
    // load from the web
    
    NSString *mediaURL = imageArray[index][@"media_url"];
    NSURL *url = [NSURL URLWithString:mediaURL];
    NSURLRequest *request = [self imageRequestWithURL:url];
    
    NSCachedURLResponse *cachedResponse = [[NSURLCache sharedURLCache] cachedResponseForRequest:request];
    
    if (cachedResponse) {
        if (willDisplayImage) {
            // if we're going to show it anyway and already have the image, skip the extra stuff
            NSData *data = cachedResponse.data;
            UIImage *image = [[UIImage alloc] initWithData:data];
            [self performSelectorOnMainThread:@selector(displayImage:) withObject:image waitUntilDone:NO];
            NSInvocationOperation *operation = [[NSInvocationOperation alloc]
                                                initWithTarget:self
                                                selector:@selector(removeRecentRequest:)
                                                object:mediaURL];
            [queue addOperation:operation];
        }
    } else {
        if (willDisplayImage) {
            //NSLog(@"NOT IN CACHE: %d", index);
            dispatch_async(dispatch_get_main_queue(), ^{
                [viewLoadingLabel setHidden:NO];
                isLoading = YES;
            });
        }
        //NSLog(@"recent requests count: %d", recentRequests.count);
        
        if(![recentRequests containsObject:mediaURL] || willDisplayImage) {
            if (![recentRequests containsObject:mediaURL]) {
                [recentRequests addObject:mediaURL];
            }

            // Get the data
            [NSURLConnection sendAsynchronousRequest:request
                                               queue:[NSOperationQueue mainQueue]
                                   completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                       if (error) {
                                           NSLog(@"ERROR: %@", error);
                                       } else {
                                           //NSLog(@"LOADED: %d", index);
                                           UIImage *image = [[UIImage alloc] initWithData:data];
                                           //if for display
                                           if (willDisplayImage) {
                                               [self performSelectorOnMainThread:@selector(displayImage:) withObject:image waitUntilDone:NO];
                                           }
                                           
                                            NSInvocationOperation *operation = [[NSInvocationOperation alloc]
                                                                               initWithTarget:self
                                                                               selector:@selector(removeRecentRequest:)
                                                                               object:mediaURL];
                                           [queue addOperation:operation];
                                       }
                                   }];
        }
    }
}

-(void)removeRecentRequest:(NSString *)requestURL
{
    if([recentRequests containsObject:requestURL]) {
        [recentRequests removeObject:requestURL];
    }
}

- (void)displayImage:(UIImage *)image {
    //NSLog(@"SHOWING: %d", imageIndex);
    isLoading = NO;
    [viewLoadingLabel setHidden:YES];
    [imgView setImage:image];
    [self showViewerControls];
}

- (void)loadInfinite
{
    //NSLog(@"LOAD INFINITE: %d", imageArray.count);
    AppDelegate *poppyAppDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if((poppyAppDelegate.recentPage + 1) * poppyAppDelegate.recentLimit <= imageArray.count) {
        //NSLog(@"LOAD MORE DATA!");
        poppyAppDelegate.recentPage = poppyAppDelegate.recentPage + 1;
        [poppyAppDelegate loadJSON:@"recent"];
    }
}

- (void)updateLikeLabels:(int)count
{
    if(count > 0) {
        [likeImageL setImage:[UIImage imageNamed:@"favorite"]];
        [likeImageR setImage:[UIImage imageNamed:@"favorite"]];
        [labelLikeCountL setText:[NSString stringWithFormat:@"%d", count]];
        [labelLikeCountR setText:[NSString stringWithFormat:@"%d", count]];
    } else {
        [likeImageL setImage:nil];
        [likeImageR setImage:nil];
        [labelLikeCountL setText:@""];
        [labelLikeCountR setText:@""];
    }
}


@end
