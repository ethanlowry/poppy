//
//  PODAssetsManager.h
//  Poppy
//
//  Created by Dominik Wagner on 14.02.14.
//  Copyright (c) 2014 Hack Things LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface PODAssetsManager : NSObject

+ (instancetype)assetsManager;

@property (strong, nonatomic) ALAssetsLibrary *assetsLibrary;
- (void)ensuredAssetsAlbumNamed:(NSString *)aName completion:(void(^)(ALAssetsGroup *, NSError *))aGroupCompletion;
- (void)addAssetURL:(NSURL *)anAssetURL toGroup:(ALAssetsGroup *)anAssetsGroup completion:(void(^)(ALAsset *,NSError *))aCompletion;
- (void)assetForLatestRawImageCompletion:(void(^)(ALAsset *foundAsset))completion;

@end

