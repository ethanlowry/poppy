//
//  TCMCaptureManager.h
//  Poppy
//
//  Created by Dominik Wagner on 16.12.13.
//  Copyright (c) 2014 Hack Things LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "PODDeviceSettings.h"

@interface TCMCaptureManager : NSObject

@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic, strong) dispatch_queue_t captureQueue;
@property (nonatomic, strong) dispatch_queue_t writerQueue;
@property (nonatomic, strong) dispatch_queue_t audioCaptureQueue;
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureDeviceInput *captureInput;

@property (nonatomic, strong) AVCaptureDeviceFormat *desiredFormat;

@property (nonatomic, strong) AVAssetWriter *assetWriter;
@property (nonatomic)         CMTime currentAssetWriterStartTime;
@property (nonatomic, strong) AVAssetWriterInput *assetWriterInput;
@property (nonatomic, strong) AVAssetWriterInput *assetWriterAudioInput;
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *assetWriterInputPixelBufferAdaptor;
@property (nonatomic, strong) NSDictionary *pixelBufferAttributesDictionary;

+ (NSURL *)tempMovieURL;
+ (instancetype)captureManager;
- (void)startSession;
- (void)stopSession;

- (void)setDesiredDeviceSettings:(PODDeviceSettings *)desiredDeviceSettings;

- (void)enqueueBlockToSessionQueue:(dispatch_block_t)aBlock;
- (void)enqueueBlockToWriterQueue:(dispatch_block_t)aBlock;

- (void)stepThroughAllInterestingFormatsWithBlock:(void(^)(NSString *aFormatDescription,dispatch_block_t aContinueBlock))aCallbackBlock;

- (CVPixelBufferRef)createPixelBufferFromOutputPoolAtTime:(CMTime)aTime;
- (void)prepareVideoAssetWriter;
- (void)finishWriterWithCompletionHandler:(void (^)(AVAssetWriter *aWriter))aCompletionHandler;
- (BOOL)writerEncodePixelBuffer:(CVPixelBufferRef)aPixelBuffer sampleTime:(CMTime)aTime;

/** focus on a centerNormalized point. coordinate system is centered on one of the two cropping areas -0.5,0 is the left center, 0.5,0 is right center. y axis is also scaled based on the width, so it's rage varies depending on the aspect ratio of the image, positive values move downward */
- (void)focusOnCenterNormalizedPoint:(CGPoint)aPoint isLeft:(BOOL)isLeft;

@end
