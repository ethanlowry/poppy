//
//  PODCameraSettings.m
//  Poppy
//
//  Created by Dominik Wagner on 09.02.14.
//  Copyright (c) 2014 Hack Things LLC. All rights reserved.
//

#import "PODCameraSettings.h"

NSString * const kPODCameraFPSKey = @"fps";
NSString * const kPODCameraResolutionKey = @"resolution";
NSString * const kPODCameraZoomKey = @"zoom";
NSString * const kPODCameraSmoothAutoFocusKey = @"smoothAutoFocus";
NSString * const kPODCameraSimplePreviewKey = @"simplePreview";
NSString * const kPODCameraSimplePreviewZoomKey = @"simplePreviewZoom";
NSString * const kPODCamersJPEGStillCaptureKey = @"jpegStillCapture";
NSString * const kPODCamersOutputResolutionKey = @"outputResolution";
NSString * const kPODCamersDirectVideoCaptureKey = @"directVideoCapture";



@implementation PODCameraSettings

+ (instancetype)cameraSettingsWithJSONRepresentation:(NSDictionary *)aJSONRepresentation {
	PODCameraSettings *result = [[PODCameraSettings alloc] init];
	result.fps = [aJSONRepresentation[kPODCameraFPSKey] doubleValue];
	result.resolution = CGSizeFromString(aJSONRepresentation[kPODCameraResolutionKey]);
	result.zoom = [aJSONRepresentation[kPODCameraZoomKey] doubleValue];
	result.smoothAutoFocus = [aJSONRepresentation[kPODCameraSmoothAutoFocusKey] boolValue];
	result.simplePreview = [aJSONRepresentation[kPODCameraSimplePreviewKey] boolValue];
	result.jpegStillCapture = [aJSONRepresentation[kPODCamersJPEGStillCaptureKey] boolValue];
	result.directVideoCapture = [aJSONRepresentation[kPODCamersDirectVideoCaptureKey] boolValue];
	if (aJSONRepresentation[kPODCameraSimplePreviewZoomKey]) {
		result.simplePreviewZoom = [aJSONRepresentation[kPODCameraSimplePreviewZoomKey] doubleValue];
	}
	if (aJSONRepresentation[kPODCamersOutputResolutionKey]) {
		result.outputResolution = CGSizeFromString(aJSONRepresentation[kPODCamersOutputResolutionKey]);
	}
	return result;
}

- (instancetype)init {
	self = [super init];
	if (self) {
		// defaults
		self.zoom = 1.0;
		self.outputResolution = CGSizeMake(1280, 720);
		self.simplePreviewZoom = 1.0;
	}
	return self;
}

- (NSString *)description {
	NSMutableArray *result = [NSMutableArray new];
	for (NSString *string in @[kPODCameraFPSKey, kPODCameraResolutionKey, kPODCameraZoomKey, kPODCameraSmoothAutoFocusKey, kPODCameraSimplePreviewKey, kPODCamersJPEGStillCaptureKey,kPODCamersOutputResolutionKey]) {
		[result addObject:[NSString stringWithFormat:@"ca-%@: %@",string, [[self valueForKey:string] description]]];
	}
	return [result componentsJoinedByString:@"; "];
}


@end
