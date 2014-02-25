//
//  AVCaptureDeviceFormat+TCMAVCaptureDeviceFormatAdditions.m
//  Poppy
//
//  Created by Dominik Wagner on 03.02.14.
//  Copyright (c) 2014 Hack Things LLC. All rights reserved.
//

#import "AVCaptureDeviceFormat+TCMAVCaptureDeviceFormatAdditions.h"

@implementation AVCaptureDeviceFormat (TCMAVCaptureDeviceFormatAdditions)

- (CMVideoDimensions)TCM_videoDimensions {
	CMFormatDescriptionRef descriptionRef = self.formatDescription;
	CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(descriptionRef);
	return dimensions;
}

- (CGSize)TCM_videoSize {
	CMVideoDimensions dimensions = self.TCM_videoDimensions;
	CGSize result = CGSizeMake(dimensions.width, dimensions.height);
	return result;
}


- (NSString *)niceFilenameDescription {
	NSMutableArray *parts = [NSMutableArray new];
	CMFormatDescriptionRef descriptionRef = self.formatDescription;
	CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(descriptionRef);
	[parts addObject:[NSString stringWithFormat:@"%dx%d",dimensions.width,dimensions.height]];
	[parts addObject:[NSString stringWithFormat:@"FOV-%0.2f",self.videoFieldOfView]];
	[parts addObject:[NSString stringWithFormat:@"MFPS-%@",[self.videoSupportedFrameRateRanges valueForKeyPath:@"@max.maxFrameRate"]]];
	[parts addObject:[NSString stringWithFormat:@"UPS-%0.3f",self.videoZoomFactorUpscaleThreshold]];
	
	
	NSString *result = [parts componentsJoinedByString:@"_"];
	return result;
}
@end
