//
//  CalibrationViewController.m
//  Poppy
//
//  Created by Ethan Lowry on 12/4/13.
//  Copyright (c) 2013 Ethan Lowry. All rights reserved.
//

#import "CalibrationViewController.h"
#import "LiveViewController.h"
#import <sys/utsname.h>

@interface CalibrationViewController ()

@end

float cropPosition;
float calibrationCropFactor;

UIView *viewWelcome;

@implementation CalibrationViewController

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
    NSLog(@"CROP POSITION: %f", cropPosition);
    
    calibrationCropFactor = [self setCropFactor];
    
    __weak typeof(self) weakSelf = self;
    
    buttonStealer = [[RBVolumeButtons alloc] init];
    buttonStealer.upBlock = ^{
        // + volume button pressed
        cropPosition = cropPosition + 0.005;
        cropPosition = (cropPosition < (1.0 - calibrationCropFactor)/2 ? cropPosition : (1.0 - calibrationCropFactor)/2);
        NSLog(@"%f", cropPosition);
        [weakSelf applyFilter];
    };
    buttonStealer.downBlock = ^{
        // - volume button pressed
        cropPosition = cropPosition - 0.005;
        cropPosition = (cropPosition > -(1.0 - calibrationCropFactor)/2 ? cropPosition : -(1.0 - calibrationCropFactor)/2);
        NSLog(@"%f", cropPosition);
        [weakSelf applyFilter];
    };
    
    [buttonStealer startStealingVolumeButtonEvents];
}

- (void)viewDidAppear:(BOOL)animated
{
    mainView = (GPUImageView *)self.view;
    mainView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;

    // set up gestures
    /*
    UIView *touchView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.height, self.view.frame.size.width)];
    [self addGestures:touchView];
    [self.view addSubview:touchView];
    */
    [self activateCamera];
    [self showWelcomeAlert];
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

- (void) showDoneButton
{
    UIView *viewControls = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 75, self.view.bounds.size.width, 75)];
    
    UIView *viewShadow = [[UIView alloc] initWithFrame:CGRectMake(viewControls.frame.size.width/2,0,viewControls.frame.size.width/2,75)];
    [viewShadow setBackgroundColor:[UIColor blackColor]];
    [viewShadow setAlpha:0.3];
    
    UIButton *buttonDone = [[UIButton alloc] initWithFrame: CGRectMake(viewControls.frame.size.width/2,0,viewControls.frame.size.width/2,75)];
    [buttonDone setTitle:@"Tap here when calibrated" forState:UIControlStateNormal];
    [buttonDone addTarget:self action:@selector(calibrationComplete:) forControlEvents:UIControlEventTouchUpInside];
    [viewControls addSubview: viewShadow];
    [viewControls addSubview: buttonDone];
    
    [self.view addSubview:viewControls];
    [self.view bringSubviewToFront:viewControls];
}

- (void)showWelcomeAlert
{
    viewWelcome = [[UIView alloc] initWithFrame:CGRectMake(0, (self.view.bounds.size.height - 75)/2, self.view.bounds.size.width, 75)];
    [viewWelcome setAutoresizingMask: UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin];
    
    UIView *viewShadow = [[UIView alloc] initWithFrame:CGRectMake(0,0,viewWelcome.frame.size.width, viewWelcome.frame.size.height)];
    [viewShadow setBackgroundColor:[UIColor blackColor]];
    [viewShadow setAlpha:0.3];
    
    UILabel *labelWelcome = [[UILabel alloc] initWithFrame:CGRectMake(0,0,viewWelcome.frame.size.width, viewWelcome.frame.size.height)];
    [labelWelcome setTextColor:[UIColor whiteColor]];
    [labelWelcome setBackgroundColor:[UIColor clearColor]];
    [labelWelcome setTextAlignment:NSTextAlignmentCenter];
    //[labelWelcome setFont:[UIFont boldSystemFontOfSize:24]];
    [labelWelcome setTextAlignment:NSTextAlignmentCenter];
    labelWelcome.lineBreakMode = NSLineBreakByWordWrapping;
    labelWelcome.numberOfLines = 0;
    [labelWelcome setText:@"Put me in Poppy\nThen use the phone's +/- volume buttons to calibrate"];
    
    [viewWelcome addSubview:viewShadow];
    [viewWelcome addSubview:labelWelcome];
    
    [self.view addSubview:viewWelcome];
    
    [UIView animateWithDuration:0.5 delay:0.0
                        options: (UIViewAnimationOptionCurveEaseInOut & UIViewAnimationOptionBeginFromCurrentState)
                     animations:^{
                         viewWelcome.alpha = 1.0;
                     }
                     completion:^(BOOL complete){
                         [NSTimer scheduledTimerWithTimeInterval:7.0 target:self selector:@selector(welcomeTimerFired:) userInfo:nil repeats:NO];
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
                         [self showDoneButton];
                     }];
}

- (void) calibrationComplete: (id) sender
{
    NSLog(@"CALIBRATION COMPLETE! %f", cropPosition);
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:@"isCalibrated"];
    [defaults setFloat:cropPosition forKey:@"xOffset"];
    [defaults synchronize];
    
    [buttonStealer stopStealingVolumeButtonEvents];
    buttonStealer = nil;
    
    [stillCamera removeAllTargets];
    [stillCamera stopCameraCapture];
    stillCamera = nil;
    
    LiveViewController *lvc = (id) self.presentingViewController;
    lvc.xOffset = cropPosition;
    lvc.isViewActive = YES;
    [self dismissViewControllerAnimated:YES completion:^{}];
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
