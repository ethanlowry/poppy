//
//  WelcomeViewController.m
//  Poppy
//
//  Created by Ethan Lowry on 12/7/13.
//  Copyright (c) 2014 Hack Things LLC. All rights reserved.
//

#import "WelcomeViewController.h"
#import "PODCalibrateViewController.h"

@interface WelcomeViewController ()

@end

int currentFrame = 0;
NSMutableArray *frameArray;
UIView *viewStep0;
UIView *viewStep1;
UIView *viewStep2;
UIView *viewStep3;
UIView *viewStep4;
UIView *touchView;

@implementation WelcomeViewController

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
}

- (void)viewDidAppear:(BOOL)animated
{
    [self createFrames];
    [self createTouchView];
    [self showFrame:0];
}

- (void)createTouchView
{
    touchView = [[UIView alloc] initWithFrame:self.view.bounds];
    [self addGestures:touchView];
    
    UIView *viewShadow = [[UIView alloc] initWithFrame:CGRectMake(0,touchView.frame.size.height - 75,touchView.frame.size.width,75)];
    [viewShadow setBackgroundColor:[UIColor blackColor]];
    [viewShadow setAlpha:0.5];
    
    UIButton *buttonLeft = [[UIButton alloc] initWithFrame: CGRectMake(20, touchView.frame.size.height - 75, 70, 75)];
    [buttonLeft setTitle:@"Previous" forState:UIControlStateNormal];
    [buttonLeft setTag:86];
    [buttonLeft addTarget:self action:@selector(showPrev) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *buttonRight = [[UIButton alloc] initWithFrame: CGRectMake(touchView.frame.size.width - 80, touchView.frame.size.height - 75, 70, 75)];
    [buttonRight setTitle:@"Next" forState:UIControlStateNormal];
    [buttonRight addTarget:self action:@selector(showNext) forControlEvents:UIControlEventTouchUpInside];

    [touchView addSubview:viewShadow];
    [touchView addSubview:buttonLeft];
    [touchView addSubview:buttonRight];
    
    [self.view addSubview:touchView];
}

- (void)createFrames
{
    frameArray = [[NSMutableArray alloc] init];
    
    // Welcome
    UIView *welcomeView = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.view.bounds.size.width, self.view.bounds.size.height)];
    [welcomeView setBackgroundColor:[UIColor whiteColor]];
    UIImageView *logoImgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo"]];
    [logoImgView setFrame:CGRectMake((self.view.bounds.size.width - 350)/2,35,350,69)];
    [welcomeView addSubview:[self makeLabel:@"Welcome to Poppy!\nBefore you put your iPhone in Poppy,\nhere are a few tips." withFrame:CGRectMake(0,0,welcomeView.frame.size.width, welcomeView.frame.size.height) withAlignment:NSTextAlignmentCenter withSize:20]];
    [welcomeView addSubview:logoImgView];
    [frameArray addObject:welcomeView];
    
    // Choosing adapter
    UIView *adapterView = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.view.bounds.size.width, self.view.bounds.size.height)];
    [adapterView setBackgroundColor:[UIColor whiteColor]];
    UIImageView *adapterImgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"adapter"]];
    [adapterImgView setFrame:CGRectMake(self.view.bounds.size.width - 190,(self.view.bounds.size.height - 275)/2,150,200)];
    [adapterView addSubview:[self makeLabel:@"Choose the right adapter and load it into Poppy. Leave your phone out for now." withFrame:CGRectMake(40,0,self.view.bounds.size.width - 270, self.view.bounds.size.height - 75) withAlignment:NSTextAlignmentLeft withSize:20]];
    [adapterView addSubview:adapterImgView];
    [frameArray addObject:adapterView];
    
    // Open Poppy to capture footage
    UIView *rotatePoppyView = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.view.bounds.size.width, self.view.bounds.size.height)];
    [rotatePoppyView setBackgroundColor:[UIColor whiteColor]];
    UIImageView *rotateImgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"twist"]];
    [rotateImgView setFrame:CGRectMake(self.view.bounds.size.width - 220,(self.view.bounds.size.height - 275)/2,200,200)];
    [rotatePoppyView addSubview:[self makeLabel:@"Twist Poppy open to shoot video or photos." withFrame:CGRectMake(40,0,self.view.bounds.size.width - 280, self.view.bounds.size.height - 75) withAlignment:NSTextAlignmentLeft withSize:20]];
    [rotatePoppyView addSubview:rotateImgView];
    [frameArray addObject:rotatePoppyView];
    
    // Use thumbholes to access controls
    UIView *thumbholeView = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.view.bounds.size.width, self.view.bounds.size.height)];
    [thumbholeView setBackgroundColor:[UIColor whiteColor]];
    UIImageView *thumbsImgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"thumbs"]];
    [thumbsImgView setFrame:CGRectMake(self.view.bounds.size.width - 220,(self.view.bounds.size.height - 275)/2,200,200)];
    [thumbholeView addSubview:[self makeLabel:@"Use the thumb holes on the bottom of Poppy to access screen controls, or to slide your phone out of Poppy." withFrame:CGRectMake(40,0,self.view.bounds.size.width - 280, self.view.bounds.size.height - 75) withAlignment:NSTextAlignmentLeft withSize:20]];
    [thumbholeView addSubview:thumbsImgView];
    [frameArray addObject:thumbholeView];
    
    // On screen controls
    UIView *screenView = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.view.bounds.size.width, self.view.bounds.size.height)];
    [screenView setBackgroundColor:[UIColor whiteColor]];
    //UIImageView *screenImgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"screencontrols"]];
    //[screenImgView setFrame:CGRectMake((self.view.bounds.size.width - 245)/2,(self.view.bounds.size.height - 140)/2,245,120)];
    float leftPosition = (self.view.bounds.size.width - 480)/2;
    UIImageView *bulletView1 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bullet"]];
    [bulletView1 setFrame: CGRectMake(leftPosition + 32, 68, 10, 10)];
    [screenView addSubview:bulletView1];
    UIImageView *bulletView2 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bullet"]];
    [bulletView2 setFrame: CGRectMake(leftPosition + 32, 108, 10, 10)];
    [screenView addSubview:bulletView2];
    UIImageView *bulletView3 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bullet"]];
    [bulletView3 setFrame: CGRectMake(leftPosition + 32, 148, 10, 10)];
    [screenView addSubview:bulletView3];
    UIImageView *bulletView4 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bullet"]];
    [bulletView4 setFrame: CGRectMake(leftPosition + 32, 188, 10, 10)];
    [screenView addSubview:bulletView4];
    [screenView addSubview:[self makeLabel:@"Gesture Controls" withFrame:CGRectMake(0,20,self.view.bounds.size.width,25) withAlignment:NSTextAlignmentCenter withSize:24]];
    [screenView addSubview:[self makeLabel:@"Tap the screen to focus when taking pictures" withFrame:CGRectMake(leftPosition + 50,60,self.view.bounds.size.width,25) withAlignment:NSTextAlignmentLeft withSize:20]];
    [screenView addSubview:[self makeLabel:@"Tap the screen to pause or play a video" withFrame:CGRectMake(leftPosition + 50,100,self.view.bounds.size.width,25) withAlignment:NSTextAlignmentLeft withSize:20]];
    [screenView addSubview:[self makeLabel:@"Swipe left or right to see images you’ve taken" withFrame:CGRectMake(leftPosition + 50,140,self.view.bounds.size.width,25) withAlignment:NSTextAlignmentLeft withSize:20]];
    [screenView addSubview:[self makeLabel:@"Or double tap on the right or left side to see\nthe next or previous image" withFrame:CGRectMake(leftPosition + 50,180,self.view.bounds.size.width,50) withAlignment:NSTextAlignmentLeft withSize:20]];
    //[screenView addSubview:screenImgView];
    [frameArray addObject:screenView];
    
    // Playback controls
    /*
    UIView *playbackView = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.view.bounds.size.width, self.view.bounds.size.height)];
    [playbackView setBackgroundColor:[UIColor whiteColor]];
    UIImageView *playbackImgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"screencontrolscamera"]];
    [playbackImgView setFrame:CGRectMake(self.view.bounds.size.width - 126,(self.view.bounds.size.height - 135)/2,66,60)];
    [playbackView addSubview:[self makeLabel:@"Swipe left and right to see images you’ve taken. Tap the camera button to switch back to taking pictures." withFrame:CGRectMake(40,0,self.view.bounds.size.width - 200, self.view.bounds.size.height - 75) withAlignment:NSTextAlignmentLeft withSize:20]];
    [playbackView addSubview:playbackImgView];
    [frameArray addObject:playbackView];
     */
    
    // Calibration
    UIView *calibrateView = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.view.bounds.size.width, self.view.bounds.size.height)];
    [calibrateView setBackgroundColor:[UIColor whiteColor]];
    [calibrateView addSubview:[self makeLabel:@"To get the best quality images with Poppy you will need to do a one-time calibration for your camera. Twist Poppy open and place your iPhone in the slot." withFrame:CGRectMake(60,0,calibrateView.frame.size.width - 120, calibrateView.frame.size.height - 75) withAlignment:NSTextAlignmentLeft withSize:20]];
    [frameArray addObject:calibrateView];
}

- (UILabel *)makeLabel:(NSString *)text withFrame:(CGRect)frame withAlignment:(NSTextAlignment)align withSize:(int)size
{
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    
    [label setTextColor:[UIColor darkGrayColor]];
    [label setBackgroundColor:[UIColor clearColor]];
    [label setTextAlignment:align];
    [label setFont:[UIFont systemFontOfSize:size]];
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.numberOfLines = 0;
    [label setText:text];
    
    return label;
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
    [self switchToViewer];
}

- (void) switchToViewer
{
    
    [self dismissViewControllerAnimated:NO completion:^{}];
}

- (void)swipeScreenRight:(UISwipeGestureRecognizer *)sgr
{
    [self showPrev];
}

- (void)showNext
{
    if (currentFrame < [frameArray count] - 1) {
        currentFrame = currentFrame + 1;
        [self showFrame:currentFrame];
    } else {
        PODCalibrateViewController *vc = (id) self.presentingViewController;
        vc.showOOBE = NO;
        [self dismissViewControllerAnimated:NO completion:^{}];
    }
}

- (void)showPrev
{
    if (currentFrame > 0) {
        currentFrame = currentFrame - 1;
        [self showFrame:currentFrame];
    }
}

- (void)showFrame:(int)frame
{
    if (frame < frameArray.count){
        for(int i=0;i < frameArray.count; i++){
            UIView *currentFrameView = [frameArray objectAtIndex:i];
            if (i == frame) {
                [self.view addSubview:currentFrameView];
                
                if (frame == 0) {
                    [touchView viewWithTag:86].hidden = YES;
                } else {
                    [touchView viewWithTag:86].hidden = NO;
                }
                [self.view bringSubviewToFront:touchView];
            } else {
                [currentFrameView removeFromSuperview];
            }
        }
    }
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return  UIInterfaceOrientationMaskLandscapeLeft;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
