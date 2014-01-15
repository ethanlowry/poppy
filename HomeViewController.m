//
//  HomeViewController.m
//  Poppy
//
//  Created by Ethan Lowry on 1/13/14.
//  Copyright (c) 2014 Ethan Lowry. All rights reserved.
//

#import "HomeViewController.h"

@interface HomeViewController ()

{
    RBVolumeButtons *buttonStealer;
}

@property (strong, nonatomic) UIView *portraitView;
@property (strong, nonatomic) UIView *landscapeLView;
@property (strong, nonatomic) UIView *landscapeRView;

@end

@implementation HomeViewController

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
	// Do any additional setup after loading the view.
    ALAssetsLibrary *lib = [[ALAssetsLibrary alloc] init];
    
    // this is just a test to trigger asking for user permission to access photos
    ALAuthorizationStatus status = [ALAssetsLibrary authorizationStatus];
    if (status == ALAuthorizationStatusNotDetermined) {
        [lib enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            NSLog(@"%i",[group numberOfAssets]);
        } failureBlock:^(NSError *error) {
            if (error.code == ALAssetsLibraryAccessUserDeniedError) {
                NSLog(@"user denied access, code: %i",error.code);
            }else{
                NSLog(@"Other error code: %i",error.code);
            }
        }];
    } else if (status != ALAuthorizationStatusAuthorized) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Attention" message:@"Please give Poppy permission to access your photos in the iPhone settings app!" delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil, nil];
        [alert show];
    }
    
    lib = nil;
    
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        if (!granted) {
            BOOL secondRun = [[NSUserDefaults standardUserDefaults] boolForKey:@"isCalibrated"];
            if (secondRun) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Attention" message:@"Please give Poppy permission to access your microphone in the iPhone settings app!" delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil, nil];
                [alert show];
            } else {
                [self authorizeAccess:AVMediaTypeAudio]; // asks the user for permission to use the microphone
            }
        }
    }];
    
    [self authorizeAccess:AVMediaTypeVideo]; // apparently permission is needed in some regions for video
    [self authorizeAccess:AVMediaTypeAudio]; // asks the user for permission to use the microphone
}


- (void) authorizeAccess:(NSString *)mediaType
{
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    
    // This status is normally not visible—the AVCaptureDevice class methods for discovering devices do not return devices the user is restricted from accessing.
    if(authStatus == AVAuthorizationStatusRestricted){
        NSLog(@"Restricted");
    }
    
    // The user has explicitly denied permission for media capture.
    else if(authStatus == AVAuthorizationStatusDenied){
        NSLog(@"Denied");
    }
    
    // The user has explicitly granted permission for media capture, or explicit user permission is not necessary for the media type in question.
    else if(authStatus == AVAuthorizationStatusAuthorized){
        NSLog(@"Authorized");
    }
    
    // Explicit user permission is required for media capture, but the user has not yet granted or denied such permission.
    else if(authStatus == AVAuthorizationStatusNotDetermined){
        
        [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
            if(granted){
                NSLog(@"Granted access to %@", mediaType);
            }
            else {
                NSLog(@"Not granted access to %@", mediaType);
            }
        }];
    }
    
    else {
        NSLog(@"Unknown authorization status");
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults boolForKey:@"isCalibrated"]) {
        [defaults setFloat:0.0 forKey:@"xOffset"];
        [defaults synchronize];
        CalibrationViewController *cvc = [[CalibrationViewController alloc] initWithNibName:@"LiveView" bundle:nil];
        [self presentViewController:cvc animated:NO completion:nil];
    } else {
        if (!buttonStealer) {
            __weak typeof(self) weakSelf = self;
            buttonStealer = [[RBVolumeButtons alloc] init];
            buttonStealer.upBlock = ^{
                // + volume button pressed
                NSLog(@"VOLUME UP!");
                [weakSelf launchCamera];
            };
        }
        [buttonStealer startStealingVolumeButtonEvents];
        
        if(!self.portraitView) {
            self.portraitView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
            [self addControlsToContainer:self.portraitView];
        }
        if(!self.landscapeLView) {
            self.landscapeLView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width/2, self.view.frame.size.height)];
            [self addControlsToContainer:self.landscapeLView];
        }
        if(!self.landscapeRView) {
            self.landscapeRView = [[UIView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width/2, 0, self.view.bounds.size.width/2, self.view.frame.size.height)];
            [self addControlsToContainer:self.landscapeRView];
        }
        [self.view setBackgroundColor:[UIColor blackColor]];
        
        if(UIDeviceOrientationIsLandscape(self.interfaceOrientation)) {
            [self.view addSubview:self.landscapeLView];
            [self.view addSubview:self.landscapeRView];
        } else {
            [self.view addSubview:self.portraitView];
        }
    }
}

- (void)addControlsToContainer:(UIView *)viewContainer
{
    UIImageView *imgLogo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo_white"]];
    [imgLogo setFrame:CGRectMake((viewContainer.bounds.size.width -200)/2,50,200,40)];
    [viewContainer addSubview:imgLogo];
    
    UIButton *buttonCamera = [self makeButton:@"Take Pictures" withPosition:1 withView:viewContainer withImageName:@"camera"];
    [buttonCamera addTarget:self action:@selector(launchCamera) forControlEvents:UIControlEventTouchUpInside];
    [viewContainer addSubview:buttonCamera];
    
    UIButton *buttonPhotos = [self makeButton:@"Your Photos" withPosition:2 withView:viewContainer withImageName:@"gallery"];
    [buttonPhotos addTarget:self action:@selector(launchViewer) forControlEvents:UIControlEventTouchUpInside];
    [viewContainer addSubview:buttonPhotos];
    
    UIButton *buttonRecent = [self makeButton:@"Twitter & Flickr" withPosition:3 withView:viewContainer withImageName:@"flicktweet"];
    [buttonRecent addTarget:self action:@selector(launchStream) forControlEvents:UIControlEventTouchUpInside];
    [viewContainer addSubview:buttonRecent];
    
    UIButton *buttonBest = [self makeButton:@"Most Liked" withPosition:4 withView:viewContainer withImageName:@"favorite"];
    [buttonBest addTarget:self action:@selector(launchBest) forControlEvents:UIControlEventTouchUpInside];
    [viewContainer addSubview:buttonBest];
}

- (UIButton *)makeButton:(NSString *)title withPosition:(int)position withView:(UIView *)containerView withImageName:(NSString *)imageName
{
    UIButton *button = [[UIButton alloc] init];
    [button setTitle:title forState:UIControlStateNormal];
    [button setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    [button setBackgroundImage:[self imageWithColor:[UIColor grayColor]] forState:UIControlStateHighlighted];
    
    if ([containerView isEqual:self.portraitView]) {
        [button setFrame:CGRectMake(0.0,position*60 + 50,containerView.bounds.size.width,60)];
        [button setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
        button.titleEdgeInsets = UIEdgeInsetsMake(0.0, 50.0, 0.0, 0.0);
        button.imageEdgeInsets = UIEdgeInsetsMake(0.0, 40.0, 0.0, 0.0);
    } else {
        float xOffset = 0;
        float yOffset = 0;
        
        switch (position) {
            case 1:
                xOffset = 0.0;
                yOffset = 220.0;
                break;
            case 2:
                xOffset = containerView.bounds.size.width/2;
                yOffset = 220.0;
                break;
            case 3:
                xOffset = 0.0;
                yOffset = 120.0;
                break;
            case 4:
                xOffset = containerView.bounds.size.width/2;
                yOffset = 120.0;
                break;
            default:
                break;
        }
    
        [button setFrame:CGRectMake(xOffset,yOffset,containerView.bounds.size.width/2,100)];
        [button setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
        CGSize imageSize = button.imageView.frame.size;
        button.titleEdgeInsets = UIEdgeInsetsMake(60.0, - imageSize.width, 0.0, 0.0);
        button.titleLabel.font = [UIFont systemFontOfSize:12];
        //CGSize titleSize = button.titleLabel.frame.size;
        button.imageEdgeInsets = UIEdgeInsetsMake(0.0, (containerView.bounds.size.width/2 - imageSize.width)/2, 0.0, 0.0);
        button.layer.borderWidth = 1.0;
    }
    
    
    [containerView addSubview:button];
    return button;
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

- (void)launchCamera
{
    LiveViewController *lvc = [[LiveViewController alloc] initWithNibName:@"LiveView" bundle:nil];
    lvc.modalTransitionStyle=UIModalTransitionStyleFlipHorizontal;
    lvc.isWatching = NO;
    [buttonStealer stopStealingVolumeButtonEvents];
    [self presentViewController:lvc animated:YES completion:nil];
}

- (void)launchViewer
{
    LiveViewController *lvc = [[LiveViewController alloc] initWithNibName:@"LiveView" bundle:nil];
    lvc.modalTransitionStyle=UIModalTransitionStyleFlipHorizontal;
    lvc.isWatching = YES;
    [buttonStealer stopStealingVolumeButtonEvents];
    [self presentViewController:lvc animated:YES completion:nil];
}

- (void)launchStream
{
    [buttonStealer stopStealingVolumeButtonEvents];
    GalleryViewController *gvc = [[GalleryViewController alloc] initWithNibName:@"LiveView" bundle:nil];
    gvc.modalTransitionStyle=UIModalTransitionStyleFlipHorizontal;
    gvc.showPopular = NO;
    [self presentViewController:gvc animated:YES completion:nil];
}

- (void)launchBest
{
    [buttonStealer stopStealingVolumeButtonEvents];
    GalleryViewController *gvc = [[GalleryViewController alloc] initWithNibName:@"LiveView" bundle:nil];
    gvc.modalTransitionStyle=UIModalTransitionStyleFlipHorizontal;
    gvc.showPopular = YES;
    [self presentViewController:gvc animated:YES completion:nil];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscapeLeft;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if(UIDeviceOrientationIsLandscape(self.interfaceOrientation)) {
        [self.view addSubview:self.landscapeLView];
        [self.view addSubview:self.landscapeRView];
        [self.portraitView removeFromSuperview];
    } else {
        [self.view addSubview:self.portraitView];
        [self.landscapeLView removeFromSuperview];
        [self.landscapeRView removeFromSuperview];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
