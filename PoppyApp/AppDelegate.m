//
//  AppDelegate.m
//  PoppyApp
//
//  Created by Ethan Lowry on 10/1/13.
//  Copyright (c) 2013 Ethan Lowry. All rights reserved.
//

#import "AppDelegate.h"
#import "LiveViewController.h"
#import "CalibrationViewController.h"
#import "WelcomeViewController.h"
#import "HomeViewController.h"
#import "Flurry.h"


@implementation AppDelegate

@synthesize recentImageArray;
@synthesize topImageArray;
@synthesize imageCache;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{    
    [Flurry setCrashReportingEnabled:YES];
    [Flurry startSession:@"YOUR_API_KEY"];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
    self.window.backgroundColor = [UIColor blackColor];

    HomeViewController *hvc = [[HomeViewController alloc] initWithNibName:@"LiveView" bundle:nil];
    [self.window setRootViewController:hvc];
    [self.window makeKeyAndVisible];
    [self loadImageArrays];
    
    return YES;
}


- (void)loadImageArrays
{
    topImageArray = [[NSMutableArray alloc] init];
    recentImageArray = [[NSMutableArray alloc] init];
    imageCache = [[NSCache alloc] init];
    [imageCache setCountLimit:4];
    [self loadJSON:@"top"];
    [self loadJSON:@"recent"];
}

- (void) loadJSON:(NSString *)sort
{
    NSString *uuid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];;
    NSString *urlString = [NSString stringWithFormat:@"http://poppy3d.com/app/media_item/get.json?uuid=%@&sort=%@", uuid, sort];
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableArray *imageArray = ([sort isEqualToString:@"top"]) ? topImageArray : recentImageArray;

    NSURLRequest *request = [NSURLRequest requestWithURL:url
                                             cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                         timeoutInterval:30.0];
    // Get the data
    NSLog(@"url: %@", url);
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               // Now create an array from the JSON data
                               NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                               // Iterate through the array of dictionaries
                               NSLog(@"Array count: %d", jsonArray.count);
                               for (NSMutableDictionary *item in jsonArray) {
                                   [imageArray addObject:item];
                               }
                               [self getFirstImage:imageArray];
                           }];
}

- (void)getFirstImage:(NSMutableArray *)imageArray
{
    NSLog(@"GETTING FIRST IMAGE");
    NSOperationQueue *queue = [NSOperationQueue new];
    NSInvocationOperation *operation = [[NSInvocationOperation alloc]
                                        initWithTarget:self
                                        selector:@selector(loadImage:)
                                        object:imageArray];
    [queue addOperation:operation];
}

- (void)loadImage:(NSMutableArray *)imageArray
{
    NSLog(@"LOADING THE FIRST IMAGE");
    NSURL *imageURL = [NSURL URLWithString:imageArray[0][@"media_url"]];
    NSURL *url = imageURL;
    NSData *imageData = [[NSData alloc] initWithContentsOfURL:url];
    UIImage *image = [[UIImage alloc] initWithData:imageData];
    [imageCache setObject:image forKey:imageArray[0][@"_id"]];
    
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
