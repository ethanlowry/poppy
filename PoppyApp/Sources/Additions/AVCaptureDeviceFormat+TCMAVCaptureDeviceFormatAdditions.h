//
//  AVCaptureDeviceFormat+TCMAVCaptureDeviceFormatAdditions.h
//  Poppy
//
//  Created by Dominik Wagner on 03.02.14.
//  Copyright (c) 2014 Hack Things LLC. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@interface AVCaptureDeviceFormat (TCMAVCaptureDeviceFormatAdditions)
- (NSString *)niceFilenameDescription;
- (CMVideoDimensions)TCM_videoDimensions;
- (CGSize)TCM_videoSize;
@end
