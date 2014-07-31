//
//  rcfAppDelegate.h
//  Refuge Christian Fellowship
//
//  Created by Micah Gemmell on 5/20/14.
//  Copyright (c) 2014 RefugeCF. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface rcfAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (copy) void (^backgroundURLSessionCompletionHandler)();

@property (strong, nonatomic) AVPlayer *audioPlayer;
//rcfAppDelegate *ad = (rcfAppDelegate *)[[UIApplication sharedApplication] delegate];

@end
