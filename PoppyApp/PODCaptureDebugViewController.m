//
//  PODCaptureDebugViewController.m
//  Poppy Dome
//
//  Created by Dominik Wagner on 03.02.14.
//  Copyright (c) 2014 Dominik Wagner. All rights reserved.
//

#import "PODCaptureDebugViewController.h"
#import "RBVolumeButtons.h"
#import "TCMCaptureManager.h"
#import "PODDeviceSettingsManager.h"
#import "PODCaptureControlsView.h"

@interface PODCaptureDebugViewController () <PODCaptureControlsViewDelegate>
@property (strong, nonatomic) IBOutlet UILabel *bigDebugLabel;

@property (nonatomic, strong) RBVolumeButtons *buttonStealer;


@end

@implementation PODCaptureDebugViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		[TCMCaptureManager captureManager]; // make sure it exists
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	self.buttonStealer = [[RBVolumeButtons alloc] init];
	
	__weak __typeof__(self) weakSelf = self;
	self.buttonStealer.upBlock = ^{
		[weakSelf plusVolumeButtonPressedAction];
	};
	self.buttonStealer.downBlock = ^{
		[weakSelf minusVolumeButtonPressedAction];
	};

	{
		//		UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchAction:)];
		//		[self.view addGestureRecognizer:pinchRecognizer];
		
		UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapAction:)];
		tapRecognizer.numberOfTapsRequired = 1;
		[self.view addGestureRecognizer:tapRecognizer];
		
		UITapGestureRecognizer *doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapAction:)];
		doubleTapRecognizer.numberOfTapsRequired = 2;
		[self.view addGestureRecognizer:doubleTapRecognizer];
		
		UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panAction:)];
		[self.view addGestureRecognizer:panRecognizer];
	}
	[[TCMCaptureManager captureManager] startSession];
	
	AVCaptureVideoPreviewLayer *previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:[[TCMCaptureManager captureManager] captureSession]];
	previewLayer.transform = CATransform3DMakeAffineTransform(CGAffineTransformMakeRotation(M_PI_2));
	previewLayer.frame = self.view.bounds;
	[self.view.layer insertSublayer:previewLayer atIndex:0];

	// setup the regular UI
	{
		PODCaptureControlsView *controlsView = [PODCaptureControlsView captureControlsForView:self.view];
		[self.view addSubview:controlsView];
		controlsView.delegate = self;
	}

}


- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[self.buttonStealer startStealingVolumeButtonEvents];
	[[TCMCaptureManager captureManager] startSession];
	[self singleTapAction:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[self.buttonStealer stopStealingVolumeButtonEvents];
	
	[[TCMCaptureManager captureManager] stopSession];
	// make sure we live long enough to recieve all delegate methods
	[[TCMCaptureManager captureManager] enqueueBlockToSessionQueue:^{
		[self captureSessionDidStop];
	}];
}

- (void)captureSessionDidStop {
	NSLog(@"%s successfully stopped the capture session",__FUNCTION__);
}

- (void)panAction:(UIPanGestureRecognizer *)panRecognizer {
}

- (void)singleTapAction:(UITapGestureRecognizer *)tapRecognizer {
}

- (void)doubleTapAction:(UITapGestureRecognizer *)tapRecognizer {
	[self dismissViewControllerAnimated:YES completion:NULL];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)captureAllAction {
	[[[TCMCaptureManager captureManager] stillImageOutput] setOutputSettings:@{
																			   AVVideoCodecKey : AVVideoCodecJPEG
																			   }];
	[[TCMCaptureManager captureManager] stepThroughAllInterestingFormatsWithBlock:^(NSString *aFormatDescription, dispatch_block_t aContinueBlock) {
		if (aContinueBlock) {
			NSLog(@"%s %@",__FUNCTION__,aFormatDescription);
			self.bigDebugLabel.text = aFormatDescription;
			NSLog(@"%@\n%@",aFormatDescription, [[[[TCMCaptureManager captureManager] captureInput] device] activeFormat]);
			AVCaptureStillImageOutput *output = [[TCMCaptureManager captureManager] stillImageOutput];
			[NSOperationQueue TCM_performBlockOnMainQueue:^{
				[output captureStillImageAsynchronouslyFromConnection:output.connections.firstObject completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
					NSData *jpegData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
					NSString *filename = [NSString stringWithFormat:@"%@_%@.jpeg",[PODDeviceSettingsManager TCM_platformString],aFormatDescription];
					NSURL *url = [NSURL fileURLWithPath:NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject];
					NSURL *targetURL = [url URLByAppendingPathComponent:filename];
					[jpegData writeToURL:targetURL options:0 error:NULL];
					[[TCMCaptureManager captureManager] enqueueBlockToSessionQueue:aContinueBlock];
				}];
			} afterDelay:2.2];
			
		}
	}];
}

- (void)captureControlsViewDidTouchDownShutter:(PODCaptureControlsView *)aView {
	[self captureAllAction];
}

- (void)captureControlsViewDidPressHome:(PODCaptureControlsView *)aView {
	[self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)plusVolumeButtonPressedAction {
	[self captureAllAction];
}

- (void)minusVolumeButtonPressedAction {
	
}

#pragma mark -
- (NSUInteger)supportedInterfaceOrientations {
	return UIInterfaceOrientationMaskLandscapeLeft;
}


@end
