//
//  PODCalibrateViewController.m
//  Poppy
//
//  Created by Dominik Wagner on 13.02.14.
//  Copyright (c) 2014 Hack Things LLC. All rights reserved.
//

#import "PODCalibrateViewController.h"
#import <GLKit/GLKit.h>
#import <CoreImage/CoreImage.h>
#import "RBVolumeButtons.h"
#import "PODFilterFactory.h"
#import "PODDeviceSettingsManager.h"
#import "PODAssetsManager.h"
#import "PODRecordViewController.h"
#import "WelcomeViewController.h"
#import "AppDelegate.h"

typedef NS_ENUM(NSInteger, PODCalibrateDisplayMode) {
	kPODCalibrateDisplayModeRaw,
	kPODCalibrateDisplayModeResult
};

@interface PODCalibrateViewController ()
@property (weak, nonatomic) IBOutlet UIButton *homeButton;
@property (nonatomic, strong) GLKView *GLKView;
@property (nonatomic, strong) CIContext *CIContext;
@property (nonatomic, strong) EAGLContext *EAGLContext;
@property (nonatomic, strong) CIImage *sourceImage;
@property (nonatomic) PODCalibrateDisplayMode displayMode;
@property (nonatomic) CGPoint centerOffsetStartValue;
@property (nonatomic) CGFloat rotationOffsetStartValue;
@property (nonatomic, strong) NSTimer *regularUpdateTimer;
@property (nonatomic, strong) UIView *viewWelcome;
@property (nonatomic, strong) UILabel *xOffsetLabel;
@property (nonatomic, strong) UIImageView *horizontalImageView;
@property (nonatomic) BOOL showVertical;
@property (nonatomic, strong) UIImageView *leftImgView;
@property (nonatomic) CGPoint offsetStartPoint;
@property (nonatomic) float xOffset;
@property (nonatomic) float yOffset;
@property (nonatomic) CGPoint tempOffset;
@end

@implementation PODCalibrateViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.needsImage = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidAppear:(BOOL)animated
{
    AppDelegate *poppyAppDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [poppyAppDelegate makeScreenBrightnessNormal];
    if (self.showOOBE) {
        WelcomeViewController *wvc = [[WelcomeViewController alloc] initWithNibName:@"LiveView" bundle:nil];
        [self presentViewController:wvc animated:NO completion:nil];
    } else if (self.needsImage) {
        // Launch the image capture phase of calibration
        self.needsImage = NO;
        [PODDeviceSettingsManager deviceSettingsManager].rotationOffsetInDegrees = 0.0;
        PODRecordViewController *vc = [[PODRecordViewController alloc] initWithNibName:nil bundle:nil];
        vc.forCalibration = YES;
        [self presentViewController:vc animated:NO completion:NULL];
    } else {
        self.showVertical = NO;
        [self showCalibrationAlert];
        self.EAGLContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        GLKView *glkitView = [[GLKView alloc] initWithFrame:self.view.bounds context:self.EAGLContext];
        UIView *view = self.view;
        [view insertSubview:glkitView atIndex:0];
        view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        glkitView.userInteractionEnabled = NO;
        self.CIContext = [CIContext contextWithEAGLContext:self.EAGLContext];
        self.GLKView = glkitView;
        
        self.horizontalImageView = [[UIImageView alloc] initWithFrame:CGRectMake(-[PODDeviceSettingsManager deviceSettingsManager].calibrationCenterOffset.x*1024, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
        [self.horizontalImageView setContentMode:UIViewContentModeScaleAspectFill];
        [self.horizontalImageView setClipsToBounds:YES];
        [self.horizontalImageView setBackgroundColor:[UIColor redColor]];

        [self.view insertSubview:self.horizontalImageView atIndex:1];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *filePath = [defaults objectForKey:@"calibrationImagePath"];
        self.horizontalImageView.contentMode = UIViewContentModeScaleAspectFill;
        [self.horizontalImageView setImage:[UIImage imageWithContentsOfFile:filePath]];
    }
}

-(void) showCalibrationAlert {
    self.viewWelcome = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    [self.viewWelcome setAutoresizingMask: UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin];
    
    UIView *viewShadow = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.viewWelcome.frame.size.width, self.viewWelcome.frame.size.height)];
    [viewShadow setBackgroundColor:[UIColor blackColor]];
    [viewShadow setAlpha:1.0];
    
    NSString *labelText = @"Now remove your iPhone\nfrom Poppy";
    
    UILabel *labelWelcomeL = [[UILabel alloc] initWithFrame:CGRectMake(0,0,self.viewWelcome.bounds.size.width/2, self.viewWelcome.bounds.size.height - 70)];
    [labelWelcomeL setTextColor:[UIColor whiteColor]];
    [labelWelcomeL setBackgroundColor:[UIColor clearColor]];
    [labelWelcomeL setTextAlignment:NSTextAlignmentCenter];
    labelWelcomeL.lineBreakMode = NSLineBreakByWordWrapping;
    labelWelcomeL.numberOfLines = 0;
    [labelWelcomeL setText:labelText];
    
    UILabel *labelWelcomeR = [[UILabel alloc] initWithFrame:CGRectMake(self.viewWelcome.bounds.size.width/2,0,self.viewWelcome.bounds.size.width/2, self.viewWelcome.frame.size.height - 70)];
    [labelWelcomeR setTextColor:[UIColor whiteColor]];
    [labelWelcomeR setBackgroundColor:[UIColor clearColor]];
    [labelWelcomeR setTextAlignment:NSTextAlignmentCenter];
    labelWelcomeR.lineBreakMode = NSLineBreakByWordWrapping;
    labelWelcomeR.numberOfLines = 0;
    [labelWelcomeR setText:labelText];
    
    
    UIButton *buttonL = [[UIButton alloc] initWithFrame:CGRectMake(0,self.viewWelcome.bounds.size.height - 70,self.viewWelcome.bounds.size.width/2,50)];
    [buttonL setTitle:@"OK" forState:UIControlStateNormal];
    [buttonL setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [buttonL addTarget:self action:@selector(hideInstructions) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *buttonR = [[UIButton alloc] initWithFrame:CGRectMake(self.viewWelcome.bounds.size.width/2,self.viewWelcome.bounds.size.height - 70,self.viewWelcome.bounds.size.width/2,50)];
    [buttonR setTitle:@"OK" forState:UIControlStateNormal];
    [buttonR setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [buttonR addTarget:self action:@selector(hideInstructions) forControlEvents:UIControlEventTouchUpInside];
    
    [self.viewWelcome addSubview:viewShadow];
    [self.viewWelcome addSubview:labelWelcomeL];
    [self.viewWelcome addSubview:labelWelcomeR];
    [self.viewWelcome addSubview:buttonL];
    [self.viewWelcome addSubview:buttonR];
    
    [self.view addSubview:self.viewWelcome];
    
}

- (void) hideInstructions
{
    [self.homeButton setHidden:NO];
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panAction:)];
    [self.view addGestureRecognizer:panGestureRecognizer];
    
    [self.viewWelcome setHidden:YES];
    
    UIView *viewShadow = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.viewWelcome.bounds.size.width, 60)];
    [viewShadow setBackgroundColor:[UIColor blackColor]];
    [viewShadow setAlpha:0.6];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0,0,self.viewWelcome.bounds.size.width, 60)];
    [label setTextColor:[UIColor whiteColor]];
    [label setTextAlignment:NSTextAlignmentCenter];
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.numberOfLines = 0;
    [label setText:@"Drag to center the red line between the two images"]; //Drag the image left or right until centered
    
    UIView *separatorView = [[UIView alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - 4)/2,0, 4, self.view.bounds.size.height)];
    [separatorView setBackgroundColor:[UIColor redColor]];
    [self.view insertSubview:separatorView atIndex:1000];
    
    self.xOffsetLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, self.view.bounds.size.height - 65, 80, 45)];
    [self.xOffsetLabel setTextColor:[UIColor whiteColor]];
    [self.xOffsetLabel setBackgroundColor:[UIColor blackColor]];
    [self.xOffsetLabel setAlpha:0.8];
    [self.xOffsetLabel setTextAlignment:NSTextAlignmentCenter];
    [self.view insertSubview:self.xOffsetLabel atIndex:1001];
    [self.xOffsetLabel setText:[NSString stringWithFormat:@"%02.1f",([PODDeviceSettingsManager deviceSettingsManager].calibrationCenterOffset.x)*1000]];
    
    [self.view addSubview:viewShadow];
    [self.view addSubview:label];
}

- (void)loadSourceImage {
    
    // use image from file
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *filePath = [defaults objectForKey:@"calibrationImagePath"];
    CIImage *sourceImage = [CIImage imageWithContentsOfURL:[NSURL fileURLWithPath:filePath]];
    self.sourceImage = sourceImage;
    [self updateFilterDisplay];
    [NSOperationQueue TCM_performBlockOnMainQueue:^{
        [self updateFilterDisplay]; // show the raw image with the debug overlay
    } afterDelay:0.5]; // delay a little so it actually happens

}

- (void)updateFilterDisplay {
	PODFilterChainSettings *filterChainSettings = [[PODDeviceSettingsManager deviceSettingsManager] deviceSettingsForMode:kPODDeviceSettingsModePhoto].filterChainSettings;
	NSArray *filterChain = [PODFilterFactory filterChainWithSettings:filterChainSettings
														  inputImage:self.sourceImage];
	
	[filterChain.firstObject setValue:self.sourceImage forKey:@"inputImage"];
	
	//CIImage *outputImage = self.sourceImage;
	
    NSMutableArray *stereoImages = [self splitImage:[filterChain.lastObject outputImage]];
    
    // set up the left and right images
    
    UIImage *rightImg = (UIImage *)stereoImages[0];
    UIImage *leftImg = (UIImage *)stereoImages[1];
    
    UIImageView *rightImgView = [[UIImageView alloc] initWithImage:rightImg];
    CGRect rightFrame = self.view.bounds;
    rightFrame.origin.x = rightFrame.origin.x + 50;
    [rightImgView setFrame:self.view.bounds];
    [rightImgView setContentMode:UIViewContentModeScaleAspectFill];
    
    self.leftImgView = [[UIImageView alloc] initWithImage:leftImg];
    [self.leftImgView setAlpha:0.5];
    CGRect leftFrame = self.view.bounds;
    leftFrame.origin.x = leftFrame.origin.x - 50;
    [self.leftImgView setFrame:leftFrame];
    [self.leftImgView setContentMode:UIViewContentModeScaleAspectFill];
    [self.view addSubview:rightImgView];
    [self.view addSubview:self.leftImgView];
    [self.view bringSubviewToFront:self.homeButton];
    [self.view bringSubviewToFront:self.xOffsetLabel];
    
    UIView *viewShadow = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.viewWelcome.bounds.size.width, 60)];
    [viewShadow setBackgroundColor:[UIColor blackColor]];
    [viewShadow setAlpha:0.6];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0,0,self.viewWelcome.bounds.size.width, 60)];
    [label setTextColor:[UIColor whiteColor]];
    [label setTextAlignment:NSTextAlignmentCenter];
    [label setText:@"Now drag the image until the main subject overlaps"];
    
    [self.view addSubview:viewShadow];
    [self.view addSubview:label];
}

-(NSMutableArray *)splitImage:(CIImage *)ciImage
{
    NSMutableArray *array = [[NSMutableArray alloc] init];

    UIImage *image;
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef processedCGImage = [context createCGImage:ciImage
                                                       fromRect:[ciImage extent]];
    
    image = [UIImage imageWithCGImage:processedCGImage];
    CGImageRelease(processedCGImage);
    
    CGRect leftCrop = CGRectMake(0, 0, image.size.width/2, image.size.height);
    CGImageRef leftImageRef = CGImageCreateWithImageInRect([image CGImage], leftCrop);
    UIImage *leftImg = [UIImage imageWithCGImage:leftImageRef];
    CGImageRelease(leftImageRef);
    CGRect rightCrop = CGRectMake(image.size.width/2, 0, image.size.width/2, image.size.height);
    CGImageRef rightImageRef = CGImageCreateWithImageInRect([image CGImage], rightCrop);
    UIImage *rightImg = [UIImage imageWithCGImage:rightImageRef];
    CGImageRelease(rightImageRef);
    
    [array addObject:rightImg];
    [array addObject:leftImg];
    
    return array;
}

+ (void)strokePath:(UIBezierPath *)aPath width:(CGFloat)aLineWidth color:(UIColor *)aColor {
	aPath.lineWidth = aLineWidth;
	[aColor set];
	[aPath stroke];
}

- (CIImage *)CIImageByDrawingOverImage:(CIImage *)aCIImage withDrawingBlock:(void(^)(CGRect bounds))aDrawingBlock {
	CGRect bounds = CGRectZero;
	bounds.size = aCIImage.extent.size;
	CGImageRef cgImage = [self.CIContext createCGImage:aCIImage fromRect:aCIImage.extent];
	UIGraphicsBeginImageContextWithOptions(bounds.size, YES, 1.0);
	{
		UIImage *uiImage = [UIImage imageWithCGImage:cgImage scale:1.0 orientation:UIImageOrientationUp];
		[uiImage drawAtPoint:CGPointZero];
	}
	CFRelease(cgImage);
	
	aDrawingBlock(bounds);
	
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	CIImage *ciImage = [[CIImage alloc] initWithCGImage:[image CGImage]];
	return ciImage;
}

- (CIImage *)drawGridOverlaysForImage:(CIImage *)aCIImage {
	CIImage *result = [self CIImageByDrawingOverImage:aCIImage withDrawingBlock:^(CGRect bounds) {
		UIBezierPath *gridline = [UIBezierPath bezierPath];
		UIColor *gridColor = [UIColor colorWithWhite:0.507 alpha:0.500];
		[gridline moveToPoint:CGPointMake(0, -4400)];
		[gridline addLineToPoint:CGPointMake(0, 4400)];
		
		CGContextRef ctx = UIGraphicsGetCurrentContext();
		CGContextSaveGState(ctx);
		CGContextTranslateCTM(ctx, CGRectGetWidth(bounds) / 2., CGRectGetHeight(bounds)/2.0);
		[self.class strokePath:gridline width:5.0 color:gridColor];
		CGFloat stepX = CGRectGetWidth(bounds) / 8.;
		for (CGFloat translationX = stepX; translationX < CGRectGetWidth(bounds) / 2 ;translationX+=stepX) {
			CGContextSaveGState(ctx);
			CGContextTranslateCTM(ctx, translationX, 0);
			[self.class strokePath:gridline width:5.0 color:gridColor];
			CGContextTranslateCTM(ctx, -2 * translationX, 0);
			[self.class strokePath:gridline width:5.0 color:gridColor];
			CGContextRestoreGState(ctx);
		}

		[gridline applyTransform:CGAffineTransformMakeRotation(M_PI_2)];
		
		[self.class strokePath:gridline width:5.0 color:gridColor];
		CGFloat stepY = CGRectGetHeight(bounds) / 8.;
		for (CGFloat translationY = stepY; translationY < CGRectGetHeight(bounds) / 2 ;translationY+=stepY) {
			CGContextSaveGState(ctx);
			CGContextTranslateCTM(ctx, 0, translationY);
			[self.class strokePath:gridline width:5.0 color:gridColor];
			CGContextTranslateCTM(ctx, 0, -2 * translationY);
			[self.class strokePath:gridline width:5.0 color:gridColor];
			CGContextRestoreGState(ctx);
		}
		
		CGContextRestoreGState(ctx);
		
	}];
	return result;
}

- (CIImage *)drawOverlaysForSettings:(PODFilterChainSettings *)aFilterChainSettings image:(CIImage *)aCIImage {
	CIImage *result = [self CIImageByDrawingOverImage:aCIImage withDrawingBlock:^(CGRect bounds) {
		CGRect leftRect = [aFilterChainSettings leftCropRectForImageExtent:bounds];
		[self.class strokePath:[UIBezierPath bezierPathWithRect:leftRect] width:3.0 color:[UIColor colorWithRed:1.000 green:0.312 blue:0.245 alpha:1.000]];
		CGRect rightRect = [aFilterChainSettings rightCropRectForImageExtent:bounds];
		[self.class strokePath:[UIBezierPath bezierPathWithRect:rightRect] width:3.0 color:[UIColor greenColor]];
		
		CGPoint centerPoint = [PODFilterChainSettings absolutePointForNormalizedPoint:aFilterChainSettings.calibratedCenter imageExtent:bounds];
		UIBezierPath *centerCross = [UIBezierPath bezierPath];
		CGFloat distance = 50.0;
		[centerCross moveToPoint:TCMPointOffset(centerPoint, -distance, 0)];
		[centerCross addLineToPoint:TCMPointOffset(centerPoint, distance, 0)];
		[centerCross moveToPoint:TCMPointOffset(centerPoint, 0, -distance)];
		[centerCross addLineToPoint:TCMPointOffset(centerPoint, 0, distance)];
		[self.class strokePath:centerCross width:6.0 color:[UIColor colorWithRed:1.000 green:0.473 blue:0.801 alpha:1.000]];
		
		UIBezierPath *rotationLine = [UIBezierPath bezierPath];
		[rotationLine moveToPoint:CGPointMake(0, -4400)];
		[rotationLine addLineToPoint:CGPointMake(0, 4400)];
		[rotationLine applyTransform:CGAffineTransformConcat(CGAffineTransformMakeRotation(TCMRadiansFromDegrees(-aFilterChainSettings.calibratedRotation)), CGAffineTransformMakeTranslation(centerPoint.x, centerPoint.y))];
		[self.class strokePath:rotationLine width:5.0 color:[UIColor blackColor]];
	}];
	return result;
}

- (void)panAction:(UIPanGestureRecognizer *)aPanGestureRecognizer {
	//	NSLog(@"%s %@",__FUNCTION__,aPanGestureRecognizer);
	CGPoint translationOffset = [aPanGestureRecognizer translationInView:self.view];
	if (aPanGestureRecognizer.state == UIGestureRecognizerStateBegan) {
		if (self.showVertical) {
            if (!self.rotationOffsetStartValue) {
                self.rotationOffsetStartValue = [[PODDeviceSettingsManager deviceSettingsManager] rotationOffsetInDegrees];
            }
        } else {
            self.centerOffsetStartValue = [[PODDeviceSettingsManager deviceSettingsManager] calibrationCenterOffset];
        }
	} else if (aPanGestureRecognizer.state == UIGestureRecognizerStateChanged) {
        if (self.showVertical) {
            
            // wiggle like UI
            self.xOffset = self.tempOffset.x + ([aPanGestureRecognizer translationInView:self.view].x)/10;
            self.yOffset = self.tempOffset.y + ([aPanGestureRecognizer translationInView:self.view].y)/10;
            
            CGRect newFrame = self.leftImgView.frame;
            newFrame.origin.x = self.xOffset - 50; //this 50 is to offset for 6 foot distance
            newFrame.origin.y = self.yOffset;
            [self.leftImgView setFrame:newFrame];
            
            [self.xOffsetLabel setText:[NSString stringWithFormat:@"%02.1f", (self.rotationOffsetStartValue + atan(self.yOffset/self.view.bounds.size.width/2)*180/M_PI)*100]];
            
        } else {
            CGFloat xChangeValue = copysign(MAX(0.0,ABS(translationOffset.x)), translationOffset.x)/10;
            CGRect newFrame = CGRectMake(-(self.centerOffsetStartValue.x - xChangeValue / 1024.)*1024, 0, self.horizontalImageView.bounds.size.width, self.horizontalImageView.bounds.size.height);
            [self.horizontalImageView setFrame:newFrame];
            [self.xOffsetLabel setText:[NSString stringWithFormat:@"%02.1f", (self.centerOffsetStartValue.x - xChangeValue / 1024.)*1000]];
        }
	}
	if (aPanGestureRecognizer.state == UIGestureRecognizerStateEnded ||
		aPanGestureRecognizer.state == UIGestureRecognizerStateFailed) {
        if (self.showVertical) {
            self.tempOffset = CGPointMake(self.xOffset, self.yOffset);
            float degreesChanged = self.rotationOffsetStartValue + atan(self.yOffset/self.view.bounds.size.width/2)*180/M_PI;
            [PODDeviceSettingsManager deviceSettingsManager].rotationOffsetInDegrees = degreesChanged;
            [self.xOffsetLabel setText:[NSString stringWithFormat:@"%02.1f", degreesChanged*100]];
        } else {
            CGFloat xChangeValue = copysign(MAX(0.0,ABS(translationOffset.x)), translationOffset.x)/10;
            [PODDeviceSettingsManager deviceSettingsManager].calibrationCenterOffset = CGPointMake(self.centerOffsetStartValue.x - xChangeValue / 1024., 0);
            [self.xOffsetLabel setText:[NSString stringWithFormat:@"%02.1f", (self.centerOffsetStartValue.x - xChangeValue / 1024.)*1000]];
        }
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSUInteger)supportedInterfaceOrientations {
	return UIInterfaceOrientationMaskLandscapeLeft;
}

- (BOOL)prefersStatusBarHidden {
	return YES;
}


- (IBAction)homeButtonAction:(id)sender {
    if (self.showVertical) {
        [self showCalibrationComplete];
    } else {
        [self.xOffsetLabel setText:[NSString stringWithFormat:@"%02.1f", ([[PODDeviceSettingsManager deviceSettingsManager] rotationOffsetInDegrees])*100]];
        [self.homeButton setTitle:@"Next" forState:UIControlStateNormal];
        self.showVertical = YES;
        self.horizontalImageView.hidden = YES;
        [self loadSourceImage];
    }
}
    
-(void)showCalibrationComplete {
    UIView *viewShadow = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.view.bounds.size.width, self.view.bounds.size.height)];
    [viewShadow setBackgroundColor:[UIColor blackColor]];
    [viewShadow setAlpha:1.0];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0,0,self.view.bounds.size.width, self.view.bounds.size.height - 70)];
    [label setTextColor:[UIColor whiteColor]];
    [label setTextAlignment:NSTextAlignmentCenter];
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.numberOfLines = 0;
    [label setText:@"Congratulations, you are done calibrating.\nPut your iPhone back in Poppy and enjoy."];
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0,self.viewWelcome.bounds.size.height - 70,self.viewWelcome.bounds.size.width,50)];
    [button setTitle:@"OK" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(dismissAction) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:viewShadow];
    [self.view addSubview:label];
    [self.view addSubview:button];
}
    
-(void)dismissAction {
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self dismissViewControllerAnimated:NO completion:NULL];
}

@end
