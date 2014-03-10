//
//  PortraitGalleryViewController.m
//  Poppy
//
//  Created by Ethan Lowry on 3/7/14.
//  Copyright (c) 2014 Ethan Lowry. All rights reserved.
//

#import "PortraitGalleryViewController.h"
#import "AppDelegate.h"

@interface PortraitGalleryViewController ()
    @property (nonatomic, strong) UIView *wiggleView;
    @property (nonatomic, strong) UIView *wiggleButtonView;
@end

@implementation PortraitGalleryViewController

    @synthesize displayView;
    @synthesize imgView;
    @synthesize frameHeight;
    @synthesize frameWidth;
    
    @synthesize viewLoadingLabel;
    @synthesize imageArray;
    @synthesize viewViewerControls;
    
    @synthesize imgSource;
    @synthesize labelAttribution;
    @synthesize labelLikeCount;
    @synthesize likeImage;
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
            [self performSelector:@selector(updateLandscapeView) withObject:nil afterDelay:0];
        }
    }
    
- (void)updateLandscapeView
    {
        UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
        
        if(deviceOrientation == UIDeviceOrientationLandscapeRight){
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
        imageIndex = -1;
        AppDelegate *poppyAppDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        imageArray = showPopular ? poppyAppDelegate.topImageArray : poppyAppDelegate.recentImageArray;
        queue = [NSOperationQueue new];
        recentRequests = [[NSMutableArray alloc] init];
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
        if (!imgView) {
            frameWidth = self.view.bounds.size.width;
            frameHeight = self.view.bounds.size.height;
            
            [self showViewerControls];
            
            [self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"background"]]];
            UIImageView *imgLogo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo_white"]];
            [imgLogo setFrame:CGRectMake((frameWidth -200)/2,20,200,40)];
            [self.view addSubview:imgLogo];
            
            displayView = [[UIView alloc] initWithFrame:CGRectMake(0,80,frameWidth,280)];
            [displayView setBackgroundColor:[UIColor darkGrayColor]];
            [self.view addSubview:displayView];
            
            imgView = [[UIImageView alloc] initWithFrame:displayView.bounds];
            [imgView setContentMode:UIViewContentModeScaleAspectFill];
            [displayView setClipsToBounds:YES];
            [displayView addSubview:imgView];
            
            float topOfButton = self.imgView.bounds.origin.y + self.imgView.bounds.size.height + (self.view.bounds.size.height - self.imgView.bounds.size.height - 60 + 20)/2;
            CGRect wiggleFrame = CGRectMake((self.view.bounds.size.width - 240)/2,topOfButton, 240, 60);
            self.wiggleButtonView = [[UIView alloc] initWithFrame:wiggleFrame];
            UIView *wiggleShadowView = [[UIView alloc] initWithFrame:self.wiggleButtonView.bounds];
            [wiggleShadowView setBackgroundColor:[UIColor grayColor]];
            [wiggleShadowView setAlpha:0.3];
            [self.wiggleButtonView addSubview:wiggleShadowView];
            UIButton *btnWiggle = [[UIButton alloc] initWithFrame:self.wiggleButtonView.bounds];
            [btnWiggle addTarget:self action:@selector(showWiggle) forControlEvents:UIControlEventTouchUpInside];
            [btnWiggle setTitle:@"View Poppy GIF" forState:UIControlStateNormal];
            [self.wiggleButtonView addSubview:btnWiggle];
            [self.view addSubview:self.wiggleButtonView];
            [self.wiggleButtonView setHidden:YES];

            viewAttribution = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frameWidth, 30)];
            UIView *viewAttrShadow = [[UIView alloc] initWithFrame:viewAttribution.frame];
            [viewAttrShadow setAlpha:0.3];
            [viewAttrShadow setBackgroundColor:[UIColor blackColor]];
            [viewAttribution addSubview:viewAttrShadow];
            
            imgSource = [[UIImageView alloc] initWithFrame:CGRectMake(10, 5, 20, 20)];
            labelAttribution = [[UILabel alloc] initWithFrame:CGRectMake(40, 5, frameWidth - 60, 20)];
            [labelAttribution setFont:[UIFont systemFontOfSize:12]];
            [labelAttribution setTextColor:[UIColor whiteColor]];
            labelLikeCount = [[UILabel alloc] initWithFrame:CGRectMake(frameWidth - 43, 5, 20, 20)];
            [labelLikeCount setFont:[UIFont systemFontOfSize:12]];
            [labelLikeCount setTextColor:[UIColor whiteColor]];
            [labelLikeCount setTextAlignment:NSTextAlignmentRight];
            likeImage = [[UIImageView alloc] initWithFrame:CGRectMake(frameWidth - 22, 11, 12, 9)];
            
            [viewAttribution addSubview:imgSource];
            [viewAttribution addSubview:labelAttribution];
            [viewAttribution addSubview:labelLikeCount];
            [viewAttribution addSubview:likeImage];
            [displayView addSubview:viewAttribution];
            
            viewLoadingLabel = [[UIView alloc] initWithFrame:CGRectMake(0, (displayView.bounds.size.height - 75)/2, frameWidth, 75)];
            [viewLoadingLabel setAutoresizingMask: UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin];
            UIView *viewShadow = [[UIView alloc] initWithFrame:viewLoadingLabel.bounds];
            [viewShadow setBackgroundColor:[UIColor blackColor]];
            [viewShadow setAlpha:0.3];
            UILabel *loadingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, viewLoadingLabel.frame.size.width, viewLoadingLabel.frame.size.height)];
            [loadingLabel setText:@"Loading..."];
            [loadingLabel setTextColor:[UIColor whiteColor]];
            [loadingLabel setTextAlignment:NSTextAlignmentCenter];

            [viewLoadingLabel addSubview:viewShadow];
            [viewLoadingLabel addSubview:loadingLabel];
            [viewLoadingLabel setHidden:YES];
            [displayView addSubview:viewLoadingLabel];
            
            UIView *touchView = [[UIView alloc] initWithFrame:self.view.bounds];
            [self addGestures:touchView];
            [displayView addSubview:touchView];
        }
        if(imageIndex == -1) {
            [self showMedia:YES];
        }
    }
    
- (void)showViewerControls
    {
        if (!viewViewerControls)
        {
            viewViewerControls = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 60, frameWidth, 60)];
            [viewViewerControls setAutoresizingMask: UIViewAutoresizingFlexibleTopMargin];
            [self addViewerControlsContent];
            [self.view addSubview:viewViewerControls];
        }
        
        if (imageArray && imageIndex >= 0 && [imageArray[imageIndex][@"favorited"] isEqualToString:@"true"]) {
            [buttonFavorite setImage:[UIImage imageNamed:@"is_favorite"] forState:UIControlStateNormal];
        } else {
            [buttonFavorite setImage:[UIImage imageNamed:@"favorite"] forState:UIControlStateNormal];
        }
    }

-(void)showWiggle
    {
        self.wiggleView = [[UIView alloc] initWithFrame:self.view.bounds];
        [self.wiggleView setBackgroundColor:[UIColor blackColor]];
        UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, self.wiggleView.frame.size.width, 480)];
        [webView setOpaque:NO];
        [webView setBackgroundColor: [UIColor clearColor]];
        CGRect dismissWiggleFrame = CGRectMake((self.wiggleView.frame.size.width - 100)/2, self.wiggleView.frame.size.height - 70, 100, 50);
        UIView *wiggleShadowView = [[UIView alloc] initWithFrame:dismissWiggleFrame];
        [wiggleShadowView setBackgroundColor:[UIColor grayColor]];
        [wiggleShadowView setAlpha:0.3];
        UIButton *wiggleButton = [[UIButton alloc] initWithFrame:dismissWiggleFrame];
        [wiggleButton addTarget:self action:@selector(dismissWiggle) forControlEvents:UIControlEventTouchUpInside];
        [wiggleButton setTitle:@"Done" forState:UIControlStateNormal];
        [self.wiggleView addSubview:webView];
        [self.wiggleView addSubview:wiggleShadowView];
        [self.wiggleView addSubview:wiggleButton];
        [self.view addSubview:self.wiggleView];
        
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://poppy3d.com/playercard/%@",imageArray[imageIndex][@"token"]]];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        [webView loadRequest:request];
    }


- (void)dismissWiggle
    {
        [self.wiggleView removeFromSuperview];
    }
    
- (void)addViewerControlsContent
    {
        UIView *viewShadow = [[UIView alloc] initWithFrame:viewViewerControls.bounds];
        [viewShadow setBackgroundColor:[UIColor blackColor]];
        [viewShadow setAlpha:0.3];
        [self addGestures:viewShadow];
        
        float spacing = (frameWidth - (4 * 70))/3;
        
        UIButton *buttonShare = [[UIButton alloc] initWithFrame: CGRectMake(0,0,70,60)];
        [buttonShare setImage:[UIImage imageNamed:@"sharing"] forState:UIControlStateNormal];
        [buttonShare addTarget:self action:@selector(showSharing) forControlEvents:UIControlEventTouchUpInside];
        
        UIButton *buttonBlock = [[UIButton alloc] initWithFrame: CGRectMake(70 + spacing,0,70,60)];
        [buttonBlock setImage:[UIImage imageNamed:@"flag"] forState:UIControlStateNormal];
        [buttonBlock addTarget:self action:@selector(showBlockAlert) forControlEvents:UIControlEventTouchUpInside];
        
        buttonFavorite = [[UIButton alloc] initWithFrame: CGRectMake(140+2 * spacing,0,70,60)];
        [buttonFavorite setImage:[UIImage imageNamed:@"favorite"] forState:UIControlStateNormal];
        [buttonFavorite addTarget:self action:@selector(markFavorite) forControlEvents:UIControlEventTouchUpInside];
        
        UIButton *buttonHome = [[UIButton alloc] initWithFrame: CGRectMake(viewViewerControls.frame.size.width - 70,0,70,60)];
        [buttonHome setImage:[UIImage imageNamed:@"home"] forState:UIControlStateNormal];
        [buttonHome addTarget:self action:@selector(goHome) forControlEvents:UIControlEventTouchUpInside];
        
        [viewViewerControls addSubview: viewShadow];
        [viewViewerControls addSubview: buttonHome];
        [viewViewerControls addSubview: buttonFavorite];
        [viewViewerControls addSubview: buttonBlock];
        [viewViewerControls addSubview: buttonShare];
    }

- (void)showSharing
    {
        if (imageArray[imageIndex] && imageArray[imageIndex][@"web_url"]) {
            NSMutableArray *sharingItems = [NSMutableArray new];
            
            [sharingItems addObject:[NSString stringWithFormat:@"Check out this Poppy GIF - %@ #poppy3d", imageArray[imageIndex][@"web_url"]]];
            
            UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:sharingItems applicationActivities:nil];
            [self presentViewController:activityController animated:YES completion:nil];
        }
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
                viewShadow.alpha = 0.6;
                UITapGestureRecognizer *handleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissBlockAlert)];
                [viewShadow addGestureRecognizer:handleTap];
                [viewBlockAlert addSubview:viewShadow];
                [self addBlockAlertContent];
            }
            
            [self.view addSubview:viewBlockAlert];
            [self.view bringSubviewToFront:viewBlockAlert];
        }
    }
    
- (void) addBlockAlertContent
    {
        UILabel *blockLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,(viewBlockAlert.frame.size.height - 120)/2,frameWidth,60)];
        [blockLabel setTextAlignment:NSTextAlignmentCenter];
        [blockLabel setBackgroundColor:[UIColor blackColor]];
        [blockLabel setTextColor:[UIColor whiteColor]];
        [blockLabel setText: @"Inappropriate or not 3D?"];
        [viewBlockAlert addSubview:blockLabel];
        
        UIButton *buttonConfirmBlock = [[UIButton alloc] initWithFrame:CGRectMake(0,viewBlockAlert.frame.size.height/2, viewBlockAlert.frame.size.width/2, 60)];
        [buttonConfirmBlock setTitle:@"Report" forState:UIControlStateNormal];
        [buttonConfirmBlock addTarget:self action:@selector(markBlocked) forControlEvents:UIControlEventTouchUpInside];
        //[buttonConfirmBlock.titleLabel setTextAlignment:NSTextAlignmentLeft];
        [buttonConfirmBlock setBackgroundColor:[UIColor blackColor]];
        [viewBlockAlert addSubview:buttonConfirmBlock];
        
        UIButton *buttonCancelBlock = [[UIButton alloc] initWithFrame:CGRectMake(viewBlockAlert.frame.size.width/2, viewBlockAlert.frame.size.height/2, viewBlockAlert.frame.size.width/2, 60)];
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
        [self showMedia:YES];
    }
    
- (void)swipeScreenRight:(UISwipeGestureRecognizer *)sgr
    {
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
        [self.wiggleButtonView setHidden:YES];
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
                    //[animatedImgView setClipsToBounds:YES];
                    [displayView addSubview:animatedImgView];
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
                //NSLog(@"NO MEDIA");
            }
        }
    }
    
- (void)goHome
    {
        [self dismissViewControllerAnimated:YES completion:^{}];
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
                [labelAttribution setText:attributionText];
                NSString *sourceImageName = imageArray[imageIndex][@"source"];
                [imgSource setImage:[UIImage imageNamed:sourceImageName]];
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
    NSString *morphURL = imageArray[imageIndex][@"morph_gif_url"];
    if (morphURL != (id)[NSNull null]) {
        //NSLog(@"%@", morphURL);
        [self.wiggleButtonView setHidden:NO];
    }
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
            [likeImage setImage:[UIImage imageNamed:@"favorite"]];
            [labelLikeCount setText:[NSString stringWithFormat:@"%d", count]];
        } else {
            [likeImage setImage:nil];
            [labelLikeCount setText:@""];
        }
    }
    
    
    @end
