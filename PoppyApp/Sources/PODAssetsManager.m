//
//  PODAssetsManager.m
//  Poppy
//
//  Created by Dominik Wagner on 14.02.14.
//  Copyright (c) 2014 Hack Things LLC. All rights reserved.
//

#import "PODAssetsManager.h"
#import "AppDelegate.h"

@implementation PODAssetsManager

+ (instancetype)assetsManager {
	static PODAssetsManager *s_sharedInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		s_sharedInstance = [self new];
	});
	return s_sharedInstance;
}

- (ALAssetsLibrary *)assetsLibrary {
	if (!_assetsLibrary) {
		_assetsLibrary  = [[ALAssetsLibrary alloc] init];
	}
	return _assetsLibrary;
}

- (void)assetForLatestRawImageCompletion:(void(^)(ALAsset *foundAsset))completion {
	NSString *albumName = @"Poppy Raw";
	[self.assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAlbum
									  usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
										  if ([[group valueForProperty:ALAssetsGroupPropertyName] isEqualToString:albumName]) {
											  //NSLog(@"found album %@", [group valueForProperty:ALAssetsGroupPropertyName]);
											  if (group.numberOfAssets > 0) {
												  NSIndexSet *lastItemSet = [NSIndexSet indexSetWithIndex:group.numberOfAssets-1];
												  [group enumerateAssetsAtIndexes:lastItemSet options:0 usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
													  if (result) {
														  completion(result);
													  }
												  }];
											  }
											  *stop = YES; // also causes the last call to this block with group = nil - so we need the block variable to keep track
										  }
										  if (group == nil) { // finished enumerating, since we didn't stop, we didn't find any images
										  }
									  }
									failureBlock:^(NSError* error) {
										NSLog(@"failed to enumerate albums:\nError: %@", [error localizedDescription]);
									}];
}

- (void)addAssetURL:(NSURL *)anAssetURL toGroup:(ALAssetsGroup *)anAssetsGroup completion:(void(^)(ALAsset *,NSError *))aCompletion {
	__typeof__(aCompletion) safeCompletion = ^(ALAsset *anAsset,NSError *anError) {
		if (aCompletion) {
			aCompletion(anAsset,anError);
		}
	};
	ALAssetsLibrary *library = self.assetsLibrary;
	if (anAssetURL && anAssetsGroup) {
		[library assetForURL:anAssetURL
				 resultBlock:^(ALAsset *asset) {
					 // assign the photo to the album
					 [anAssetsGroup addAsset:asset];
					 //NSLog(@"Added %@ to %@", [[asset defaultRepresentation] filename], [anAssetsGroup valueForProperty:ALAssetsGroupPropertyName]);
					 //NSLog(@"SIZE: %f : %f", [asset defaultRepresentation].dimensions.height, [asset defaultRepresentation].dimensions.width);
					 safeCompletion(asset,nil);
				 }
				failureBlock:^(NSError* error) {
					safeCompletion(nil, error);
				}];
	} else {
		safeCompletion(nil,[NSError errorWithDomain:@"POD" code:10 userInfo:nil]);
	}
}

- (void)addAssetsGroupAlbumWithName:(NSString *)aName completion:(void(^)(ALAssetsGroup *, NSError *))aGroupCompletion {
	ALAssetsLibrary *library = self.assetsLibrary;
	
	[library addAssetsGroupAlbumWithName:aName
							 resultBlock:^(ALAssetsGroup *group) {
								 aGroupCompletion(group,nil);
							 }
							failureBlock:^(NSError *error) {
								NSLog(@"error adding album");
								aGroupCompletion(nil,error);
							}];
	
}

- (void)ensuredAssetsAlbumNamed:(NSString *)aName completion:(void(^)(ALAssetsGroup *, NSError *))aGroupCompletion {
    AppDelegate *poppyAppDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (poppyAppDelegate.assetsGroup) {
        aGroupCompletion(poppyAppDelegate.assetsGroup, nil);
    } else {    
        ALAssetsLibrary *library = self.assetsLibrary;
        __block BOOL didFindGroup = NO;
        [library enumerateGroupsWithTypes:ALAssetsGroupAlbum
                               usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                                   if ([[group valueForProperty:ALAssetsGroupPropertyName] isEqualToString:aName]) {
                                       //NSLog(@"found album %@", [group valueForProperty:ALAssetsGroupPropertyName]);
                                       didFindGroup = YES;
                                       aGroupCompletion(group, nil);
                                       *stop = YES;
                                   }
                                   if (group == nil && !didFindGroup) {
                                       [self addAssetsGroupAlbumWithName:aName completion:aGroupCompletion];
                                   }
                               }
                             failureBlock:^(NSError *error) {
                                 NSLog(@"failed to enumerate albums:\nError: %@", [error localizedDescription]);
                                 aGroupCompletion(nil,error);
                             }];
    }
}


@end
