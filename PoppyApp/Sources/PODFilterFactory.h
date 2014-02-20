//
//  PODFilterFactory.h
//  Poppy Dome
//
//  Created by Dominik Wagner on 19.12.13.
//  Copyright (c) 2013 Dominik Wagner. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CoreImage/CoreImage.h>

#import "PODFilterChainSettings.h"

@interface PODFilterFactory : NSObject

+ (CGSize)maxOpenGLTextureSize;

+ (NSArray *)filterChainWithSettings:(PODFilterChainSettings *)aSetting inputImage:(CIImage *)inputImage;

+ (CIImage *)scaleImage:(CIImage *)anImage toFitInSize:(CGSize)aTargetSize downscaleOnly:(BOOL)shouldOnlyDownscale;

@end
