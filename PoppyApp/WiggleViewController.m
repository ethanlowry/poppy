//
//  WiggleViewController.m
//  wiggle_test
//
//  Created by Ethan Lowry on 2/3/14.
//  Copyright (c) 2014 Ethan Lowry. All rights reserved.
//

#import "WiggleViewController.h"
#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "UIImage+Resize.h"
#import "AppDelegate.h"

@interface WiggleViewController ()
@property (nonatomic, strong) UIImageView *leftImgView;
@property (nonatomic, strong) UIImageView *rightImgView;
@property (nonatomic, strong) UIImageView *animatedView;
@property (nonatomic, strong) UIView *maskViewX;
@property (nonatomic, strong) UIView *maskViewY;
@property (nonatomic) CGPoint offsetStartValue;
@property (nonatomic) float xOffset;
@property (nonatomic) float yOffset;
@property (nonatomic) CGPoint tempOffset;
@property (nonatomic) BOOL stopFade;
@property (nonatomic) BOOL isAnimating;
@property (nonatomic, strong) NSString *wiggleURL;

@end

@implementation WiggleViewController

NSURL *fileURL;
UIImage *leftImg;
UIImage *rightImg;
float offset = 0.0;
UIView *gifView;


-(void) makeAnimatedGifWithLeft: (UIImage *)imageL withRight: (UIImage *)imageR
{
    static NSUInteger const kFrameCount = 2;
    
    NSDictionary *fileProperties = @{
                                     (__bridge id)kCGImagePropertyGIFDictionary: @{
                                             (__bridge id)kCGImagePropertyGIFLoopCount: @0, // 0 means loop forever
                                             }
                                     };
    NSDictionary *frameProperties = @{
                                      (__bridge id)kCGImagePropertyGIFDictionary: @{
                                              (__bridge id)kCGImagePropertyGIFDelayTime: @.3f, // a float (not double!) in seconds, rounded to centiseconds in the GIF data
                                              }
                                      };
    
    NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
    fileURL = [documentsDirectoryURL URLByAppendingPathComponent:@"animated.gif"];
    
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL((__bridge CFURLRef)fileURL, kUTTypeGIF, kFrameCount, NULL);
    CGImageDestinationSetProperties(destination, (__bridge CFDictionaryRef)fileProperties);
    
    @autoreleasepool {
        CGImageDestinationAddImage(destination, imageL.CGImage, (__bridge CFDictionaryRef)frameProperties);
    }
    @autoreleasepool {
        CGImageDestinationAddImage(destination, imageR.CGImage, (__bridge CFDictionaryRef)frameProperties);
    }
    
    if (!CGImageDestinationFinalize(destination)) {
        NSLog(@"failed to finalize image destination");
    }
    CFRelease(destination);
    
    //NSLog(@"url=%@", fileURL);
}



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
    [self getValuesFromDefaults];
	// Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated
{
    AppDelegate *poppyAppDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [poppyAppDelegate makeScreenBrightnessNormal];
    
    if(self.stereoImage && !self.leftImgView) {
        self.stereoImage = [self.stereoImage resizedImageWithContentMode:UIViewContentModeScaleAspectFit bounds:CGSizeMake(1704, 1278) interpolationQuality:1.0];
        
        [self splitImage:self.stereoImage];
        
        // set up the left and right images
        self.rightImgView = [[UIImageView alloc] initWithImage:rightImg];
        [self.rightImgView setFrame:self.view.frame];
        [self.rightImgView setContentMode:UIViewContentModeScaleAspectFill];
        self.leftImgView = [[UIImageView alloc] initWithImage:leftImg];
        [self.leftImgView setFrame:self.view.frame];
        [self.leftImgView setContentMode:UIViewContentModeScaleAspectFill];
        [self.view addSubview:self.rightImgView];
        [self.view addSubview:self.leftImgView];
        
        
        // mask out the parts of the background image that are cropped out of the foreground image
        self.maskViewX = [[UIView alloc] initWithFrame:CGRectMake(-self.view.frame.size.width, 0, self.view.frame.size.width, self.view.frame.size.height)];
        [self.maskViewX setBackgroundColor:[UIColor blackColor]];
        [self.view addSubview:self.maskViewX];
        
        self.maskViewY = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height)];
        [self.maskViewY setBackgroundColor:[UIColor blackColor]];
        [self.view addSubview:self.maskViewY];
        
        // fake the appearance of an animated gif
        [self fadeInLeft];
        
        // add the slider
        /*
        CGRect frame = CGRectMake(60.0, 50.0, 200.0, 10.0);
        UISlider *slider = [[UISlider alloc] initWithFrame:frame];
        [slider addTarget:self action:@selector(sliderAction:) forControlEvents:UIControlEventValueChanged];
        [slider setBackgroundColor:[UIColor clearColor]];
        slider.minimumValue = -60.0;
        slider.maximumValue = 60.0;
        slider.continuous = YES;
        slider.value = 0.0;
        [self.view addSubview:slider];
         */
        
        // add the pan gesture
        UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panAction:)];
        [self.view addGestureRecognizer:panGestureRecognizer];
        
        //add instruction label
        CGRect labelFrame = CGRectMake(0, 0, self.view.bounds.size.width, 80);
        UIView *labelShadowView = [[UIView alloc] initWithFrame:labelFrame];
        [labelShadowView setBackgroundColor:[UIColor blackColor]];
        [labelShadowView setAlpha:0.3];
        UILabel *label = [[UILabel alloc] initWithFrame:labelFrame];
        [label setTextColor:[UIColor whiteColor]];
        [label setTextAlignment:NSTextAlignmentCenter];
        [label setText:@"Drag the image until you are happy"];
        [self.view addSubview:labelShadowView];
        [self.view addSubview:label];
        
        // add the save button
        CGRect saveButtonFrame = CGRectMake(40, self.view.frame.size.height - 70, 100, 50);
        UIView *saveShadowView = [[UIView alloc] initWithFrame:saveButtonFrame];
        [saveShadowView setBackgroundColor:[UIColor blackColor]];
        [saveShadowView setAlpha:0.3];
        UIButton *saveButton = [[UIButton alloc] initWithFrame:saveButtonFrame];
        [saveButton addTarget:self action:@selector(postGif) forControlEvents:UIControlEventTouchUpInside];
        [saveButton setTitle:@"Share" forState:UIControlStateNormal];
        [self.view addSubview:saveShadowView];
        [self.view addSubview:saveButton];
        
        // add the cancel button
        CGRect cancelButtonFrame = CGRectMake(180, self.view.frame.size.height - 70, 100, 50);
        UIView *cancelShadowView = [[UIView alloc] initWithFrame:cancelButtonFrame];
        [cancelShadowView setBackgroundColor:[UIColor blackColor]];
        [cancelShadowView setAlpha:0.3];
        UIButton *cancelButton = [[UIButton alloc] initWithFrame:cancelButtonFrame];
        [cancelButton addTarget:self action:@selector(dismissAction) forControlEvents:UIControlEventTouchUpInside];
        [cancelButton setTitle:@"Done" forState:UIControlStateNormal];
        [self.view addSubview:cancelShadowView];
        [self.view addSubview:cancelButton];
    }
    [self positionImage];
}

-(void)dismissAction
{
    [self dismissViewControllerAnimated:YES completion:^{}];
}

-(void)redoGif
{
    [gifView removeFromSuperview];
}

-(void)postGif
{
    
    if (self.wiggleURL) {
        [self showSharingLink:self.wiggleURL];
    } else {
        // Show the loading indicator and perform the POST
        CGRect labelFrame = CGRectMake(0, (self.view.bounds.size.height-80)/2, self.view.bounds.size.width, 80);
        UIView *labelShadowView = [[UIView alloc] initWithFrame:labelFrame];
        [labelShadowView setBackgroundColor:[UIColor blackColor]];
        [labelShadowView setAlpha:0.8];
        UILabel *label = [[UILabel alloc] initWithFrame:labelFrame];
        [label setTextColor:[UIColor whiteColor]];
        [label setTextAlignment:NSTextAlignmentCenter];
        [label setFont:[UIFont boldSystemFontOfSize:18.0]];
        label.lineBreakMode = NSLineBreakByWordWrapping;
        label.numberOfLines = 0;
        [label setText:@"Uploading..."];
        [self.view addSubview:labelShadowView];
        [self.view addSubview:label];
        
        //UIImage *image = [UIImage imageNamed:@"image.jpg"];
        NSData *imageData = UIImageJPEGRepresentation(self.stereoImage, 0.8);
        //NSLog(@"DATA: %d", imageData.length);
        
        NSURL *url = [NSURL URLWithString:@"http://poppy3d.com/app/upload_wiggle"];
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                               cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                           timeoutInterval:10.0];
        
        [request setHTTPMethod:@"POST"];
        NSString *boundary = @"IaTjHpHp";
        NSString *kNewLine = @"\r\n";
        
        // Note that setValue is used so as to override any existing Content-Type header.
        // addValue appends to the Content-Type header
        NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
        [request setValue:contentType forHTTPHeaderField: @"Content-Type"];
        
        NSMutableData *body = [NSMutableData data];
        
        // UUID
        [body appendData:[[NSString stringWithFormat:@"--%@%@", boundary, kNewLine] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"", @"uuid"] dataUsingEncoding:NSUTF8StringEncoding]];
        // For simple data types, such as text or numbers, there's no need to set the content type
        [body appendData:[[NSString stringWithFormat:@"%@%@", kNewLine, kNewLine] dataUsingEncoding:NSUTF8StringEncoding]];
        NSString *UUID = [UIDevice currentDevice].identifierForVendor.UUIDString;
        [body appendData:[UUID dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[kNewLine dataUsingEncoding:NSUTF8StringEncoding]];
        
        // Wiggle offset
        [body appendData:[[NSString stringWithFormat:@"--%@%@", boundary, kNewLine] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"", @"wiggle_offset"] dataUsingEncoding:NSUTF8StringEncoding]];
        // For simple data types, such as text or numbers, there's no need to set the content type
        [body appendData:[[NSString stringWithFormat:@"%@%@", kNewLine, kNewLine] dataUsingEncoding:NSUTF8StringEncoding]];
        NSString *wiggleOffset = [NSString stringWithFormat:@"%.3f", self.xOffset * 100/self.view.bounds.size.width];
        [body appendData:[wiggleOffset dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[kNewLine dataUsingEncoding:NSUTF8StringEncoding]];
        
        // Wiggle-Y offset
        [body appendData:[[NSString stringWithFormat:@"--%@%@", boundary, kNewLine] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"", @"wiggle_offset_y"] dataUsingEncoding:NSUTF8StringEncoding]];
        // For simple data types, such as text or numbers, there's no need to set the content type
        [body appendData:[[NSString stringWithFormat:@"%@%@", kNewLine, kNewLine] dataUsingEncoding:NSUTF8StringEncoding]];
        NSString *wiggleYOffset = [NSString stringWithFormat:@"%.3f", self.yOffset * 100/self.view.bounds.size.height];
        [body appendData:[wiggleYOffset dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[kNewLine dataUsingEncoding:NSUTF8StringEncoding]];
        
        // Add the image to the request body
        [body appendData:[[NSString stringWithFormat:@"--%@%@", boundary, kNewLine] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"image.jpg\"%@", @"content[file]", kNewLine] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Type: image/jpeg"] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"%@%@", kNewLine, kNewLine] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:imageData];
        [body appendData:[kNewLine dataUsingEncoding:NSUTF8StringEncoding]];
        
        // Add the terminating boundary marker to signal that we're at the end of the request body
        [body appendData:[[NSString stringWithFormat:@"--%@--", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        
        [request setHTTPBody:body];

        [NSURLConnection sendAsynchronousRequest:request
                                           queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                   if(error) {
                                       [label setFont:[UIFont systemFontOfSize:18.0]];
                                       [label setText:@"Uh oh, network trouble!\nTry again later."];
                                       int64_t delayInSeconds = 4.0;
                                       dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                                       dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                                           [label removeFromSuperview];
                                           [labelShadowView removeFromSuperview];
                                       });
                                   } else {
                                       NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
                                       self.wiggleURL = [dict objectForKey:@"page_url"];
                                       [self showSharingLink:self.wiggleURL];
                                       //[self saveToDefaults];
                                       // Hide the loading indicator
                                       [label removeFromSuperview];
                                       [labelShadowView removeFromSuperview];
                                   }
                               }
         ];
    }
    
}
    
-(void)saveToDefaults
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *wiggleDictionary = [[NSMutableDictionary alloc] init];
    if ([defaults dictionaryForKey:@"wiggleDictionary"]) {
        wiggleDictionary = [[defaults dictionaryForKey:@"wiggleDictionary"] mutableCopy];
    }
    NSDictionary *wiggleItem;
    if (self.wiggleURL) {
        wiggleItem = [[NSDictionary alloc] initWithObjectsAndKeys:self.wiggleURL, @"wiggleURL", [NSString stringWithFormat:@"%f", self.xOffset], @"xOffset", [NSString stringWithFormat:@"%f", self.yOffset], @"yOffset", nil];
    } else {
        wiggleItem = [[NSDictionary alloc] initWithObjectsAndKeys:[NSString stringWithFormat:@"%f", self.xOffset], @"xOffset", [NSString stringWithFormat:@"%f", self.yOffset], @"yOffset", nil];
    }
    [wiggleDictionary setObject:wiggleItem forKey:[self.assetURL absoluteString]];
    [defaults setObject:wiggleDictionary forKey:@"wiggleDictionary"];
    [defaults synchronize];
}
    
-(void)getValuesFromDefaults
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *wiggleDictionary = [defaults dictionaryForKey:@"wiggleDictionary"];
    NSDictionary *wiggleItem = [wiggleDictionary objectForKey:[self.assetURL absoluteString]];
    if (wiggleItem) {
        self.xOffset = [[wiggleItem objectForKey:@"xOffset"] floatValue];
        self.yOffset = [[wiggleItem objectForKey:@"yOffset"] floatValue];
        self.wiggleURL = [wiggleItem objectForKey:@"wiggleURL"];
    }
}

-(void)showSharingLink:(NSString *)urlString
{
    NSMutableArray *sharingItems = [NSMutableArray new];
    if (urlString) {
        [sharingItems addObject:[NSString stringWithFormat:@"Check out my Poppy GIF - %@ #poppy3d", urlString]];
    }
    
    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:sharingItems applicationActivities:nil];
    [self presentViewController:activityController animated:YES completion:nil];
}



-(void)splitImage:(UIImage *)image
{
    CGRect leftCrop = CGRectMake(0, 0, image.size.width/2, image.size.height);
    CGImageRef leftImageRef = CGImageCreateWithImageInRect([image CGImage], leftCrop);
    leftImg = [UIImage imageWithCGImage:leftImageRef];
    CGImageRelease(leftImageRef);
    CGRect rightCrop = CGRectMake(image.size.width/2, 0, image.size.width/2, image.size.height);
    CGImageRef rightImageRef = CGImageCreateWithImageInRect([image CGImage], rightCrop);
    rightImg = [UIImage imageWithCGImage:rightImageRef];
    CGImageRelease(rightImageRef);
}

/*
-(void)sliderAction:(id)sender
{
    
    UISlider *slider = (id)sender;
    offset = slider.value;
    CGRect newFrame = self.leftImgView.frame;
    newFrame.origin.x = offset;
    [self.leftImgView setFrame:newFrame];
    
    CGRect maskFrame = self.maskView.frame;
    if (offset > 0 ) {
        maskFrame.origin.x = offset - self.view.frame.size.width;
    } else {
        maskFrame.origin.x = self.view.frame.size.width + offset;
    }
    [self.maskView setFrame:maskFrame];
}
 */

- (void)panAction:(UIPanGestureRecognizer *)aPanGestureRecognizer {
	//	NSLog(@"%s %@",__FUNCTION__,aPanGestureRecognizer);
    self.wiggleURL = nil;
	CGPoint translationOffset = [aPanGestureRecognizer translationInView:self.view];
	if (aPanGestureRecognizer.state == UIGestureRecognizerStateBegan) {
        self.tempOffset = CGPointMake(self.xOffset, self.yOffset);
        self.stopFade = YES;
        self.offsetStartValue = translationOffset;
	} else if (aPanGestureRecognizer.state == UIGestureRecognizerStateChanged) {
        self.xOffset = self.tempOffset.x + ([aPanGestureRecognizer translationInView:self.view].x - self.offsetStartValue.x)/10;
        self.yOffset = self.tempOffset.y + ([aPanGestureRecognizer translationInView:self.view].y - self.offsetStartValue.y)/10;
        
        [self positionImage];
        
        /*
		CGFloat xMinDistance = 30.;
		CGFloat xChangeValue = copysign(MAX(0.0,ABS(translationOffset.x) - xMinDistance), translationOffset.x);
		[PODDeviceSettingsManager deviceSettingsManager].calibrationCenterOffset = CGPointMake(self.offsetStartValue.x - xChangeValue / 1024., 0);
		
		CGFloat yMinDistance = 30.;
		CGFloat yChangeValue = copysign(MAX(0.0,ABS(translationOffset.y) - yMinDistance), translationOffset.y);
        
        CGPoint location = [aPanGestureRecognizer locationInView:self.view];
        if (location.x < self.view.frame.size.width / 2) {
            [PODDeviceSettingsManager deviceSettingsManager].rotationOffsetInDegrees = self.rotationOffsetStartValue + yChangeValue / 50.;
        } else {
            [PODDeviceSettingsManager deviceSettingsManager].rotationOffsetInDegrees = self.rotationOffsetStartValue - yChangeValue / 50.;
        }
         */
        
	}
    if (aPanGestureRecognizer.state == UIGestureRecognizerStateEnded) {
        self.stopFade = NO;
        if (!self.isAnimating) {
            [self fadeInLeft];
        }
        self.tempOffset = CGPointMake(self.xOffset, self.yOffset);
        [self saveToDefaults];
	}
}
    
-(void)positionImage
{
    CGRect newFrame = self.leftImgView.frame;
    newFrame.origin.x = self.xOffset;
    newFrame.origin.y = self.yOffset;
    [self.leftImgView setFrame:newFrame];
    
    CGRect maskFrameX = self.maskViewX.frame;
    if (self.xOffset > 0 ) {
        maskFrameX.origin.x = self.xOffset - self.view.frame.size.width;
    } else {
        maskFrameX.origin.x = self.view.frame.size.width + self.xOffset;
    }
    [self.maskViewX setFrame:maskFrameX];
    
    CGRect maskFrameY = self.maskViewY.frame;
    if (self.yOffset > 0 ) {
        maskFrameY.origin.y = self.yOffset - self.view.frame.size.height;
    } else {
        maskFrameY.origin.y = self.view.frame.size.height + self.yOffset;
    }
    [self.maskViewY setFrame:maskFrameY];
}


-(void)fadeInLeft
{
    if (!self.stopFade){
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.isAnimating = YES;
            [self.leftImgView setAlpha:1.0];} completion:^(BOOL finished){
                self.isAnimating = NO;
                [self fadeInRight];
        }];
    } else {
        [self.leftImgView setAlpha:0.5];
    }
}

-(void)fadeInRight
{
    if (!self.stopFade){
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.isAnimating = YES;
            [self.leftImgView setAlpha:0.0]; } completion:^(BOOL finished){
            self.isAnimating = NO;
            [self fadeInLeft];
        }];
    } else {
        [self.leftImgView setAlpha:0.5];
    }
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
