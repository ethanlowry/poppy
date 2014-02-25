//
//  PODCaptureControlsView.h
//  Poppy
//
//  Created by Dominik Wagner on 07.02.14.
//  Copyright (c) 2014 Hack Things LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(char, PODCaptureControlMode) {
	kPODCaptureControlModePhoto,
	kPODCaptureControlModeVideo,
};

@class PODCaptureControlsView;

@protocol PODCaptureControlsViewDelegate <NSObject>

@optional
- (void)captureControlsViewDidPressHome:(PODCaptureControlsView *)aView;
- (void)captureControlsViewDidPressModeChange:(PODCaptureControlsView *)aView;
- (void)captureControlsViewDidTouchDownShutter:(PODCaptureControlsView *)aView;
- (void)captureControlsViewDidTouchUpShutter:(PODCaptureControlsView *)aView;
@end

@interface PODCaptureControlsView : UIView
@property (nonatomic) PODCaptureControlMode currentControlMode;
@property (nonatomic, weak) id<PODCaptureControlsViewDelegate> delegate;
@property (nonatomic) BOOL isRecording;
+ (instancetype)captureControlsForView:(UIView *)aContainerView;
+ (instancetype)captureControlsForCalibrationView:(UIView *)aContainerView;

@end
