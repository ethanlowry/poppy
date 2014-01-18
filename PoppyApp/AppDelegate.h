//
//  AppDelegate.h
//  PoppyApp
//
//  Created by Ethan Lowry on 10/1/13.
//  Copyright (c) 2013 Ethan Lowry. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIApplication <UIApplicationDelegate>

@property (strong, nonatomic) NSMutableArray *recentImageArray;
@property (strong, nonatomic) NSMutableArray *topImageArray;
@property (strong, nonatomic) NSCache *imageCache;
@property (strong, nonatomic) NSTimer *screenTimer;
@property (nonatomic) BOOL isConnected;
@property (strong, nonatomic) UIWindow *window;
-(void)loadImageArrays;

@end
