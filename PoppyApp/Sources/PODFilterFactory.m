//
//  PODFilterFactory.m
//  Poppy
//
//  Created by Dominik Wagner on 19.12.13.
//  Copyright (c) 2014 Hack Things LLC. All rights reserved.
//

#import "PODFilterFactory.h"

#import "PODDeviceSettingsManager.h"

@implementation PODFilterFactory

+ (CGSize)maxOpenGLTextureSize {
	static CGSize s_maxDimension = {};
	if (CGSizeEqualToSize(s_maxDimension, CGSizeZero)) {
		int maxTextureSize;
		glGetIntegerv(GL_MAX_TEXTURE_SIZE, &maxTextureSize);
		s_maxDimension = CGSizeMake(maxTextureSize, maxTextureSize);
	}
	return s_maxDimension;
}

+ (CIFilter *)keystoneFilterWithImage:(CIImage *)inputImage factor:(CGFloat)aFactor shift:(CGFloat)aShift longEdge:(CGRectEdge)anEdge {
	// TO DO: deal with horizontal offset
	CGRect extentRect = inputImage.extent;
	CIVector *topLeft = [CIVector vectorWithCGPoint:CGPointMake(CGRectGetMinX(extentRect), CGRectGetMaxY(extentRect))];
	CIVector *topRight = [CIVector vectorWithCGPoint:CGPointMake(CGRectGetMaxX(extentRect), CGRectGetMaxY(extentRect))];
	CIVector *bottomLeft = [CIVector vectorWithCGPoint:CGPointMake(CGRectGetMinX(extentRect), CGRectGetMinY(extentRect))];
	CIVector *bottomRight = [CIVector vectorWithCGPoint:CGPointMake(CGRectGetMaxX(extentRect), CGRectGetMinY(extentRect))];
	
	CGFloat inset = (aFactor + .367 * aShift ) * CGRectGetHeight(extentRect);
    CGFloat squeeze = CGRectGetWidth(extentRect) * aShift;
    NSLog(@"SHIFT: %f", aShift);
    NSLog(@"SQUEEZE: %f", squeeze);
	
    NSLog(@"pre width: %f", bottomRight.X - bottomLeft.X);
    
	if (anEdge == CGRectMinXEdge) {
        NSLog(@"LEFT");
        bottomLeft = [CIVector vectorWithX:bottomLeft.X + squeeze Y:bottomLeft.Y + inset];
        topLeft = [CIVector vectorWithX:topLeft.X + squeeze Y:topLeft.Y - inset];
	} else if (anEdge == CGRectMaxXEdge) {
        NSLog(@"RIGHT");
        bottomRight = [CIVector vectorWithX:bottomRight.X - squeeze Y:bottomRight.Y + inset];
        topRight = [CIVector vectorWithX:topRight.X - squeeze Y:topRight.Y - inset];
	}
    
    NSLog(@"post width: %f", bottomRight.X - bottomLeft.X);
	
	CIFilter *result = [CIFilter filterWithName:@"CIPerspectiveTransform" keysAndValues:kCIInputImageKey,inputImage,
						@"inputTopLeft"    ,topLeft,
						@"inputTopRight"   ,topRight,
						@"inputBottomLeft" ,bottomLeft,
						@"inputBottomRight",bottomRight,
						nil];
	return result;
}

+ (CIFilter *)extentCropFilterWithImage:(CIImage *)anImage {
	CIFilter *result = [CIFilter filterWithName:@"CICrop" keysAndValues:kCIInputImageKey,anImage, @"inputRectangle",[CIVector vectorWithCGRect:anImage.extent],nil];
	return result;
}

/*!
	@return an NSArray of CIFilters - you have to set the @"inputImage" on the first filter - and you can use the .outputImage from the last as final output - or use every step in between for debugging purposes
 */

+ (NSArray *)filterChainWithSettings:(PODFilterChainSettings *)aSetting inputImage:(CIImage *)inputImage {
	NSMutableArray *filterChain = [NSMutableArray new];

	CGRect fullExtent = inputImage.extent;
	
	// step one - move the image so it is centered
	CIFilter *filter = nil;
	CGPoint centerPoint = [PODFilterChainSettings absolutePointForNormalizedPoint:aSetting.calibratedCenter imageExtent:fullExtent];
	filter = [CIFilter filterWithName:@"CIAffineTransform" keysAndValues:kCIInputImageKey,inputImage,@"inputTransform",[NSValue valueWithCGAffineTransform:CGAffineTransformMakeTranslation(-centerPoint.x, -centerPoint.y)], nil];
	[filterChain addObject:filter];
	
	// rotate
	filter = [CIFilter filterWithName:@"CIAffineTransform" keysAndValues:kCIInputImageKey,[filter outputImage],
			  @"inputTransform",[NSValue valueWithCGAffineTransform:CGAffineTransformMakeRotation(TCMRadiansFromDegrees(aSetting.calibratedRotation))],nil];
	[filterChain addObject:filter];
	
    // using shiftoffset to compensate for the horizontal shift in the keystoning
    CGFloat shiftOffset = [PODDeviceSettingsManager deviceSettingsManager].calibrationCenterOffset.x; // 1 for 5, .2 for 5s
    shiftOffset = shiftOffset * (ABS(shiftOffset)) * 25;
    NSLog(@"shiftOffset: %f", shiftOffset);
	CGRect cropRect = CGRectZero;
	cropRect.size = [PODFilterChainSettings absoluteSizeForNormalizedSize:aSetting.sideCropSize imageExtent:fullExtent];
	cropRect.origin.y = round(CGRectGetHeight(cropRect) / -2.0);
	cropRect.origin.x = round(CGRectGetWidth(cropRect) / -2.0);
    
    CGFloat stretch = cropRect.size.width * shiftOffset;
    NSLog(@"STRETCH: %f", stretch);
    
	CGRect leftCropRect = CGRectOffset(cropRect, -[PODFilterChainSettings absoluteWidthForNormalizedWidth:aSetting.leftDistance imageExtent:fullExtent] ,0);
    
    leftCropRect.origin.x = leftCropRect.origin.x + stretch;
    leftCropRect.size.width = leftCropRect.size.width - stretch;

    NSLog(@"left width: %f", leftCropRect.size.width);
	CIFilter *leftCropFilter = [CIFilter filterWithName:@"CICrop" keysAndValues:kCIInputImageKey,filter.outputImage, @"inputRectangle",[CIVector vectorWithCGRect:leftCropRect],nil];
	[filterChain addObject:leftCropFilter];

	
	CGRect rightCropRect = CGRectOffset(cropRect,[PODFilterChainSettings absoluteWidthForNormalizedWidth:aSetting.rightDistance imageExtent:fullExtent],0);
    

    rightCropRect.size.width = rightCropRect.size.width + stretch;
    NSLog(@"Right width: %f",rightCropRect.size.width);
    
	CIFilter *rightCropFilter = [CIFilter filterWithName:@"CICrop" keysAndValues:kCIInputImageKey,filter.outputImage, @"inputRectangle",[CIVector vectorWithCGRect:rightCropRect],nil];
	[filterChain addObject:rightCropFilter];

	CGFloat keystoneFactor = aSetting.keystoneFactor;
	
    // TO DO: adjust the keystoneFactor based on the center shift
    
	CIFilter *leftKeystoneFilter = [self keystoneFilterWithImage:leftCropFilter.outputImage factor:keystoneFactor shift:-shiftOffset longEdge:CGRectMinXEdge];
	[filterChain addObject:leftKeystoneFilter];

	CIFilter *rightKeystoneFilter = [self keystoneFilterWithImage:rightCropFilter.outputImage factor:keystoneFactor shift:shiftOffset longEdge:CGRectMaxXEdge];
	[filterChain addObject:rightKeystoneFilter];

	
	// compose together
	CGRect leftExtent  = leftKeystoneFilter.outputImage.extent;
	CGRect rightExtent = rightKeystoneFilter.outputImage.extent;
	CGRect bigImageRect = CGRectMake(0,0,CGRectGetWidth(leftExtent) * 2, CGRectGetHeight(leftExtent));
	
	CIImage *blackImage = [CIFilter filterWithName:@"CICrop" keysAndValues:kCIInputImageKey,[CIFilter filterWithName:@"CIConstantColorGenerator" keysAndValues:@"inputColor",[CIColor colorWithRed:0 green:0 blue:0], nil].outputImage, @"inputRectangle",[CIVector vectorWithCGRect:bigImageRect],nil].outputImage;
	CIFilter *leftTransform = [CIFilter filterWithName:@"CIAffineTransform" keysAndValues:kCIInputImageKey,leftKeystoneFilter.outputImage,kCIInputTransformKey,[NSValue valueWithCGAffineTransform:CGAffineTransformMakeTranslation(-leftExtent.origin.x, -leftExtent.origin.y)], nil];
	CIFilter *rightTransform = [CIFilter filterWithName:@"CIAffineTransform" keysAndValues:kCIInputImageKey,rightKeystoneFilter.outputImage,kCIInputTransformKey,[NSValue valueWithCGAffineTransform:CGAffineTransformMakeTranslation(-rightExtent.origin.x + leftExtent.size.width, -leftExtent.origin.y)], nil];
	
	CIFilter *composed = [CIFilter filterWithName:@"CISourceAtopCompositing" keysAndValues:kCIInputImageKey,leftTransform.outputImage, @"inputBackgroundImage",blackImage,nil];
	[filterChain addObject:composed];
	CIFilter *composed2 = [CIFilter filterWithName:@"CISourceAtopCompositing" keysAndValues:kCIInputImageKey,rightTransform.outputImage, @"inputBackgroundImage",composed.outputImage,nil];
	[filterChain addObject:composed2];
	
	CGFloat cropHeight = [PODFilterChainSettings absoluteHeightForNormalizedHeight:aSetting.cropHeight imageExtent:fullExtent];
	CIFilter *finalCrop = [CIFilter filterWithName:@"CICrop" keysAndValues:kCIInputImageKey,composed2.outputImage, @"inputRectangle",[CIVector vectorWithCGRect:CGRectIntegral(CGRectInset(bigImageRect, 0, CGRectGetHeight(bigImageRect) - cropHeight))],nil];
	[filterChain addObject:finalCrop];
	
	
	return [filterChain copy];
}

+ (CIImage *)scaleImage:(CIImage *)anImage toFitInSize:(CGSize)aTargetSize downscaleOnly:(BOOL)shouldOnlyDownscale {
	CGRect imageExtent = anImage.extent;
	CGRect targetRect = CGRectZero;
	targetRect.size = aTargetSize;
	
	if (shouldOnlyDownscale && imageExtent.size.width <= aTargetSize.width && imageExtent.size.height <= aTargetSize.height) {
		return anImage;
	}
	
	CGRect croppedExtent = imageExtent;
	croppedExtent.size.height = ceil(targetRect.size.height / targetRect.size.width * croppedExtent.size.width);
	croppedExtent.origin.y += ceil((CGRectGetHeight(imageExtent) - CGRectGetHeight(croppedExtent)) / 2.0);
	
	CIFilter *crop = [CIFilter filterWithName:@"CICrop" keysAndValues:
					  kCIInputImageKey,anImage,
					   @"inputRectangle",[CIVector vectorWithCGRect:croppedExtent],nil];
	
	CGFloat scaleFactor = targetRect.size.width/croppedExtent.size.width;
	
//	CIFilter *scaleFilter = [CIFilter filterWithName:@"CILanczosScaleTransform" keysAndValues:
//							 kCIInputImageKey, crop.outputImage,
//							 kCIInputScaleKey, @(targetRect.size.width/croppedExtent.size.width),
//							 nil];
	CGAffineTransform transform = CGAffineTransformConcat(CGAffineTransformMakeTranslation(-croppedExtent.origin.x, -croppedExtent.origin.y),CGAffineTransformMakeScale(scaleFactor,scaleFactor));
	
	CIFilter *scaleFilter = [CIFilter filterWithName:@"CIAffineTransform" keysAndValues:
							 kCIInputImageKey, crop.outputImage,
							 kCIInputTransformKey, [NSValue valueWithCGAffineTransform:transform],
							 nil];
	
	CIImage *result = scaleFilter.outputImage;
	
	return result;
}



@end
