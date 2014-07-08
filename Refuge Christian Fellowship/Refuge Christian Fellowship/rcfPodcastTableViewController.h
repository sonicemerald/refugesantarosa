//
//  rcfPodcastTableViewController.h
//  Refuge Christian Fellowship
//
//  Created by Micah Gemmell on 5/20/14.
//  Copyright (c) 2014 RefugeCF. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface rcfPodcastTableViewController : UITableViewController <NSURLSessionDownloadDelegate>
@property (strong, nonatomic) NSURLSessionDownloadTask *backgroundTask;
@property (strong, nonatomic, readonly) NSURLSession *backgroundSession;
@property (strong, nonatomic) AVPlayer *audioPlayer;
@end