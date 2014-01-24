//
//  CalibrationViewController.m
//  Poppy
//
//  Created by Ethan Lowry on 12/4/13.
//  Copyright (c) 2013 Ethan Lowry. All rights reserved.
//

#import "CalibrationViewController.h"
#import "WelcomeViewController.h"
#import <sys/utsname.h>

@interface CalibrationViewController ()

@end

float cropPosition;
float calibrationCropFactor;

UIView *viewWelcome;

@implementation CalibrationViewController

@synthesize showOOBE;
@synthesize viewCalNumber;

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
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    cropPosition = [defaults floatForKey:@"xOffset"];
    if (!cropPosition) {
        cropPosition = 0;
    }
    
    calibrationCropFactor = [self setCropFactor];
}

- (void)calibrateLeft: (id) sender
{
    cropPosition = cropPosition - 0.005;
    cropPosition = (cropPosition > -(1.0 - calibrationCropFactor)/2 ? cropPosition : -(1.0 - calibrationCropFactor)/2);
    [self applyFilter];
    [self showCalNumber];
}

- (void)calibrateRight: (id) sender
{
    cropPosition = cropPosition + 0.005;
    cropPosition = (cropPosition < (1.0 - calibrationCropFactor)/2 ? cropPosition : (1.0 - calibrationCropFactor)/2);
    [self applyFilter];
    [self showCalNumber];
}

- (void)viewDidAppear:(BOOL)animated
{
    if (showOOBE) {
        NSLog(@"ABOUT TO SHOW OOBE");
        WelcomeViewController *wvc = [[WelcomeViewController alloc] initWithNibName:@"LiveView" bundle:nil];
        [self presentViewController:wvc animated:NO completion:nil];
    } else {
        [self showWelcomeAlert];
        mainView = (GPUImageView *)self.view;
        mainView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
        [self activateCamera];
    }
}

-(void)showCalNumber
{
    if (!viewCalNumber) {
        viewCalNumber = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 30)];
        UIView *viewShadow = [[UIView alloc] initWithFrame:viewCalNumber.bounds];
        [viewShadow setBackgroundColor:[UIColor blackColor]];
        [viewShadow setAlpha:0.3];
        [viewCalNumber addSubview:viewShadow];
        UILabel *labelCalNumberL = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, viewCalNumber.frame.size.width/2, viewCalNumber.frame.size.height)];
        [labelCalNumberL setTextColor:[UIColor whiteColor]];
        [labelCalNumberL setFont:[UIFont systemFontOfSize:12.0]];
        [labelCalNumberL setTextAlignment:NSTextAlignmentCenter];
        
        UILabel *labelCalNumberR = [[UILabel alloc] initWithFrame:CGRectMake(viewCalNumber.frame.size.width/2, 0, viewCalNumber.frame.size.width/2, viewCalNumber.frame.size.height)];
        [labelCalNumberR setTextColor:[UIColor whiteColor]];
        [labelCalNumberR setFont:[UIFont systemFontOfSize:12.0]];
        [labelCalNumberR setTextAlignment:NSTextAlignmentCenter];
        
        [viewCalNumber addSubview:labelCalNumberL];
        [viewCalNumber addSubview:labelCalNumberR];
        [self.view addSubview:viewCalNumber];
    }
    for(UIView *subview in viewCalNumber.subviews )
    {
        if([subview isKindOfClass:[UILabel class]])
        {
            UILabel *label = (id)subview;
            int num = (int)(cropPosition * 200);
            NSString *sign = num > 0 ? @"+" : (num < 0 ? @"-" : @"");
            label.text = [NSString stringWithFormat:@"%@ %d", sign , abs(num)];
        }
    }
}

- (void)activateCamera
{
    stillCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionBack];
    stillCamera.outputImageOrientation = UIInterfaceOrientationLandscapeLeft;
    stillCamera.horizontallyMirrorRearFacingCamera = NO;
    [self applyFilter];
    [stillCamera startCameraCapture];
}

- (void)applyFilter
{
    [stillCamera removeAllTargets];
    
    float xDisplacement = cropPosition + (1.0 - calibrationCropFactor)/2;
    displayFilter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(xDisplacement, (1.0 - calibrationCropFactor)/2, calibrationCropFactor, calibrationCropFactor)];
    
    [stillCamera addTarget:displayFilter];
    [displayFilter addTarget:mainView];
}

- (void) showControls
{
    UIView *viewControls = [[UIView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width/2, self.view.bounds.size.height - 75,self.view.bounds.size.width/2, 75)];
    
    UIView *viewShadow = [[UIView alloc] initWithFrame:CGRectMake(0,0,viewControls.frame.size.width,75)];
    [viewShadow setBackgroundColor:[UIColor blackColor]];
    [viewShadow setAlpha:0.3];
    
    UIButton *buttonLeft = [[UIButton alloc] initWithFrame: CGRectMake(viewControls.frame.size.width - 230, 0, 70, 75)];
    [buttonLeft setImage:[UIImage imageNamed:@"arrow-left"] forState:UIControlStateNormal];
    [buttonLeft addTarget:self action:@selector(calibrateLeft:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *buttonDone = [[UIButton alloc] initWithFrame: CGRectMake(viewControls.frame.size.width - 150, 0, 70, 75)];
    [buttonDone setTitle:@"Done" forState:UIControlStateNormal];
    [buttonDone addTarget:self action:@selector(calibrationComplete:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *buttonRight = [[UIButton alloc] initWithFrame: CGRectMake(viewControls.frame.size.width - 70, 0, 70, 75)];
    [buttonRight setImage:[UIImage imageNamed:@"arrow-right"] forState:UIControlStateNormal];
    [buttonRight addTarget:self action:@selector(calibrateRight:) forControlEvents:UIControlEventTouchUpInside];
    
    [viewControls addSubview: viewShadow];
    [viewControls addSubview: buttonLeft];
    [viewControls addSubview: buttonDone];
    [viewControls addSubview: buttonRight];
    
    [mainView addSubview:viewControls];
    [mainView bringSubviewToFront:viewControls];
}

- (void)showWelcomeAlert
{
    viewWelcome = [[UIView alloc] initWithFrame:CGRectMake(0, (self.view.bounds.size.height - 75)/2, self.view.bounds.size.width, 75)];
    [viewWelcome setAutoresizingMask: UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin];
    
    UIView *viewShadow = [[UIView alloc] initWithFrame:CGRectMake(0,0,viewWelcome.frame.size.width, viewWelcome.frame.size.height)];
    [viewShadow setBackgroundColor:[UIColor blackColor]];
    [viewShadow setAlpha:0.3];
    
    NSString *labelText = @"Put me in Poppy and move\nimage left or right to calibrate";
    
    UILabel *labelWelcomeL = [[UILabel alloc] initWithFrame:CGRectMake(0,0,viewWelcome.frame.size.width/2, viewWelcome.frame.size.height)];
    [labelWelcomeL setTextColor:[UIColor whiteColor]];
    [labelWelcomeL setBackgroundColor:[UIColor clearColor]];
    [labelWelcomeL setTextAlignment:NSTextAlignmentCenter];
    [labelWelcomeL setFont:[UIFont systemFontOfSize:14.0]];
    labelWelcomeL.lineBreakMode = NSLineBreakByWordWrapping;
    labelWelcomeL.numberOfLines = 0;
    [labelWelcomeL setText:labelText];
    
    UILabel *labelWelcomeR = [[UILabel alloc] initWithFrame:CGRectMake(viewWelcome.frame.size.width/2,0,viewWelcome.frame.size.width/2, viewWelcome.frame.size.height)];
    [labelWelcomeR setTextColor:[UIColor whiteColor]];
    [labelWelcomeR setBackgroundColor:[UIColor clearColor]];
    [labelWelcomeR setTextAlignment:NSTextAlignmentCenter];
    [labelWelcomeR setFont:[UIFont systemFontOfSize:14.0]];
    labelWelcomeR.lineBreakMode = NSLineBreakByWordWrapping;
    labelWelcomeR.numberOfLines = 0;
    [labelWelcomeR setText:labelText];
    
    [viewWelcome addSubview:viewShadow];
    [viewWelcome addSubview:labelWelcomeL];
    [viewWelcome addSubview:labelWelcomeR];
    
    [self.view addSubview:viewWelcome];
    
    [UIView animateWithDuration:0.5 delay:0.0
                        options: (UIViewAnimationOptionCurveEaseInOut & UIViewAnimationOptionBeginFromCurrentState)
                     animations:^{
                         viewWelcome.alpha = 1.0;
                     }
                     completion:^(BOOL complete){
                         [NSTimer scheduledTimerWithTimeInterval:4.0 target:self selector:@selector(welcomeTimerFired:) userInfo:nil repeats:NO];
                     }];
}

- (void)welcomeTimerFired:(NSTimer *)timer
{
    [UIView animateWithDuration:0.5 delay:0.0
                        options: (UIViewAnimationOptionCurveEaseInOut & UIViewAnimationOptionBeginFromCurrentState)
                     animations:^{
                         viewWelcome.alpha = 0.0;
                     }
                     completion:^(BOOL complete){
                         [viewWelcome removeFromSuperview];
                         [self showCalNumber];
                         [self showControls];
                     }];
}

- (void) calibrationComplete: (id) sender
{
    NSLog(@"CALIBRATION COMPLETE! %f", cropPosition);
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:@"isCalibrated"];
    [defaults setFloat:cropPosition forKey:@"xOffset"];
    [defaults synchronize];
    
    
    //[buttonStealer stopStealingVolumeButtonEvents];
    //buttonStealer = nil;
    
    
    [stillCamera removeAllTargets];
    [stillCamera stopCameraCapture];
    stillCamera = nil;
    
    /*
    LiveViewController *lvc = (id) self.presentingViewController;
    lvc.xOffset = cropPosition;
    lvc.isViewActive = YES;
     */
    
    [self dismissViewControllerAnimated:NO completion:^{}];
}

- (float)setCropFactor
{
    NSLog(@"MODEL: %i", [self deviceModelNumber]);
    int phoneModel = [self deviceModelNumber];
    float modelCropFactor;
    
    switch (phoneModel) {
        case 40:
            modelCropFactor = 0.8;
            break;
        case 41:
            modelCropFactor = 0.8;
            break;
        case 50:
            modelCropFactor = 0.7;
            break;
        case 51:
            modelCropFactor = 0.7;
            break;
        case 52:
            modelCropFactor = 0.7;
            break;
        case 99:
            modelCropFactor = 0.8;
            break;
        default:
            modelCropFactor = 0.7;
            break;
    }
    return modelCropFactor;
}

- (int)deviceModelNumber {
    
    struct utsname systemInfo;
    
    uname(&systemInfo);
    
    NSString *machineName = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    NSDictionary *commonNamesDictionary =
    @{
      @"iPhone3,1":    @"40",
      @"iPhone3,2":    @"40",
      @"iPhone3,3":    @"40",
      @"iPhone4,1":    @"41",
      @"iPhone5,1":    @"50",
      @"iPhone5,2":    @"50",
      @"iPhone5,3":    @"51",
      @"iPhone5,4":    @"51",
      @"iPhone6,1":    @"52",
      @"iPhone6,2":    @"53",
      @"iPod5,1":  @"99",
      
      /*
       @"iPhone3,1":    @"iPhone 4",
       @"iPhone3,2":    @"iPhone 4(Rev A)",
       @"iPhone3,3":    @"iPhone 4(CDMA)",
       @"iPhone4,1":    @"iPhone 4S",
       @"iPhone5,1":    @"iPhone 5(GSM)",
       @"iPhone5,2":    @"iPhone 5(GSM+CDMA)",
       @"iPhone5,3":    @"iPhone 5c(GSM)",
       @"iPhone5,4":    @"iPhone 5c(GSM+CDMA)",
       @"iPhone6,1":    @"iPhone 5s(GSM)",
       @"iPhone6,2":    @"iPhone 5s(GSM+CDMA)",
       @"iPod5,1":  @"iPod 5th Gen",
       */
      
      };
    
    NSString *deviceNumber = commonNamesDictionary[machineName];
    
    return deviceNumber.intValue;
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

@end
