//
//  PODDeviceSettingsManager.m
//  Poppy
//
//  Created by Dominik Wagner on 09.02.14.
//  Copyright (c) 2014 Hack Things LLC. All rights reserved.
//

#import "PODDeviceSettingsManager.h"

#include <sys/types.h>
#include <sys/sysctl.h>


NSString * const kPODDeviceSettingsCalibrationCenterOffsetKey = @"calibrationCenterOffset";
NSString * const kPODDeviceSettingsCalibrationRotationOffsetKey = @"rotationOffsetInDegrees";


@interface PODDeviceSettingsManager ()
@property (nonatomic, strong) NSMutableDictionary *deviceSettings;
@end

@implementation PODDeviceSettingsManager

+ (NSString *)TCM_platformString {
	static NSString *platformString = nil;
	if (!platformString) {
		size_t size;
		sysctlbyname("hw.machine", NULL, &size, NULL, 0);
		char *machine = malloc(size);
		sysctlbyname("hw.machine", machine, &size, NULL, 0);
		platformString = [NSString stringWithUTF8String:machine];
		free(machine);
	}
	return platformString;
}

+ (instancetype)deviceSettingsManager {
	static PODDeviceSettingsManager *s_sharedInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		s_sharedInstance = [self new];
	});
	return s_sharedInstance;
}

- (instancetype)init {
	self = [super init];
	if (self) {
		_deviceSettings = [NSMutableDictionary new];
		NSString *centerString = [[NSUserDefaults standardUserDefaults] objectForKey:kPODDeviceSettingsCalibrationCenterOffsetKey];
		self.calibrationCenterOffset = [centerString isKindOfClass:[NSString class]]? CGPointFromString(centerString) : CGPointMake(0,0);
		NSNumber *rotationOffset = [[NSUserDefaults standardUserDefaults] objectForKey:kPODDeviceSettingsCalibrationRotationOffsetKey];
		self.rotationOffsetInDegrees = rotationOffset ? rotationOffset.doubleValue : 0.0;
		[self loadSettings];
	}
	return self;
}

- (void)setCalibrationCenterOffset:(CGPoint)calibrationCenterOffset {
	_calibrationCenterOffset = calibrationCenterOffset;
	[[NSUserDefaults standardUserDefaults] setObject:NSStringFromCGPoint(_calibrationCenterOffset) forKey:kPODDeviceSettingsCalibrationCenterOffsetKey];
}

- (void)setRotationOffsetInDegrees:(CGFloat)rotationOffsetInDegrees {
	_rotationOffsetInDegrees = rotationOffsetInDegrees;
	[[NSUserDefaults standardUserDefaults] setObject:@(_rotationOffsetInDegrees) forKey:kPODDeviceSettingsCalibrationRotationOffsetKey];
}

/** provides fallbacks for devices without settings, first looksup in a static dictionary, then counts down the number after the comma if any - see http://theiphonewiki.com/wiki/Models for a complete list of models
	@returns fallback platform string if any possible, or iPhone6,1 (iPhone 5s) as last fallback resort
 */
- (NSString *)fallbackPlatformStringForString:(NSString *)aPlatformString {
	NSDictionary *fallbackDictionary = @{
										 @"iPhone6,2" : @"iPhone6,1", // iPhone 5s - just as an example. the dialing down the last numbers should actually handle all current cases. if not, this would be the dictionary to put this in.
										 };
	NSString *result = fallbackDictionary[aPlatformString];
	
	if (!result) {
		// count down the last digit
		NSMutableArray *components = [[aPlatformString componentsSeparatedByString:@","] mutableCopy];
		if ([components.lastObject integerValue] > 0) {
			components[components.count-1] = [@([components.lastObject integerValue] - 1) stringValue];
			result = [components componentsJoinedByString:@","];
		}
	}
	
	if (!result) {
		// ultimate fallback is the iPhone6,1 - we just assume that new phones can manage the same quality than the 5s (which might be too optimistic)
		result = @"iPhone6,1";
	}
	
	return result;
}

- (PODDeviceSettings *)deviceSettingsForMode:(NSString *)aModeNameString {
	NSString *platformString = [self.class TCM_platformString];
	NSString *fallbackPlatformString = platformString;
	NSDictionary *perDeviceSettings = nil;
	while (perDeviceSettings == nil && fallbackPlatformString) {
		perDeviceSettings = self.deviceSettings[fallbackPlatformString];
		if (!perDeviceSettings) {
			fallbackPlatformString = [self fallbackPlatformStringForString:fallbackPlatformString];
		}
	}
	if (![fallbackPlatformString isEqualToString:platformString]) {
		//NSLog(@"%s no per device settings found for: %@ falling back to %@",__FUNCTION__,platformString, fallbackPlatformString);
		// write it into the settings to speedup lookup in the future
		self.deviceSettings[platformString] = perDeviceSettings;
	}
	PODDeviceSettings *result = perDeviceSettings[aModeNameString];
	if (!result) {
		// if we don't have settings for the mode chosen, fallback to the photo mode
		result = perDeviceSettings[kPODDeviceSettingsModePhoto];
	}
	return result;
}

- (void)loadSettings {
	// load the per device settings from a json file
	NSURL *settingsDirectory = [[NSBundle mainBundle] URLForResource:@"DeviceSettings" withExtension:@""];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	for (NSURL *fileURL in [fileManager enumeratorAtURL:settingsDirectory includingPropertiesForKeys:nil options:0 errorHandler:NULL]) {
		if ([[fileURL pathExtension] isEqualToString:@"json"]) {
			NSString *deviceString = [[[fileURL pathComponents] lastObject] stringByDeletingPathExtension];
			// lazily initialize subdicitionary if needed
			NSMutableDictionary *perDeviceSettings = ({
				NSMutableDictionary *settings = self.deviceSettings[deviceString];
				if (!settings) {
					settings = [NSMutableDictionary new];
					self.deviceSettings[deviceString] = settings;
				}
				settings;
			});
			//NSLog(@"%s found json file %@  -- %@",__FUNCTION__,fileURL, deviceString);
			NSError *error = nil;
			NSData *jsonData = [NSData dataWithContentsOfURL:fileURL options:0 error:&error];
			if (!jsonData) {
				NSLog(@"%s error reading %@ -- %@",__FUNCTION__,fileURL, jsonData);
			} else {
				NSMutableDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers | NSJSONReadingMutableLeaves error:&error];
				if (!jsonDict) {
					NSLog(@"%s error parsing json: %@ -- %@",__FUNCTION__,fileURL, error);
					NSAssert(NO, @"Error parsing the config json");
				} else {
					// parse it
					//NSLog(@"%s %@",__FUNCTION__,jsonDict);
					for (NSString *modeName in jsonDict) {
						PODDeviceSettings *settings = [PODDeviceSettings deviceSettingsFromJSONRepresentation:jsonDict[modeName] modeName:modeName deviceString:deviceString];
						if (settings) {
							perDeviceSettings[settings.modeName] = settings;
							//NSLog(@"%s settings loaded: %@",__FUNCTION__, settings);
						}
					}
				}
			}
		}
	}
}

@end
