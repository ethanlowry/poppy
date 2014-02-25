//
//  PODDeviceSettings.h
//  Poppy
//
//  Created by Dominik Wagner on 09.02.14.
//  Copyright (c) 2014 Hack Things LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PODCameraSettings.h"
#import "PODFilterChainSettings.h"

NSString * const kPODDeviceSettingsCameraResolutionKey;

extern NSString * const kPODDeviceSettingsModePhoto;
extern NSString * const kPODDeviceSettingsModeVideo;

@interface PODDeviceSettings : NSObject

+ (instancetype)deviceSettingsFromJSONRepresentation:(NSMutableDictionary *)aJSONRepresentation modeName:(NSString *)aModeName deviceString:(NSString *)aDeviceString;

@property (nonatomic, strong) PODFilterChainSettings *filterChainSettings;
@property (nonatomic, strong) NSString *modeName;
@property (nonatomic, strong) NSString *deviceString;
@property (nonatomic, strong) PODCameraSettings *cameraSettings;

- (BOOL)isForVideo;

@end
