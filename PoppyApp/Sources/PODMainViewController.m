//
//  PODMainViewController.m
//  Poppy Dome
//
//  Created by Dominik Wagner on 09.12.13.
//  Copyright (c) 2013 Dominik Wagner. All rights reserved.
//

#import "PODMainViewController.h"
@class PODMainViewController;
#import "PODAppDelegate.h"
#import "PODShowContentViewController.h"
#import "PODRecordViewController.h"
#import "PODTestFilterChainViewController.h"
#import "PODCaptureDebugViewController.h"
#import "PODCalibrateViewController.h"
#import "PODAssetsManager.h"

#import <AssetsLibrary/AssetsLibrary.h>

static NSString * const s_poppyAlbumName = @"Poppy";

@interface PODMainViewController ()
@end

#define CREATE_AND_POPULATE_ALBUM

@implementation PODMainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)showViewerWithAssetGroup:(ALAssetsGroup *)anAssetsGroup {
	PODShowContentViewController *contentViewController = [[PODShowContentViewController alloc] initWithNibName:nil bundle:nil];
	contentViewController.assetsGroup = anAssetsGroup;
	[self presentViewController:contentViewController animated:YES completion:NULL];
}

- (void)populateAlbumWithStockPictures:(ALAssetsGroup *)anAlbum completion:(dispatch_block_t)aCompletion {
	__weak ALAssetsLibrary *assetsLibrary = [[PODAssetsManager assetsManager] assetsLibrary];
	NSMutableArray *imagePathsToAdd = [NSMutableArray new];
	NSURL *pathURL = [[NSBundle mainBundle] URLForResource:@"StockImages" withExtension:@""];
	for (NSURL *fileURL in [[NSFileManager defaultManager] enumeratorAtURL:pathURL includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsSubdirectoryDescendants errorHandler:NULL]) {
		[imagePathsToAdd addObject:fileURL];
	}
	
	__weak __block dispatch_block_t weakRecursionBlock = nil;
	dispatch_block_t recursionBlock = ^{
		__strong dispatch_block_t strongRecursionBlock = weakRecursionBlock;
		if (imagePathsToAdd.count == 0) {
			// finish
			if (aCompletion) aCompletion();
		} else {
			NSURL *imageURL = [imagePathsToAdd firstObject];
			[imagePathsToAdd removeObjectAtIndex:0];
			NSError *dataError = nil;
			NSData *imageData = [NSData dataWithContentsOfURL:imageURL options:NSDataReadingMappedAlways error:&dataError];
			if (imageData) {
				[assetsLibrary writeImageDataToSavedPhotosAlbum:imageData
													   metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
														   if (assetURL) {
															   [assetsLibrary assetForURL:assetURL resultBlock:^(ALAsset *asset) {
																   [anAlbum addAsset:asset];
																   strongRecursionBlock();
															   } failureBlock:^(NSError *error) {
																   NSLog(@"%s could not add asset to group %@",__FUNCTION__,error);
																   strongRecursionBlock();
															   }];
														   }
													   }];
			} else {
				NSLog(@"%s could not read data from URL: %@ - %@",__FUNCTION__,imageURL,dataError);
				strongRecursionBlock();
			}
		}
	};
	weakRecursionBlock = recursionBlock;
	recursionBlock();
}

- (void)createAndPopulateAlbumWithStockPicturesAndRerunChooseImage {
	__weak ALAssetsLibrary *assetsLibrary = [[PODAssetsManager assetsManager] assetsLibrary];
	[assetsLibrary addAssetsGroupAlbumWithName:s_poppyAlbumName resultBlock:^(ALAssetsGroup *anAssetGroup) {
		dispatch_block_t completion = ^{
			[self chooseImage];
		};
		if (!anAssetGroup) {
			// it probably did already exist - so lets get it
			[assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAlbum usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
				if ([[group valueForProperty:ALAssetsGroupPropertyName] isEqualToString:s_poppyAlbumName]) {
					*stop = YES; // also causes the last call to this block with group = nil - so we need the block variable to keep track
					[self populateAlbumWithStockPictures:group completion:completion];
				}
			} failureBlock:^(NSError *error) {
				NSLog(@"%s could not find assets group named '%@' %@",__FUNCTION__,s_poppyAlbumName,error);
			}];
		} else {
			[self populateAlbumWithStockPictures:anAssetGroup completion:completion];
		};
		
	} failureBlock:^(NSError *error) {
		NSLog(@"%s could not add asset group named '%@' %@",__FUNCTION__,s_poppyAlbumName,error);
	}];
}

- (void)chooseImage {
	NSString *albumName = s_poppyAlbumName;
	__block ALAssetsGroup *foundAlbum = nil;;
	[[[PODAssetsManager assetsManager] assetsLibrary] enumerateGroupsWithTypes:ALAssetsGroupAlbum
usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
	if ([[group valueForProperty:ALAssetsGroupPropertyName] isEqualToString:albumName]) {
		NSLog(@"found album %@", [group valueForProperty:ALAssetsGroupPropertyName]);
		dispatch_async(dispatch_get_main_queue(), ^{
			[self showViewerWithAssetGroup:group];
		});
		foundAlbum = group;
		*stop = YES; // also causes the last call to this block with group = nil - so we need the block variable to keep track
	}
	if (group == nil) { // finished enumerating, since we didn't stop, we didn't find any images
#ifdef CREATE_AND_POPULATE_ALBUM
		NSLog(@"%s %@",__FUNCTION__,foundAlbum);
		if ([foundAlbum numberOfAssets] == 0) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[self createAndPopulateAlbumWithStockPicturesAndRerunChooseImage];
			});
		}
#endif
	}
}
	failureBlock:^(NSError* error) {
		NSLog(@"failed to enumerate albums:\nError: %@", [error localizedDescription]);
	}];
}

- (IBAction)showCalibrateAction:(id)sender {
	PODCalibrateViewController *vc = [[PODCalibrateViewController alloc] initWithNibName:nil bundle:nil];
	[self presentViewController:vc animated:NO completion:NULL];
}

- (IBAction)showDebugAction:(id)sender {
	PODTestFilterChainViewController *vc = [[PODTestFilterChainViewController alloc] initWithNibName:nil bundle:nil];
	[self presentViewController:vc animated:YES completion:NULL];
}

- (IBAction)showCaptureDebugAction:(id)sender {
	PODCaptureDebugViewController *vc = [[PODCaptureDebugViewController alloc] initWithNibName:nil bundle:nil];
	[self presentViewController:vc animated:YES completion:NULL];
}

- (IBAction)viewImageAction {
	[self chooseImage];
}

- (IBAction)viewMoviesAction {
	PODShowContentViewController *contentViewController = [[PODShowContentViewController alloc] initWithNibName:nil bundle:nil];
	contentViewController.contentDirectoryURL = [NSURL fileURLWithPath:NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject];
	[self presentViewController:contentViewController animated:YES completion:NULL];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
	return UIStatusBarStyleLightContent;
}

- (IBAction)showRecordViewAction:(id)sender {
	PODRecordViewController *recordViewController = [[PODRecordViewController alloc] initWithNibName:nil bundle:nil];
	[self presentViewController:recordViewController animated:YES completion:NULL];
}
@end
