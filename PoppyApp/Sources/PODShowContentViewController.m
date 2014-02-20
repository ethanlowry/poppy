//
//  PODShowContentViewController.m
//  Poppy Dome
//
//  Created by Dominik Wagner on 09.12.13.
//  Copyright (c) 2013 Dominik Wagner. All rights reserved.
//

#import "PODShowContentViewController.h"
#import "RBVolumeButtons.h"
#import <GLKit/GLKit.h>
#import "TCMCGGeometryAdditions.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreImage/CoreImage.h>


@interface PODShowContentViewController () <AVPlayerItemOutputPullDelegate>
@property (nonatomic) NSUInteger currentImageIndex;
@property (nonatomic) ALAsset *currentAsset;
@property (nonatomic, strong) RBVolumeButtons *buttonStealer;
@property (nonatomic) NSInteger zoomMode;
@property (nonatomic) CGPoint normalizedCenterPoint;

@property (nonatomic, strong) AVPlayerLayer *leftPlayerLayer;
@property (nonatomic, strong) AVPlayer *currentMoviePlayer;
@property AVPlayerItemVideoOutput *videoOutput;
@property dispatch_queue_t videoOutputQueue;

@property (nonatomic, strong) GLKView *leftGLKView;
@property (nonatomic, strong) CIContext *leftCIContext;
@property (nonatomic, strong) EAGLContext *leftEAGLContext;

@property (nonatomic, strong) GLKView *rightGLKView;
@property (nonatomic, strong) CIContext *rightCIContext;
@property (nonatomic, strong) EAGLContext *rightEAGLContext;

@property CADisplayLink *displayLink;

@property (nonatomic) NSURL *currentFileURL;
@end

@implementation PODShowContentViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	self.view.userInteractionEnabled = YES;
	{
		UISwipeGestureRecognizer *swipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(showPreviousImage:)];
		swipeRecognizer.numberOfTouchesRequired = 1;
		swipeRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
		[self.view addGestureRecognizer:swipeRecognizer];
	}

	{
		UISwipeGestureRecognizer *swipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(showNextImage:)];
		swipeRecognizer.numberOfTouchesRequired = 1;
		swipeRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
		[self.view addGestureRecognizer:swipeRecognizer];
	}
	self.leftView.layer.masksToBounds = YES;
	self.rightView.layer.masksToBounds = YES;
	self.leftView.layer.contentsRect = CGRectMake(0, 0, 0.5, 1.0);
	self.rightView.layer.contentsRect = CGRectMake(0.5, 0, 0.5, 1.0);
	self.leftView.layer.contentsGravity = kCAGravityResizeAspectFill;
	self.rightView.layer.contentsGravity = kCAGravityResizeAspectFill;
	self.leftView.contentScaleFactor = [[UIScreen mainScreen] scale];
	self.rightView.contentScaleFactor = [[UIScreen mainScreen] scale];
	self.imageView.alpha = 0.0;
	
	if (self.contentDirectoryURL) {
		self.rightEAGLContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
		self.rightGLKView = [[GLKView alloc] initWithFrame:self.rightView.bounds context:self.rightEAGLContext];
		[self.rightView addSubview:self.rightGLKView];
		self.rightCIContext = [CIContext contextWithEAGLContext:self.rightEAGLContext];

		self.leftEAGLContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
		self.leftGLKView = [[GLKView alloc] initWithFrame:self.leftView.bounds context:self.leftEAGLContext];
		[self.leftView addSubview:self.leftGLKView];
		self.leftCIContext = [CIContext contextWithEAGLContext:self.leftEAGLContext];

	}
	{
		UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapAction:)];
		gestureRecognizer.numberOfTapsRequired = 1;
		[self.view addGestureRecognizer:gestureRecognizer];
	}
	{
		UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapAction:)];
		gestureRecognizer.numberOfTapsRequired = 2;
		[self.view addGestureRecognizer:gestureRecognizer];
	}
	
	self.buttonStealer = [[RBVolumeButtons alloc] init];
	
	__weak __typeof__(self) weakSelf = self;
	self.buttonStealer.upBlock = ^{
		[weakSelf plusVolumeButtonPressedAction];
	};
	self.buttonStealer.downBlock = ^{
		[weakSelf minusVolumeButtonPressedAction];
	};
	
	
	// Setup AVPlayerItemVideoOutput with the required pixelbuffer attributes.
	NSDictionary *pixBuffAttributes = @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)};
	self.videoOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:pixBuffAttributes];
	self.videoOutputQueue = dispatch_queue_create("videoOutputQueue", DISPATCH_QUEUE_SERIAL);
	[[self videoOutput] setDelegate:self queue:self.videoOutputQueue];

	// Setup CADisplayLink which will callback displayPixelBuffer: at every vsync.
	self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkCallback:)];
	[self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[self.displayLink setPaused:YES];

	[self showAssetWithOffset:-1];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[self.buttonStealer startStealingVolumeButtonEvents];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[self.buttonStealer stopStealingVolumeButtonEvents];
}

- (void)updateEyeViews {
	CGRect contentsRect = CGRectMake(0, 0, 0.5, 1.0);
	if (self.zoomMode > 0) {
		CGFloat factor = 0.15;
		CGFloat contentDiameterX = 0.5 / (self.zoomMode * factor + 1.0);
		CGFloat contentDiameterY = 0.7 / (self.zoomMode * factor + 1.0);
		CGFloat contentXInset = (0.5 - contentDiameterX) / 2.0;
		CGFloat contentYInset = (1.0 - contentDiameterY) / 2.0;
		contentsRect = CGRectMake(contentXInset, contentYInset, contentDiameterX, contentDiameterY);
	}
	
	contentsRect.origin.x += self.normalizedCenterPoint.x;
	contentsRect.origin.x = MAX(0.0,contentsRect.origin.x);
	if (CGRectGetMaxX(contentsRect) > 0.5) contentsRect.origin.x = 0.5 - CGRectGetWidth(contentsRect);
	
	contentsRect.origin.y += self.normalizedCenterPoint.y;
	contentsRect.origin.y = MAX(0.0,contentsRect.origin.y);
	if (CGRectGetMaxY(contentsRect) > 1.0) {
		contentsRect.origin.y = 1.0 - CGRectGetHeight(contentsRect);
	}
	
	self.leftView.layer.contentsRect = contentsRect;
	self.rightView.layer.contentsRect = CGRectOffset(contentsRect,0.5,0.0);
	
}

- (void)setNormalizedCenterPoint:(CGPoint)aNormalizedCenterPoint {
	if (!CGPointEqualToPoint(aNormalizedCenterPoint, _normalizedCenterPoint)) {
		_normalizedCenterPoint = TCMCGPointLinearInterpolation(_normalizedCenterPoint, aNormalizedCenterPoint, 0.8);
		dispatch_async(dispatch_get_main_queue(), ^{
			[self updateEyeViews];
		});
	}
}

- (void)showCurrentMovie {
	[self.currentMoviePlayer pause];
	[self.currentMoviePlayer.currentItem removeOutput:self.videoOutput];
	AVPlayer *moviePlayer = [AVPlayer playerWithURL:self.currentFileURL];
	[moviePlayer.currentItem addOutput:self.videoOutput];
	
	self.currentMoviePlayer = moviePlayer;
	[moviePlayer play];
	[self.displayLink setPaused:NO];
}


// an offSetPOint has range from -0.5 to 0.5
- (CGRect)rectByPlacingRect:(CGRect)aInnerRect inContainingRect:(CGRect)aContainingRect accordingToOffset:(CGPoint)anOffsetPoint {
	CGRect result = aInnerRect;
	CGFloat wiggleRoomX = CGRectGetWidth(aContainingRect) - CGRectGetWidth(aInnerRect);
	CGFloat wiggleRoomY = CGRectGetHeight(aContainingRect) - CGRectGetHeight(aInnerRect);
	
	result.origin.x = (wiggleRoomX / 2.0) + (anOffsetPoint.x * wiggleRoomX);
	result.origin.y = (wiggleRoomY / 2.0) + (anOffsetPoint.y * -wiggleRoomY);

	return result;
}


- (void)displayLinkCallback:(CADisplayLink *)sender
{
	
	/*
	 The callback gets called once every Vsync.
	 Using the display link's timestamp and duration we can compute the next time the screen will be refreshed, and copy the pixel buffer for that time
	 This pixel buffer can then be processed and later rendered on screen.
	 */
	CMTime outputItemTime = kCMTimeInvalid;
	
	// Calculate the nextVsync time which is when the screen will be refreshed next.
	CFTimeInterval nextVSync = ([sender timestamp] + [sender duration]);
	
	outputItemTime = [[self videoOutput] itemTimeForHostTime:nextVSync];
	
	if ([[self videoOutput] hasNewPixelBufferForItemTime:outputItemTime]) {
		CVPixelBufferRef pixelBuffer = NULL;
		pixelBuffer = [[self videoOutput] copyPixelBufferForItemTime:outputItemTime itemTimeForDisplay:NULL];
		CIImage *image = [CIImage imageWithCVPixelBuffer:pixelBuffer];
		
		
		CGRect sourceRect = image.extent;
		sourceRect.size.width /= 2;
		CGRect containingRect = sourceRect;
		
		CGFloat rightPictureOffset = CGRectGetWidth(sourceRect);
		
		// TODO: do same calculations as in update stuff kram lalala.
		
		CGRect targetRect = self.leftGLKView.bounds;
		targetRect = CGRectApplyAffineTransform(targetRect, CGAffineTransformMakeScale(2.0,2.0));

		
		// clear views
		[EAGLContext setCurrentContext:self.leftEAGLContext];
		glClearColor(0.0, 0.0, 0.0, 0.0);
		glClear(GL_COLOR_BUFFER_BIT);
		[EAGLContext setCurrentContext:self.rightEAGLContext];
		glClearColor(0.0, 0.0, 0.0, 0.0);
		glClear(GL_COLOR_BUFFER_BIT);
				
		if (self.zoomMode == 1) {
			targetRect = CGRectInset(targetRect, 0, CGRectGetHeight(targetRect) / 4.0);
		} else if (self.zoomMode == 2) {
			sourceRect.size.width /= 2.0;
			sourceRect = [self rectByPlacingRect:sourceRect inContainingRect:containingRect accordingToOffset:self.normalizedCenterPoint];
		} else if (self.zoomMode > 2) {
			sourceRect = CGRectApplyAffineTransform(sourceRect, CGAffineTransformMakeScale(0.5 / (self.zoomMode * 0.4), 1.0 / (self.zoomMode * 0.4)));
			sourceRect = [self rectByPlacingRect:sourceRect inContainingRect:containingRect accordingToOffset:self.normalizedCenterPoint];
		}
		[self.leftCIContext drawImage:image inRect:targetRect fromRect:sourceRect];
		[self.leftGLKView setNeedsDisplay];

		sourceRect.origin.x += rightPictureOffset;
		[self.rightCIContext drawImage:image inRect:targetRect fromRect:sourceRect];
		[self.rightGLKView setNeedsDisplay];

		
		CVPixelBufferRelease(pixelBuffer);
	}
}


- (void)showCurrentAsset {
	ALAssetRepresentation *assetRepresentation = [self.currentAsset defaultRepresentation];
	CGImageRef fullImage = assetRepresentation.fullResolutionImage;
	self.leftView.layer.contents = (__bridge id)fullImage;
	self.rightView.layer.contents = (__bridge id)fullImage;
	UIImage *image = [[UIImage alloc] initWithCGImage:fullImage scale:assetRepresentation.scale orientation:UIImageOrientationUp];
	self.imageView.image = image;
}

- (void)showAssetWithOffset:(NSInteger)anOffset {
	if (self.assetsGroup) {
		[self.assetsGroup setAssetsFilter:[ALAssetsFilter allPhotos]];
		NSInteger assetCount = self.assetsGroup.numberOfAssets;
		NSInteger targetIndex = self.currentImageIndex + anOffset;
		if (targetIndex < 0) {
			targetIndex = targetIndex + assetCount;
		} else if (targetIndex >= assetCount) {
			targetIndex = targetIndex - assetCount;
		}
		self.currentImageIndex = targetIndex;
		[self.assetsGroup enumerateAssetsAtIndexes:[NSIndexSet indexSetWithIndex:targetIndex] options:0 usingBlock:^(ALAsset *asset, NSUInteger index, BOOL *stop) {
			if (asset) { // we also get the call with nil as last call, so we need to guard against that
				self.currentAsset = asset;
				[self showCurrentAsset];
			}
		}];
	} else {
		NSMutableArray *movieURLArray = [NSMutableArray new];
		for (NSURL *fileURL in [[NSFileManager defaultManager] enumeratorAtURL:self.contentDirectoryURL includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles errorHandler:nil]) {
			
			if ([@[@"mp4",@"m4v"] containsObject:[[fileURL pathExtension] lowercaseString]]) {
				[movieURLArray addObject:fileURL];
			}
		}
		NSInteger assetCount = movieURLArray.count;
		NSInteger targetIndex = self.currentImageIndex + anOffset;
		if (targetIndex < 0) {
			targetIndex = targetIndex + assetCount;
		} else if (targetIndex >= assetCount) {
			targetIndex = targetIndex - assetCount;
		}
		self.currentImageIndex = targetIndex;
		self.currentFileURL = movieURLArray[targetIndex];
		
		[self showCurrentMovie];
	}
}

- (void)showPreviousImage:(id)aSender {
	[self showAssetWithOffset:-1];
}

- (void)showNextImage:(id)aSender {
	[self showAssetWithOffset:1];
}

- (void)doubleTapAction:(UIGestureRecognizer *)aGestureRecognizer {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)singleTapAction:(UIGestureRecognizer *)aGestureRecognizer {
	self.currentMoviePlayer.rate = 1.0 - self.currentMoviePlayer.rate;
}



- (void)minusVolumeButtonPressedAction {
	[self showPreviousImage:nil];
}

- (void)toggleZoomMode {
	self.zoomMode = (self.zoomMode + 1) % 7;
	[self updateEyeViews];
}

- (void)plusVolumeButtonPressedAction {
	[self toggleZoomMode];
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

@end
