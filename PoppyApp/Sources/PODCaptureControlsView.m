//
//  PODCaptureControlsView.m
//  Poppy
//
//  Created by Dominik Wagner on 07.02.14.
//  Copyright (c) 2014 Hack Things LLC. All rights reserved.
//

#import "PODCaptureControlsView.h"

@interface PODCaptureControlsView ()
@property (nonatomic, strong) UIButton *shutterButton;
@property (nonatomic, strong) UIButton *homeButton;
@property (nonatomic, strong) UIButton *recordingTypeButton;
@property (nonatomic) BOOL hideControls;
@end

@implementation PODCaptureControlsView

+ (instancetype)captureControlsForView:(UIView *)aContainerView {
	// make the capture controls sit in the lower right
	CGRect frame = aContainerView.bounds;
	frame.size.width /= 2.0;
	frame.origin.x += frame.size.width;
	frame.size.height = 75;
	frame.origin.y = CGRectGetMaxY(aContainerView.bounds) - 75;
	PODCaptureControlsView *result = [[self alloc] initWithFrame:frame withExtras:YES];
	return result;
}

+ (instancetype)captureControlsForCalibrationView:(UIView *)aContainerView {
	// make the capture controls sit in the lower right
    
	CGRect frame = aContainerView.bounds;
	frame.size.width /= 2.0;
	frame.origin.x += frame.size.width;
	frame.size.height = 75;
	frame.origin.y = CGRectGetMaxY(aContainerView.bounds) - 75;
	PODCaptureControlsView *result = [[self alloc] initWithFrame:frame withExtras:NO];
	return result;
}

- (instancetype)initWithFrame:(CGRect)frame withExtras:(BOOL)showExtras
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
		CGRect bounds = self.bounds;
		
		self.opaque = NO;
		self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.15];
		
        if(showExtras){
            self.homeButton = ({
                UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
                [button setImage:[UIImage imageNamed:@"home"] forState:UIControlStateNormal];
                [button addTarget:self action:@selector(homeButtonPressed) forControlEvents:UIControlEventTouchUpInside];
                button.frame = ({
                    CGRect frame = bounds;
                    frame.size.width = CGRectGetHeight(bounds) + 20;
                    frame.origin.x = round(CGRectGetMaxX(bounds) - CGRectGetWidth(frame));
                    frame;
                });
                [self addSubview:button];
                [button setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
                button;
            });

            self.recordingTypeButton = ({
                UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
                [button setImage:[UIImage imageNamed:@"camera-toggle"] forState:UIControlStateNormal];
                [button setImage:[UIImage imageNamed:@"video-toggle"] forState:UIControlStateSelected];
                [button addTarget:self action:@selector(toggleRecordingTypePressed) forControlEvents:UIControlEventTouchUpInside];
                button.frame = ({
                    CGRect frame = bounds;
                    //				frame.origin.x = round(CGRectGetMaxX(frame) - bounds.size.height);
                    frame.size.width = bounds.size.height + 20;
                    frame;
                });
                [self addSubview:button];
                [button setAutoresizingMask:UIViewAutoresizingFlexibleRightMargin];
                button;
            });
        }

		self.shutterButton = ({
			UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
			button.frame = ({
				CGRect frame = bounds;
				frame.origin.x = round(CGRectGetMidX(frame) - bounds.size.height / 2.0);
				frame.size.width = bounds.size.height;
				frame;
			});
			[button addTarget:self action:@selector(shutterButtonDown) forControlEvents:UIControlEventTouchDown];
			[button addTarget:self action:@selector(shutterButtonUpInside) forControlEvents:UIControlEventTouchUpInside];
			[self addSubview:button];
			[button setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
			button;
		});
		[self configureShutterButtonForMode:kPODCaptureControlModePhoto];

		self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    }
    return self;
}

- (void)setCaptureControlMode:(PODCaptureControlMode)aNewMode {
	self.currentControlMode = aNewMode;
	self.recordingTypeButton.selected = aNewMode == kPODCaptureControlModeVideo;
	[self configureShutterButtonForMode:aNewMode];
}

- (void)configureShutterButtonForMode:(PODCaptureControlMode)aMode {
	if (aMode == kPODCaptureControlModePhoto) {
		[self.shutterButton setImage:[UIImage imageNamed:@"shutter"] forState:UIControlStateNormal];
		[self.shutterButton setImage:[UIImage imageNamed:@"shutterPressed"] forState:UIControlStateHighlighted];
		[self.shutterButton setImage:[UIImage imageNamed:@"shutter"] forState:UIControlStateSelected];
	} else {
		[self.shutterButton setImage:[UIImage imageNamed:@"shutter_video"] forState:UIControlStateNormal];
		[self.shutterButton setImage:[UIImage imageNamed:@"shutterPressed"] forState:UIControlStateHighlighted];
		[self.shutterButton setImage:[UIImage imageNamed:@"shutter_recording"] forState:UIControlStateSelected];
	}
}

- (void)setIsRecording:(BOOL)isRecording {
	_isRecording = isRecording;
	self.shutterButton.selected = isRecording;
}

- (IBAction)shutterButtonDown {
	//NSLog(@"%s",__FUNCTION__);
	if ([self.delegate respondsToSelector:@selector(captureControlsViewDidTouchDownShutter:)]) {
		[self.delegate captureControlsViewDidTouchDownShutter:self];
	}
}

- (IBAction)shutterButtonUpInside {
	//NSLog(@"%s",__FUNCTION__);
	if ([self.delegate respondsToSelector:@selector(captureControlsViewDidTouchUpShutter:)]) {
		[self.delegate captureControlsViewDidTouchUpShutter:self];
	}
}

- (IBAction)homeButtonPressed {
	//NSLog(@"%s",__FUNCTION__);
	if ([self.delegate respondsToSelector:@selector(captureControlsViewDidPressHome:)]) {
		[self.delegate captureControlsViewDidPressHome:self];
	}
}

- (IBAction)toggleRecordingTypePressed {
	//NSLog(@"%s",__FUNCTION__);
	self.recordingTypeButton.selected = !self.recordingTypeButton.selected;
	[self setCaptureControlMode:self.recordingTypeButton.selected ? kPODCaptureControlModeVideo : kPODCaptureControlModePhoto];
	if ([self.delegate respondsToSelector:@selector(captureControlsViewDidPressModeChange:)]) {
		[self.delegate captureControlsViewDidPressModeChange:self];
	}
}


@end
