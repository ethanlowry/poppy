//
//  PODDeviceSettingsManager.h
//  Poppy
//
//  Created by Dominik Wagner on 09.02.14.
//  Copyright (c) 2014 Hack Things LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PODDeviceSettings.h"

@interface PODDeviceSettingsManager : NSObject

/** @returns the device platform string - e.g. iPhone4,1, etc.*/
+ (NSString *)TCM_platformString;

+ (instancetype)deviceSettingsManager;

/** @returns the PODDeviceSettings for the specified Mode. Trys to fallback on similar devices, if the device it runs on isn't available. Also falls back into photo mode, if no video settings are present */
- (PODDeviceSettings *)deviceSettingsForMode:(NSString *)aModeNameString;


/** */
@property (nonatomic) CGPoint calibrationCenterOffset;
@property (nonatomic) CGFloat rotationOffsetInDegrees;

@end
