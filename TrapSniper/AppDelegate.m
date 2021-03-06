//
//  AppDelegate.m
//  TrapSniper
//
//  Created by Hai Phung on 11/6/14.
//  Copyright (c) 2014 Hai Phung. All rights reserved.
//

#import <Parse/Parse.h>
#import <CoreLocation/CoreLocation.h>
#import "AppDelegate.h"

@interface AppDelegate ()

@property (nonatomic) CLLocationManager *locationManager;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Setup Parse.
    [Parse setApplicationId:@"LR2JX8yTOQVFWTKmcX4fMBjqbFpqIhj8vqcGBmHr" clientKey:@"ef2L9umUUKJziwktdFeJGfavCvZu71C6BdeBMYBD"];
    
    // Register for local notifications.
    if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]){
        [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound categories:nil]];
    }
    
    [self configureViews];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Before the application terminates, purge all monitored regions.
    self.locationManager = [[CLLocationManager alloc] init];
    [self.locationManager.monitoredRegions enumerateObjectsUsingBlock:^(CLRegion *region, BOOL *stop) {
        [self.locationManager performSelector:@selector(stopMonitoringForRegion:) withObject:region afterDelay:0.1];
    }];
    
    [self.locationManager stopUpdatingLocation];
    [self.locationManager stopMonitoringSignificantLocationChanges];
}

-(void)configureViews {
    [self.window setTintColor:[UIColor colorWithRed:177.0/255.0 green:29.0/255.0 blue:44.0/255.0 alpha:1.0]];
    [[UINavigationBar appearance] setBackgroundImage:[[UIImage alloc] init] forBarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setShadowImage:[[UIImage alloc] init]];
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:177.0/255.0 green:29.0/255.0 blue:44.0/255.0 alpha:1.0]];
    [[UINavigationBar appearance] setTitleTextAttributes: @{ NSForegroundColorAttributeName:[UIColor whiteColor] }];
}

@end
