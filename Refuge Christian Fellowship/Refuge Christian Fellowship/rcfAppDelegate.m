//
//  rcfAppDelegate.m
//  Refuge Christian Fellowship
//
//  Created by Micah Gemmell on 5/20/14.
//  Copyright (c) 2014 RefugeCF. All rights reserved.
//

#import "rcfAppDelegate.h"

@implementation rcfAppDelegate

-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
    [[UINavigationBar appearance] setBarTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setTranslucent:NO];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:68.0/255.0f green:68.0/255.0f blue:68.0/255.0f alpha:1.0]}]; //title text tint is grey
    [[UINavigationBar appearance] setTintColor:[UIColor colorWithRed:48/255.0f green:113/255.0f blue:121/255.0f alpha:1.0f]]; //tint is teal

    
    [[UITabBar appearance] setBarTintColor:[UIColor whiteColor]];
    [[UITabBar appearance] setTranslucent:NO];

    //Selected Tab is teal
    [[UITabBar appearance] setTintColor:[UIColor colorWithRed:48/255.0f green:113/255.0f blue:121/255.0f alpha:1.0f]];
    
    
    
    [[UITabBarItem appearance] setTitleTextAttributes:
     @{NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue" size:10.0f],
       NSForegroundColorAttributeName : [UIColor colorWithRed:68/255.0f green:68/255.0f blue:68/255.0f alpha:1.0f], } forState:UIControlStateSelected];
    
    [[UITabBarItem appearance] setTitleTextAttributes:
     @{NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue" size:10.0f],
       NSForegroundColorAttributeName : [UIColor colorWithRed:68/255.0f green:68/255.0f blue:68/255.0f alpha:1.0f]
                                         , } forState:UIControlStateNormal];
    
    

    /*[[UITabBarItem appearance] setTitleTextAttributes:@{NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue-Bold" size:10.0f],
                                                        NSForegroundColorAttributeName : [UIColor colorWithRed:48/255.0f green:113/255.0f blue:121/255.0f alpha:1.0f]
                                                        } forState:UIControlStateNormal];
   */
    // Override point for customization after application launch.
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
//    __block UIBackgroundTaskIdentifier task = 0;
//    task=[application beginBackgroundTaskWithExpirationHandler:^{
//        NSLog(@"Expiration handler called %f",[application backgroundTimeRemaining]);
//        [application endBackgroundTask:task];
//        task=UIBackgroundTaskInvalid;
//    }];
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

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler
{
    self.backgroundURLSessionCompletionHandler = completionHandler;
}

@end
