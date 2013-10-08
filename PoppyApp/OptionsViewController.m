//
//  OptionsViewController.m
//  PoppyApp
//
//  Created by Patrick O'Donnell on 10/7/13.
//  Copyright (c) 2013 Ethan Lowry. All rights reserved.
//

#import "OptionsViewController.h"
#import "LiveViewController.h"

@interface OptionsViewController ()

@end

@implementation OptionsViewController

- (void)viewDidLoad
{
    self->lView = [[LiveViewController alloc] initWithNibName:@"LiveView" bundle:nil];

}

- (NSUInteger)supportedInterfaceOrientations
{
    return
    UIInterfaceOrientationMaskLandscapeLeft |
    UIInterfaceOrientationMaskLandscapeRight |
    UIInterfaceOrientationMaskPortrait |
    UIInterfaceOrientationMaskPortraitUpsideDown;
}

-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    NSLog(@"rotating!");
    if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
        NSLog(@"lefty!");
        self->lView.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [self presentModalViewController:self->lView animated:YES];
    }
}


@end
