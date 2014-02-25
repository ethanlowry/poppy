//
//  PODDeviceSettings.m
//  Poppy
//
//  Created by Dominik Wagner on 09.02.14.
//  Copyright (c) 2014 Hack Things LLC. All rights reserved.
//

#import "PODDeviceSettings.h"

NSString * const kPODDeviceSettingsFilterChainSettingsKey = @"filterChainSettings";
NSString * const kPODDeviceSettingsCameraSettingsKey = @"cameraSettings";

NSString * const kPODDeviceSettingsCameraResolutionKey = @"resolution";

NSString * const kPODDeviceSettingsModePhoto = @"photo";
NSString * const kPODDeviceSettingsModeVideo = @"video";

@implementation PODDeviceSettings

+ (instancetype)deviceSettingsFromJSONRepresentation:(NSDictionary *)aJSONRepresentation modeName:(NSString *)aModeName deviceString:(NSString *)aDeviceString {
	NSAssert(aJSONRepresentation, @"the json representation cannot be nil");
	// load the appropriate bits
	PODFilterChainSettings *filterChainSettings = [PODFilterChainSettings filterChainSettingsWithJSONRepresentation:aJSONRepresentation[kPODDeviceSettingsFilterChainSettingsKey]];

	PODCameraSettings *cameraSettings = [PODCameraSettings cameraSettingsWithJSONRepresentation:aJSONRepresentation[kPODDeviceSettingsCameraSettingsKey]];

	PODDeviceSettings *result = [[PODDeviceSettings alloc] init];
	result.modeName = aModeName;
	result.deviceString = aDeviceString;
	result.filterChainSettings = filterChainSettings;
	result.cameraSettings = cameraSettings;
	return result;
}

- (NSString *)description {
	NSMutableArray *result = [NSMutableArray new];
	for (NSString *string in @[@"deviceString", @"modeName", kPODDeviceSettingsFilterChainSettingsKey,kPODDeviceSettingsCameraSettingsKey]) {
		[result addObject:[NSString stringWithFormat:@"%@: %@",string, [[self valueForKey:string] description]]];
	}
	return [result componentsJoinedByString:@"; "];
}

- (BOOL)isForVideo {
	BOOL result = [self.modeName isEqualToString:kPODDeviceSettingsModeVideo];
	return result;
}


@end
