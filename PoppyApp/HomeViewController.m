//
//  HomeViewController.m
//  Poppy
//
//  Created by Ethan Lowry on 1/13/14.
//  Copyright (c) 2014 Hack Things LLC. All rights reserved.
//

#import "HomeViewController.h"
#import "AppDelegate.h"
#import "UpgradeViewController.h"
#import "PODRecordViewController.h"
#import "PODCalibrateViewController.h"
#import "ViewerViewController.h"
#import "PortraitViewerViewController.h"
#import "GalleryViewController.h"
#import "PortraitGalleryViewController.h"

@interface HomeViewController ()
@property (nonatomic, strong) RBVolumeButtons *buttonStealer;
@property (strong, nonatomic) UIView *portraitView;
@property (strong, nonatomic) UIView *landscapeLView;
@property (strong, nonatomic) UIView *landscapeRView;


@end

@implementation HomeViewController

@synthesize viewConnectionAlert;
@synthesize viewCalibrationAlert;

BOOL showPopular;

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
            //NSLog(@"%i",[group numberOfAssets]);
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
    
    self.buttonStealer = [[RBVolumeButtons alloc] init];
    
    __weak __typeof__(self) weakSelf = self;
    self.buttonStealer.upBlock = ^{
        [weakSelf plusVolumeButtonPressedAction];
    };
    self.buttonStealer.downBlock = ^{
        [weakSelf minusVolumeButtonPressedAction];
    };
}

- (void)minusVolumeButtonPressedAction {
    [self launchViewer];
}

- (void)plusVolumeButtonPressedAction {
    [self launchCamera];
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
        //NSLog(@"Authorized");
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
    AppDelegate *poppyAppDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [poppyAppDelegate makeScreenBrightnessNormal];
    if (!poppyAppDelegate.versionCheck || [poppyAppDelegate.versionCheck isEqualToString:@"ok"]) {
        if (![defaults objectForKey:@"calibrationImagePath"]) {
            [self runCalibration];
        } else if (poppyAppDelegate.switchToCamera) {
            [self launchCamera];
        } else if (poppyAppDelegate.switchToViewer) {
            [self launchViewer];
        } else if (poppyAppDelegate.switchToGallery) {
            poppyAppDelegate.showBestGallery ? [self launchBest] : [self launchStream];
        } else {
            int64_t delayInSeconds = 0.01;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [self.buttonStealer startStealingVolumeButtonEvents];
            });
            [self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"background"]]];
            //NSLog(@"ORIENTATION: %@", (UIDeviceOrientationIsLandscape(self.interfaceOrientation)) ? @"Landscape": @"Portrait" );
            if(UIDeviceOrientationIsLandscape(self.interfaceOrientation)) {
                [self showLandscape];
            } else {
                [self showPortrait];
            }
        }
    } else {
        [self showUpgradeMessage];
    }
}

-(void) showUpgradeMessage
{
    UpgradeViewController *uvc = [[UpgradeViewController alloc] initWithNibName:nil bundle:nil];
    [self presentViewController:uvc animated:NO completion:nil];
}

-(void) showLandscape
{
    if(self.portraitView) {
        [self.portraitView removeFromSuperview];
        self.portraitView = nil;
    }
    if(!self.landscapeLView) {
        self.landscapeLView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width/2, self.view.bounds.size.height)];
        [self addControlsToContainer:self.landscapeLView];
    }
    if(!self.landscapeRView) {
        self.landscapeRView = [[UIView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width/2, 0, self.view.bounds.size.width/2, self.view.bounds.size.height)];
        [self addControlsToContainer:self.landscapeRView];
    }
    if (![self.landscapeLView isDescendantOfView:self.view]) {
        [self.view addSubview:self.landscapeLView];
    }
    if (![self.landscapeRView isDescendantOfView:self.view]) {
        [self.view addSubview:self.landscapeRView];
    }
}

-(void) showPortrait
{
    [self.portraitView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"backgroundP"]]];
    if(self.landscapeRView) {
        [self.landscapeRView removeFromSuperview];
        self.landscapeRView = nil;
    }
    if (self.landscapeLView) {
        [self.landscapeLView removeFromSuperview];
        self.landscapeLView = nil;
    }
    if(!self.portraitView) {
        self.portraitView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
        [self addControlsToContainer:self.portraitView];
        
        UIButton *buttonRecalibrate = [self makeButton:@"Recalibrate" withPosition:5 withView:self.portraitView withImageName:@"cog"];
        [buttonRecalibrate addTarget:self action:@selector(showCalibrationAlert) forControlEvents:UIControlEventTouchUpInside];
        [self.portraitView addSubview:buttonRecalibrate];
        
        UIButton *buttonHelp = [self makeButton:@"How to Share Photos" withPosition:6 withView:self.portraitView withImageName:@"question"];
        [buttonHelp addTarget:self action:@selector(launchHelp) forControlEvents:UIControlEventTouchUpInside];
        [self.portraitView addSubview:buttonHelp];
    }
    if (![self.portraitView isDescendantOfView:self.view]) {
        [self.view addSubview:self.portraitView];
    }
}


- (void)addControlsToContainer:(UIView *)viewContainer
{
    float yOffset = 0.0;
    if ([viewContainer isEqual:self.portraitView]) {
        yOffset = 20.0;
    } else {
        yOffset = 50.0;
    }
    
    UIImageView *imgLogo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo_white"]];
    [imgLogo setFrame:CGRectMake((viewContainer.bounds.size.width -200)/2,yOffset,200,40)];
    [viewContainer addSubview:imgLogo];
    
    UIButton *buttonCamera = [self makeButton:@"Take Pictures" withPosition:1 withView:viewContainer withImageName:@"camera"];
    [buttonCamera addTarget:self action:@selector(launchCamera) forControlEvents:UIControlEventTouchUpInside];
    [viewContainer addSubview:buttonCamera];
    
    UIButton *buttonPhotos = [self makeButton:@"Your Photos" withPosition:2 withView:viewContainer withImageName:@"gallery"];
    [buttonPhotos addTarget:self action:@selector(launchViewer) forControlEvents:UIControlEventTouchUpInside];
    [viewContainer addSubview:buttonPhotos];
    
    UIButton *buttonRecent = [self makeButton:@"#poppy3d" withPosition:4 withView:viewContainer withImageName:@"flicktweet"];
    [buttonRecent addTarget:self action:@selector(launchStream) forControlEvents:UIControlEventTouchUpInside];
    [viewContainer addSubview:buttonRecent];
    
    UIButton *buttonBest = [self makeButton:@"Most Popular" withPosition:3 withView:viewContainer withImageName:@"favorite"];
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
        [button setFrame:CGRectMake(0.0,position*60 + 10,containerView.bounds.size.width,60)];
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

- (void)showCalibrationAlert
{
    viewCalibrationAlert = [[UIView alloc] initWithFrame:self.view.bounds];
    [viewCalibrationAlert setAutoresizingMask: UIViewAutoresizingFlexibleTopMargin];
    
    UIView *viewShadow = [[UIView alloc] initWithFrame:self.view.bounds];
    viewShadow.backgroundColor = [UIColor blackColor];
    viewShadow.alpha = 0.8;
    UITapGestureRecognizer *handleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissCalibrationAlert)];
    [viewShadow addGestureRecognizer:handleTap];
    [viewCalibrationAlert addSubview:viewShadow];
    
    UILabel *calibrationLabel = [[UILabel alloc] init];
    
    [calibrationLabel setFrame:CGRectMake(0, 120, viewCalibrationAlert.frame.size.width, 60)];
    [calibrationLabel setTextAlignment:NSTextAlignmentCenter];
    [calibrationLabel setBackgroundColor:[UIColor blackColor]];
    [calibrationLabel setTextColor:[UIColor whiteColor]];
    [calibrationLabel setText: @"Would you like to recalibrate?"];
    CALayer *bottomBorder = [CALayer layer];
    bottomBorder.frame = CGRectMake(40, 59, calibrationLabel.frame.size.width-80, 1.0);
    bottomBorder.backgroundColor = [UIColor whiteColor].CGColor;
    [calibrationLabel.layer addSublayer:bottomBorder];
    [viewCalibrationAlert addSubview:calibrationLabel];
    
    UIButton *buttonCalibration = [[UIButton alloc] initWithFrame:CGRectMake(calibrationLabel.frame.origin.x + 40,calibrationLabel.frame.origin.y + 60, calibrationLabel.frame.size.width/2 - 40, 60)];
    [buttonCalibration setTitle:@"Recalibrate" forState:UIControlStateNormal];
    [buttonCalibration addTarget:self action:@selector(runCalibration) forControlEvents:UIControlEventTouchUpInside];
    buttonCalibration.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [buttonCalibration setBackgroundColor:[UIColor blackColor]];
    [viewCalibrationAlert addSubview:buttonCalibration];
    
    UIButton *buttonDismissCalibration = [[UIButton alloc] initWithFrame:CGRectMake(calibrationLabel.frame.size.width/2,calibrationLabel.frame.origin.y + 60, calibrationLabel.frame.size.width/2 - 40, 60)];
    [buttonDismissCalibration setTitle:@"Cancel" forState:UIControlStateNormal];
    [buttonDismissCalibration addTarget:self action:@selector(dismissCalibrationAlert) forControlEvents:UIControlEventTouchUpInside];
    buttonDismissCalibration.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    [buttonDismissCalibration setBackgroundColor:[UIColor blackColor]];
    [viewCalibrationAlert addSubview:buttonDismissCalibration];
    
    [self.view addSubview:viewCalibrationAlert];
    [self.view bringSubviewToFront:viewCalibrationAlert];
}

- (void)dismissCalibrationAlert
{
    [viewCalibrationAlert removeFromSuperview];
    self.viewCalibrationAlert = nil;
}

- (void)runCalibration
{
    [self dismissCalibrationAlert];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *filePath = [defaults objectForKey:@"calibrationImagePath"];
    BOOL oldCalibration = [defaults boolForKey:@"isCalibrated"];
    
    PODCalibrateViewController *vc = [[PODCalibrateViewController alloc] initWithNibName:nil bundle:nil];
    if (!oldCalibration && !filePath) {
        vc.showOOBE = YES;
    }
    [self presentViewController:vc animated:NO completion:NULL];
}

- (void)launchCamera
{
    PODRecordViewController *recordViewController = [[PODRecordViewController alloc] initWithNibName:nil bundle:nil];
    
    AppDelegate *poppyAppDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if(poppyAppDelegate.switchToCamera) {
        poppyAppDelegate.switchToCamera = NO;
        [self presentViewController:recordViewController animated:NO completion:nil];
    } else {
        recordViewController.modalTransitionStyle=UIModalTransitionStyleFlipHorizontal;
        [self presentViewController:recordViewController animated:YES completion:nil];
    }
}

- (void)launchViewer
{
    AppDelegate *poppyAppDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    BOOL animated = !poppyAppDelegate.switchToViewer;
    poppyAppDelegate.switchToViewer = NO;
    
    if(UIDeviceOrientationIsLandscape(self.interfaceOrientation)) {
        ViewerViewController *vvc = [[ViewerViewController alloc] initWithNibName:@"LiveView" bundle:nil];
        vvc.modalTransitionStyle=UIModalTransitionStyleFlipHorizontal;
        [self presentViewController:vvc animated:animated completion:nil];
    } else {
        PortraitViewerViewController *pvc = [[PortraitViewerViewController alloc] init];
        pvc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        [self presentViewController:pvc animated:animated completion:nil];
    }
}

- (void)launchStream
{
    [self launchGallery:NO];
}

- (void)launchBest
{
    [self launchGallery:YES];
}

-(void)launchGallery:(BOOL)best
{
    AppDelegate *poppyAppDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    BOOL animated = !poppyAppDelegate.switchToGallery;
    poppyAppDelegate.switchToGallery = NO;
    
    if (poppyAppDelegate.isConnected) {
        if(UIDeviceOrientationIsLandscape(self.interfaceOrientation)) {
            GalleryViewController *gvc = [[GalleryViewController alloc] initWithNibName:@"LiveView" bundle:nil];
            gvc.modalTransitionStyle=UIModalTransitionStyleFlipHorizontal;
            gvc.showPopular = best;
            [self presentViewController:gvc animated:animated completion:nil];
        } else {
            PortraitGalleryViewController *pgvc = [[PortraitGalleryViewController alloc] initWithNibName:nil bundle:nil];
            pgvc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            pgvc.showPopular = best;
            [self presentViewController:pgvc animated:animated completion:nil];
        }
    } else {
        // show the No Connection popup
        [poppyAppDelegate loadImageArrays];
        showPopular = best;
        [self showConnectionAlert];
    }
}

- (void)launchHelp
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://poppy3d.com/app-help"]];
}

- (void)showConnectionAlert
{
    viewConnectionAlert = [[UIView alloc] initWithFrame:self.view.bounds];
    [viewConnectionAlert setAutoresizingMask: UIViewAutoresizingFlexibleTopMargin];
    
    UIView *viewShadow = [[UIView alloc] initWithFrame:self.view.bounds];
    viewShadow.backgroundColor = [UIColor blackColor];
    viewShadow.alpha = 0.8;
    UITapGestureRecognizer *handleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissConnectionAlert)];
    [viewShadow addGestureRecognizer:handleTap];
    [viewConnectionAlert addSubview:viewShadow];
    
    UILabel *connectionLabel = [[UILabel alloc] init];
    
    if (viewConnectionAlert.frame.size.height > viewConnectionAlert.frame.size.width) {
        //portrait view
        [connectionLabel setFrame:CGRectMake(0, 120, viewConnectionAlert.frame.size.width, 60)];
    } else {
        //landscape view
        [connectionLabel setFrame:CGRectMake(viewConnectionAlert.frame.size.width/2,(viewConnectionAlert.frame.size.height - 120)/2,viewConnectionAlert.frame.size.width/2,60)];
    }
    [connectionLabel setTextAlignment:NSTextAlignmentCenter];
    [connectionLabel setBackgroundColor:[UIColor blackColor]];
    [connectionLabel setTextColor:[UIColor whiteColor]];
    [connectionLabel setText: @"Uh oh, network trouble!"];
    CALayer *bottomBorder = [CALayer layer];
    bottomBorder.frame = CGRectMake(40, 59, connectionLabel.frame.size.width-80, 1.0);
    bottomBorder.backgroundColor = [UIColor whiteColor].CGColor;
    [connectionLabel.layer addSublayer:bottomBorder];
    [viewConnectionAlert addSubview:connectionLabel];
    
    UIButton *buttonConnection = [[UIButton alloc] initWithFrame:CGRectMake(connectionLabel.frame.origin.x,connectionLabel.frame.origin.y + 60, connectionLabel.frame.size.width, 60)];
    [buttonConnection setTitle:@"Try again" forState:UIControlStateNormal];
    [buttonConnection addTarget:self action:@selector(reattemptConnection) forControlEvents:UIControlEventTouchUpInside];
    [buttonConnection setBackgroundColor:[UIColor blackColor]];
    [viewConnectionAlert addSubview:buttonConnection];

    [self.view addSubview:viewConnectionAlert];
    [self.view bringSubviewToFront:viewConnectionAlert];
}

- (void)reattemptConnection
{
    [self dismissConnectionAlert];
    AppDelegate *poppyAppDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (poppyAppDelegate.isConnected) {
        if(showPopular){
            [self launchBest];
        } else {
            [self launchStream];
        }
    }
}


- (void)dismissConnectionAlert
{
    [viewConnectionAlert removeFromSuperview];
    self.viewConnectionAlert = nil;
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
        [self showLandscape];
    } else {
        [self showPortrait];
    }
    [self dismissConnectionAlert];
    [self dismissCalibrationAlert];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

@end
