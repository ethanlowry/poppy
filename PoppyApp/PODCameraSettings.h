//
//  PODCameraSettings.h
//  Poppy
//
//  Created by Dominik Wagner on 09.02.14.
//  Copyright (c) 2014 Hack Things LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kPODCameraFPSKey;
extern NSString * const kPODCameraResolutionKey;
extern NSString * const kPODCameraZoomKey;
extern NSString * const kPODCameraSmoothAutoFocusKey;
extern NSString * const kPODCameraSimplePreviewKey;
extern NSString * const kPODCamersJPEGStillCaptureKey;
extern NSString * const kPODCamersOutputResolutionKey;
extern NSString * const kPODCamersDirectVideoCaptureKey;

@interface PODCameraSettings : NSObject

+ (instancetype)cameraSettingsWithJSONRepresentation:(NSDictionary *)aJSONRepresentation;

@property (nonatomic) CGFloat fps;
@property (nonatomic) CGSize resolution;
@property (nonatomic) CGSize outputResolution;
@property (nonatomic) CGFloat zoom;
@property (nonatomic) BOOL smoothAutoFocus;
@property (nonatomic) BOOL simplePreview;
@property (nonatomic) CGFloat simplePreviewZoom;
@property (nonatomic) BOOL jpegStillCapture;
@property (nonatomic) BOOL directVideoCapture;

@end
