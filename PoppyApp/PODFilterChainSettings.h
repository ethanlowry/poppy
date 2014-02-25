//
//  PODFilterChainSettings.h
//  Poppy
//
//  Created by Dominik Wagner on 09.02.14.
//  Copyright (c) 2014 Hack Things LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


extern NSString * const kPODFilterRotationKey;
extern NSString * const kPODFilterCenterKey;
extern NSString * const kPODFilterKeystoneFactorKey;
extern NSString * const kPODFilterLeftRightCropSizeKey;
extern NSString * const kPODFilterFinalCropHeightKey;
extern NSString * const kPODFilterLeftCenterDistanceKey;
extern NSString * const kPODFilterRightCenterDistanceKey;

@interface PODFilterChainSettings : NSObject

+ (instancetype)filterChainSettingsWithJSONRepresentation:(NSDictionary *)aJSONRepresentation;

/** center is given in normalized coordinates (0,0) is top left, (1,1) is bottom right, (0.5,0.5) is the default center */
@property (nonatomic) CGPoint center;
@property (nonatomic, readonly) CGPoint calibratedCenter;
/** rotation is in degrees, clockwise **/
@property (nonatomic) CGFloat rotation; // in Degrees
@property (nonatomic) CGFloat calibratedRotation;
/** keystoneFactor is the length of the outer side in relation to the inner side of the crop rect trapeze */
@property (nonatomic) CGFloat keystoneFactor;

/** side crop size is also given in normalized values. e.g. (0.5,1) would be the complete left half of the screen and the max value for this**/
@property (nonatomic) CGSize sideCropSize;

/** distance is given in normalized x direction values. e.g. 0.25 would be a quarter of the screen width - it specifies the distance of the center of the crop rect from the center of the image */
@property (nonatomic) CGFloat rightDistance;
@property (nonatomic) CGFloat leftDistance;

/** crop height is the final cropHeight of the image - the last step of the filter crops top and bottom to get rid of the distorted areas */
@property (nonatomic) CGFloat cropHeight;

- (CGRect)leftCropRectForImageExtent:(CGRect)anImageExtent;
- (CGRect)rightCropRectForImageExtent:(CGRect)anImageExtent;

/** all values are rounded to full point sizes */
+ (CGPoint)absolutePointForNormalizedPoint:(CGPoint)aPoint imageExtent:(CGRect)anImageExtent;
+ (CGSize)absoluteSizeForNormalizedSize:(CGSize)aSize imageExtent:(CGRect)anImageExtent;
+ (CGFloat)absoluteWidthForNormalizedWidth:(CGFloat)aWidth imageExtent:(CGRect)anImageExtent;
+ (CGFloat)absoluteHeightForNormalizedHeight:(CGFloat)aHeight imageExtent:(CGRect)anImageExtent;

@end
