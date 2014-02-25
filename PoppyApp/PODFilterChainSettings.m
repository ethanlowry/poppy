//
//  PODFilterChainSettings.m
//  Poppy
//
//  Created by Dominik Wagner on 09.02.14.
//  Copyright (c) 2014 Hack Things LLC. All rights reserved.
//

#import "PODFilterChainSettings.h"
#import "PODDeviceSettingsManager.h"

NSString * const kPODFilterRotationKey  = @"rotation";
NSString * const kPODFilterCenterKey    = @"center";
NSString * const kPODFilterKeystoneFactorKey = @"keystoneFactor";
NSString * const kPODFilterLeftRightCropSizeKey = @"sideCropSize";
NSString * const kPODFilterFinalCropHeightKey = @"cropHeight";
NSString * const kPODFilterLeftCenterDistanceKey  = @"leftDistance";
NSString * const kPODFilterRightCenterDistanceKey = @"rightDistance";

@implementation PODFilterChainSettings

@dynamic calibratedCenter;

+ (instancetype)filterChainSettingsWithJSONRepresentation:(NSDictionary *)aJSONRepresentation {
	PODFilterChainSettings *result = [[PODFilterChainSettings alloc] init];
	result.rotation          = [aJSONRepresentation[kPODFilterRotationKey] doubleValue];
	result.center            = CGPointFromString(aJSONRepresentation[kPODFilterCenterKey]);
	result.leftDistance      = [aJSONRepresentation[kPODFilterLeftCenterDistanceKey]  doubleValue];
	result.rightDistance     = [aJSONRepresentation[kPODFilterRightCenterDistanceKey] doubleValue];
	result.keystoneFactor    = [aJSONRepresentation[kPODFilterKeystoneFactorKey] doubleValue];
	result.sideCropSize      = CGSizeFromString(aJSONRepresentation[kPODFilterLeftRightCropSizeKey]);
	result.cropHeight        = [aJSONRepresentation[kPODFilterFinalCropHeightKey] doubleValue];
	return result;
}

- (NSString *)description {
	NSMutableArray *result = [NSMutableArray new];
	for (NSString *string in @[kPODFilterRotationKey, kPODFilterCenterKey, kPODFilterKeystoneFactorKey, kPODFilterLeftRightCropSizeKey, kPODFilterFinalCropHeightKey, kPODFilterFinalCropHeightKey, kPODFilterLeftCenterDistanceKey, kPODFilterRightCenterDistanceKey]) {
		[result addObject:[NSString stringWithFormat:@"fc-%@: %@",string, [[self valueForKey:string] description]]];
	}
	return [result componentsJoinedByString:@"; "];
}

- (CGPoint)calibratedCenter {
	CGPoint result = TCMPointAdd(self.center,[[PODDeviceSettingsManager deviceSettingsManager] calibrationCenterOffset]);
	return result;
}

- (CGFloat)calibratedRotation {
	CGFloat result = self.rotation + [[PODDeviceSettingsManager deviceSettingsManager] rotationOffsetInDegrees];
	return result;
}

- (CGRect)leftCropRectForImageExtent:(CGRect)anImageExtent {
	CGRect cropRect = CGRectZero;
	cropRect.size = [PODFilterChainSettings absoluteSizeForNormalizedSize:self.sideCropSize imageExtent:anImageExtent];
	cropRect.origin = [PODFilterChainSettings absolutePointForNormalizedPoint:self.calibratedCenter imageExtent:anImageExtent];
	cropRect.origin.y -= round(CGRectGetHeight(cropRect) / 2.0);
	cropRect.origin.x -= round(CGRectGetWidth(cropRect) / 2.0);
	cropRect = CGRectOffset(cropRect, -[PODFilterChainSettings absoluteWidthForNormalizedWidth:self.leftDistance imageExtent:anImageExtent] ,0);
	return cropRect;
}

- (CGRect)rightCropRectForImageExtent:(CGRect)anImageExtent {
	CGRect cropRect = CGRectZero;
	cropRect.size = [PODFilterChainSettings absoluteSizeForNormalizedSize:self.sideCropSize imageExtent:anImageExtent];
	cropRect.origin = [PODFilterChainSettings absolutePointForNormalizedPoint:self.calibratedCenter imageExtent:anImageExtent];
	cropRect.origin.y -= round(CGRectGetHeight(cropRect) / 2.0);
	cropRect.origin.x -= round(CGRectGetWidth(cropRect) / 2.0);
	cropRect = CGRectOffset(cropRect, [PODFilterChainSettings absoluteWidthForNormalizedWidth:self.rightDistance imageExtent:anImageExtent], 0);
	return cropRect;
}


#pragma mark - normalization methods

+ (CGPoint)absolutePointForNormalizedPoint:(CGPoint)aPoint imageExtent:(CGRect)anImageExtent {
	CGPoint result = anImageExtent.origin;
	result.x += round(anImageExtent.size.width * aPoint.x);
	result.y += round(anImageExtent.size.height * aPoint.y);
	return result;
}

+ (CGSize)absoluteSizeForNormalizedSize:(CGSize)aSize imageExtent:(CGRect)anImageExtent {
	CGSize result = CGSizeZero;
	result.width = round(aSize.width * anImageExtent.size.width);
	result.height = round(aSize.height * anImageExtent.size.height);
	return result;
}

+ (CGFloat)absoluteWidthForNormalizedWidth:(CGFloat)aWidth imageExtent:(CGRect)anImageExtent {
	CGFloat result = round(aWidth * anImageExtent.size.width);
	return result;
}

+ (CGFloat)absoluteHeightForNormalizedHeight:(CGFloat)aHeight imageExtent:(CGRect)anImageExtent {
	CGFloat result = round(aHeight * anImageExtent.size.height);
	return result;
}


@end
