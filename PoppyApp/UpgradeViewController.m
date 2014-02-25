//
//  UpgradeViewController.m
//  Poppy
//
//  Created by Ethan Lowry on 1/21/14.
//  Copyright (c) 2014 Hack Things LLC. All rights reserved.
//

#import "UpgradeViewController.h"
#import "AppDelegate.h"

@interface UpgradeViewController ()

@end

@implementation UpgradeViewController

BOOL requireUpgrade = NO;

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

-(void)viewDidAppear:(BOOL)animated
{
    AppDelegate *poppyAppDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSString *labelText;
    if ([poppyAppDelegate.versionCheck isEqualToString:@"force_upgrade"]) {
        requireUpgrade = YES;
        labelText = @"Please upgrade to the latest version of the Poppy 3D app";
    } else {
        requireUpgrade = NO;
        labelText = @"A newer version of the\nPoppy 3D app is available";
    }
    
    [self.view setBackgroundColor:[UIColor darkGrayColor]];
    UILabel *upgradeLabel = [[UILabel alloc] initWithFrame:CGRectMake(30, 120, self.view.frame.size.width-60, 120)];
    [upgradeLabel setText:labelText];
    [upgradeLabel setTextColor:[UIColor whiteColor]];
    [upgradeLabel setBackgroundColor:[UIColor blackColor]];
    [upgradeLabel setTextAlignment:NSTextAlignmentCenter];
    upgradeLabel.lineBreakMode = NSLineBreakByWordWrapping;
    upgradeLabel.numberOfLines = 0;
    CALayer *bottomBorder = [CALayer layer];
    bottomBorder.frame = CGRectMake(40, 119, upgradeLabel.frame.size.width-80, 1.0);
    bottomBorder.backgroundColor = [UIColor whiteColor].CGColor;
    [upgradeLabel.layer addSublayer:bottomBorder];
    [self.view addSubview:upgradeLabel];
    
    UIButton *buttonGetUpgrade = [[UIButton alloc] init];
    [buttonGetUpgrade setTitle:@"Upgrade" forState:UIControlStateNormal];
    [buttonGetUpgrade addTarget:self action:@selector(getUpgrade) forControlEvents:UIControlEventTouchUpInside];
    [buttonGetUpgrade setBackgroundColor:[UIColor blackColor]];
    [self.view addSubview:buttonGetUpgrade];
    if (!requireUpgrade) {
        [buttonGetUpgrade setFrame:CGRectMake(30, 240, self.view.frame.size.width/2 - 30, 60)];
        UIButton *buttonIgnore = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2, 240, self.view.frame.size.width/2 - 30, 60)];
        [buttonIgnore setTitle:@"Cancel" forState:UIControlStateNormal];
        [buttonIgnore addTarget:self action:@selector(dismissAlert) forControlEvents:UIControlEventTouchUpInside];
        [buttonIgnore setBackgroundColor:[UIColor blackColor]];
        [self.view addSubview:buttonIgnore];
    } else {
        [buttonGetUpgrade setFrame:CGRectMake(30, 240, self.view.frame.size.width - 60, 60)];
    }
}

- (void)getUpgrade
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms://itunes.apple.com/app/id779230686"]];
}

- (void) dismissAlert
{
    AppDelegate *poppyAppDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    poppyAppDelegate.versionCheck = @"ok";
    [self dismissViewControllerAnimated:NO completion:^{}];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

@end
