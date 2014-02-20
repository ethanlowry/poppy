//
//  AVCaptureDeviceFormat+TCMAVCaptureDeviceFormatAdditions.h
//  Poppy Dome
//
//  Created by Dominik Wagner on 03.02.14.
//  Copyright (c) 2014 Dominik Wagner. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@interface AVCaptureDeviceFormat (TCMAVCaptureDeviceFormatAdditions)
- (NSString *)niceFilenameDescription;
- (CMVideoDimensions)TCM_videoDimensions;
- (CGSize)TCM_videoSize;
@end
