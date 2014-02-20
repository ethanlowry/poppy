//
//  PODTestFilterChainViewController.m
//  Poppy Dome
//
//  Created by Dominik Wagner on 16.12.13.
//  Copyright (c) 2013 Dominik Wagner. All rights reserved.
//

#import "PODTestFilterChainViewController.h"
#import <GLKit/GLKit.h>
#import <CoreImage/CoreImage.h>
#import "RBVolumeButtons.h"
#import "PODFilterFactory.h"
#import "PODDeviceSettingsManager.h"
#import "PODAppDelegate.h"
#import "PODAssetsManager.h"

@interface PODTestFilterChainViewController ()
@property (nonatomic, strong) GLKView *GLKView;
@property (nonatomic, strong) CIContext *CIContext;
@property (nonatomic, strong) EAGLContext *EAGLContext;

@property (nonatomic, strong) RBVolumeButtons *buttonStealer;

@property (nonatomic, strong) CIImage *sourceImage;
@property (nonatomic) NSInteger tapCount;
@end

@implementation PODTestFilterChainViewController

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
    // Do any additional setup after loading the view from its nib.
	self.EAGLContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
	GLKView *glkitView = [[GLKView alloc] initWithFrame:self.view.bounds context:self.EAGLContext];
	UIView *view = self.view;
	[view addSubview:glkitView];
	glkitView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	glkitView.userInteractionEnabled = NO;
	self.view.autoresizesSubviews = YES;
	self.CIContext = [CIContext contextWithEAGLContext:self.EAGLContext];
	self.GLKView = glkitView;
	
	self.buttonStealer = [[RBVolumeButtons alloc] init];
	
	__weak __typeof__(self) weakSelf = self;
	self.buttonStealer.upBlock = ^{
		[weakSelf plusVolumeButtonPressedAction];
	};
	self.buttonStealer.downBlock = ^{
		[weakSelf minusVolumeButtonPressedAction];
	};
	
	[self loadSourceImage];
	[self updateFilterDisplay];
	
	UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapAction:)];
	tap.numberOfTouchesRequired = 1;
	[self.view addGestureRecognizer:tap];
}

- (void)loadSourceImage {
	CIImage *sourceImage = [CIImage imageWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"TestImagesRaw5s/IMG_5462" withExtension:@"JPG"]];
	self.sourceImage = sourceImage;
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
		self.tapCount = 0;
		[NSOperationQueue TCM_performBlockOnMainQueue:^{
			[self singleTapAction:nil]; // show the raw image with the debug overlay
		} afterDelay:0.5]; // delay a little so it actually happens
	}];
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
	targetRect = CGRectInset(targetRect,(desiredWidth - CGRectGetWidth(targetRect)) / -2.0,0);
	[self.CIContext drawImage:aCIImage inRect:targetRect fromRect:sourceRect];
	[self.GLKView setNeedsDisplay];
	//	[self grabImage];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[self.buttonStealer startStealingVolumeButtonEvents];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[self.buttonStealer stopStealingVolumeButtonEvents];
}

- (void)updateFilterDisplay {
}

- (CIImage *)drawOverlaysForSettings:(PODFilterChainSettings *)aFilterChainSettings image:(CIImage *)aCIImage {
	CGImageRef cgImage = [self.CIContext createCGImage:aCIImage fromRect:aCIImage.extent];
	UIGraphicsBeginImageContextWithOptions(aCIImage.extent.size, YES, 1.0);
	UIImage *uiImage = [UIImage imageWithCGImage:cgImage scale:1.0 orientation:UIImageOrientationUp];
	[uiImage drawAtPoint:CGPointZero];
	[[UIColor redColor] set];
	CGRect bounds = CGRectZero;
	bounds.size = aCIImage.extent.size;
	
	void(^stroke)(UIBezierPath *path, CGFloat lineWidth, UIColor *color) = ^(UIBezierPath *path, CGFloat lineWidth, UIColor *color) {
		path.lineWidth = lineWidth;
		[color set];
		[path stroke];
	};
	
	CGRect leftRect = [aFilterChainSettings leftCropRectForImageExtent:bounds];
	stroke([UIBezierPath bezierPathWithRect:leftRect], 3.0, [UIColor redColor]);
	CGRect rightRect = [aFilterChainSettings rightCropRectForImageExtent:bounds];
	stroke([UIBezierPath bezierPathWithRect:rightRect], 3.0, [UIColor greenColor]);
	
	CGPoint centerPoint = [PODFilterChainSettings absolutePointForNormalizedPoint:aFilterChainSettings.center imageExtent:bounds];
	UIBezierPath *centerCross = [UIBezierPath bezierPath];
	CGFloat distance = 50.0;
	[centerCross moveToPoint:TCMPointOffset(centerPoint, -distance, 0)];
	[centerCross addLineToPoint:TCMPointOffset(centerPoint, distance, 0)];
	[centerCross moveToPoint:TCMPointOffset(centerPoint, 0, -distance)];
	[centerCross addLineToPoint:TCMPointOffset(centerPoint, 0, distance)];
	stroke(centerCross,3.0,[UIColor purpleColor]);
	
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	CFRelease(cgImage);
	CIImage *ciImage = [[CIImage alloc] initWithCGImage:[image CGImage]];
	return ciImage;
}

#pragma mark -

- (void)minusVolumeButtonPressedAction {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)plusVolumeButtonPressedAction {
}

- (void)singleTapAction:(UITapGestureRecognizer *)aRecognizer {
	PODFilterChainSettings *filterChainSettings = [[PODDeviceSettingsManager deviceSettingsManager] deviceSettingsForMode:kPODDeviceSettingsModePhoto].filterChainSettings;
	NSArray *filterChain = [PODFilterFactory filterChainWithSettings:filterChainSettings
														  inputImage:self.sourceImage];
	
	[filterChain.firstObject setValue:self.sourceImage forKey:@"inputImage"];
	
	CIImage *outputImage = self.sourceImage;
	
	NSInteger filterChainIndex = self.tapCount % (filterChain.count);
	if (filterChainIndex > 0) {
		outputImage = [filterChain[filterChainIndex] outputImage];
	} else {
		outputImage = [self drawOverlaysForSettings:filterChainSettings image:outputImage];
	}
	[self displayCIImage:outputImage];
	self.tapCount++;
}

#pragma mark -


- (NSUInteger)supportedInterfaceOrientations {
	return UIInterfaceOrientationMaskLandscapeLeft;
}

- (BOOL)prefersStatusBarHidden {
	return YES;
}


@end
