//
//  PODCalibrateViewController.m
//  Poppy Dome
//
//  Created by Dominik Wagner on 13.02.14.
//  Copyright (c) 2014 Dominik Wagner. All rights reserved.
//

#import "PODCalibrateViewController.h"
#import <GLKit/GLKit.h>
#import <CoreImage/CoreImage.h>
#import "RBVolumeButtons.h"
#import "PODFilterFactory.h"
#import "PODDeviceSettingsManager.h"
#import "PODAppDelegate.h"
#import "PODAssetsManager.h"
#import "PODRecordViewController.h"

typedef NS_ENUM(NSInteger, PODCalibrateDisplayMode) {
	kPODCalibrateDisplayModeRaw,
	kPODCalibrateDisplayModeResult
};

@interface PODCalibrateViewController ()
@property (nonatomic, strong) GLKView *GLKView;
@property (nonatomic, strong) CIContext *CIContext;
@property (nonatomic, strong) EAGLContext *EAGLContext;
@property (nonatomic, strong) CIImage *sourceImage;
@property (nonatomic) PODCalibrateDisplayMode displayMode;
@property (nonatomic) CGPoint centerOffsetStartValue;
@property (nonatomic) CGFloat rotationOffsetStartValue;
@property (nonatomic, strong) NSTimer *regularUpdateTimer;
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
    if (self.needsImage) {
        // Launch the image capture phase of calibration
        self.needsImage = NO;
        PODRecordViewController *vc = [[PODRecordViewController alloc] initWithNibName:nil bundle:nil];
        vc.forCalibration = YES;
        [self presentViewController:vc animated:NO completion:NULL];
    } else {
        self.EAGLContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        GLKView *glkitView = [[GLKView alloc] initWithFrame:self.view.bounds context:self.EAGLContext];
        UIView *view = self.view;
        [view insertSubview:glkitView atIndex:0];
        view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        glkitView.userInteractionEnabled = NO;
        self.CIContext = [CIContext contextWithEAGLContext:self.EAGLContext];
        self.GLKView = glkitView;
        
        [self loadSourceImage];
        [self updateFilterDisplay];
        
        UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panAction:)];
        
        [self.view addGestureRecognizer:panGestureRecognizer];
    }
}



- (void)loadSourceImage {
	CIImage *sourceImage = [CIImage imageWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"TestImagesRaw5s/IMG_5462" withExtension:@"JPG"]];
	self.sourceImage = sourceImage;
    
    // use image from file
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *filePath = [defaults objectForKey:@"calibrationImagePath"];
    sourceImage = [CIImage imageWithContentsOfURL:[NSURL fileURLWithPath:filePath]];
    self.sourceImage = sourceImage;
    [NSOperationQueue TCM_performBlockOnMainQueue:^{
        [self updateFilterDisplay]; // show the raw image with the debug overlay
    } afterDelay:0.5]; // delay a little so it actually happens
    
    // use image from raw
    /*
	[[PODAssetsManager assetsManager] assetForLatestRawImageCompletion:^(ALAsset *foundAsset) {
		ALAssetRepresentation *rep = foundAsset.defaultRepresentation;
		CGImageRef ref = rep.fullResolutionImage;
		CIImage *sourceImage = [[CIImage alloc] initWithCGImage:ref];

		if (rep.orientation != ALAssetOrientationUp) {
			// rotate the image
			CGFloat rotation = rep.orientation == ALAssetOrientationDown ?
			TCMRadiansFromDegrees(180) :
			rep.orientation == ALAssetOrientationLeft ?
			TCMRadiansFromDegrees(90) : TCMRadiansFromDegrees(270);
			CGAffineTransform transform = CGAffineTransformMakeRotation(rotation);
			CIImage *result = [CIFilter filterWithName:@"CIAffineTransform" keysAndValues:kCIInputImageKey, sourceImage, kCIInputTransformKey, [NSValue valueWithCGAffineTransform:transform],nil].outputImage;
			sourceImage = result;
		}
		
		self.sourceImage = sourceImage;
		[NSOperationQueue TCM_performBlockOnMainQueue:^{
			[self updateFilterDisplay]; // show the raw image with the debug overlay
		} afterDelay:0.5]; // delay a little so it actually happens
	}];
     */
}

- (void)displayCIImage:(CIImage *)aCIImage {
	[EAGLContext setCurrentContext:self.EAGLContext];
	glClearColor(0.0, 0.0, 0.0, 0.0);
	glClear(GL_COLOR_BUFFER_BIT);
	CGRect sourceRect = aCIImage.extent;
	CGRect targetRect = self.GLKView.bounds;
	CGFloat scaleFactor = [self.GLKView contentScaleFactor];
	targetRect = CGRectApplyAffineTransform(targetRect, CGAffineTransformMakeScale(scaleFactor, scaleFactor));
	CGFloat desiredWidth = CGRectGetHeight(targetRect) / CGRectGetHeight(sourceRect) * CGRectGetWidth(sourceRect);
    CGFloat desiredHeight = CGRectGetWidth(targetRect) / CGRectGetWidth(sourceRect) * CGRectGetHeight(sourceRect);
    
	//targetRect = CGRectInset(targetRect,(desiredWidth - CGRectGetWidth(targetRect)) / -2.0,0);
    targetRect = CGRectInset(targetRect,0,(desiredHeight - CGRectGetHeight(targetRect)) / -2.0);
	[self.CIContext drawImage:aCIImage inRect:targetRect fromRect:sourceRect];
	[self.GLKView setNeedsDisplay];
}

- (void)updateFilterDisplay {
	PODFilterChainSettings *filterChainSettings = [[PODDeviceSettingsManager deviceSettingsManager] deviceSettingsForMode:kPODDeviceSettingsModePhoto].filterChainSettings;
	NSArray *filterChain = [PODFilterFactory filterChainWithSettings:filterChainSettings
														  inputImage:self.sourceImage];
	
	[filterChain.firstObject setValue:self.sourceImage forKey:@"inputImage"];
	
	CIImage *outputImage = self.sourceImage;
	
    outputImage = [self drawGridOverlaysForImage:[filterChain.lastObject outputImage]];

	/*
    if (self.displayMode > kPODCalibrateDisplayModeRaw) {
		outputImage = [self drawGridOverlaysForImage:[filterChain.lastObject outputImage]];
	} else {
		outputImage = [self drawOverlaysForSettings:filterChainSettings image:outputImage];
	}
    */
	[self displayCIImage:outputImage];
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

- (void)startRegularUpdates {
	[self.regularUpdateTimer invalidate];
	self.regularUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(updateFilterDisplay) userInfo:nil repeats:YES];
}

- (void)stopRegularUpdates {
	[self.regularUpdateTimer invalidate];
	self.regularUpdateTimer = nil;
}

- (void)panAction:(UIPanGestureRecognizer *)aPanGestureRecognizer {
	//	NSLog(@"%s %@",__FUNCTION__,aPanGestureRecognizer);
	CGPoint translationOffset = [aPanGestureRecognizer translationInView:self.view];
	if (aPanGestureRecognizer.state == UIGestureRecognizerStateBegan) {
		self.centerOffsetStartValue = [[PODDeviceSettingsManager deviceSettingsManager] calibrationCenterOffset];
		self.rotationOffsetStartValue = [[PODDeviceSettingsManager deviceSettingsManager] rotationOffsetInDegrees];
		[self startRegularUpdates];
	} else if (aPanGestureRecognizer.state == UIGestureRecognizerStateChanged) {
		CGFloat xMinDistance = 30.;
		CGFloat xChangeValue = copysign(MAX(0.0,ABS(translationOffset.x) - xMinDistance), translationOffset.x);
		[PODDeviceSettingsManager deviceSettingsManager].calibrationCenterOffset = CGPointMake(self.centerOffsetStartValue.x - xChangeValue / 1024., 0);
		
		CGFloat yMinDistance = 30.;
		CGFloat yChangeValue = copysign(MAX(0.0,ABS(translationOffset.y) - yMinDistance), translationOffset.y);
        
        CGPoint location = [aPanGestureRecognizer locationInView:self.view];
        if (location.x < self.view.frame.size.width / 2) {
            [PODDeviceSettingsManager deviceSettingsManager].rotationOffsetInDegrees = self.rotationOffsetStartValue + yChangeValue / 50.;
        } else {
            [PODDeviceSettingsManager deviceSettingsManager].rotationOffsetInDegrees = self.rotationOffsetStartValue - yChangeValue / 50.;
        }
        

	}
	if (aPanGestureRecognizer.state == UIGestureRecognizerStateEnded ||
		aPanGestureRecognizer.state == UIGestureRecognizerStateFailed) {
		[self stopRegularUpdates];
		[self updateFilterDisplay];
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
	[[NSUserDefaults standardUserDefaults] synchronize];
	[self dismissViewControllerAnimated:NO completion:NULL];
}

- (IBAction)toggleModeAction:(id)sender {
	self.displayMode = 1-self.displayMode;
	[self updateFilterDisplay];
}
@end
