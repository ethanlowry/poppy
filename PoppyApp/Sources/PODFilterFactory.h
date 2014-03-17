//
//  PODFilterFactory.h
//  Poppy
//
//  Created by Dominik Wagner on 19.12.13.
//  Copyright (c) 2014 Hack Things LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CoreImage/CoreImage.h>

#import "PODFilterChainSettings.h"

@interface PODFilterFactory : NSObject

+ (CGSize)maxOpenGLTextureSize;

+ (NSArray *)filterChainWithSettings:(PODFilterChainSettings *)aSetting inputImage:(CIImage *)inputImage;

+ (CIImage *)scaleImage:(CIImage *)anImage toFitInSize:(CGSize)aTargetSize downscaleOnly:(BOOL)shouldOnlyDownscale;

@end
