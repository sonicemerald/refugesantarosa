//
//  rcfPodcastDetailView.h
//  Refuge Christian Fellowship
//
//  Created by Micah Gemmell on 5/26/14.
//  Copyright (c) 2014 RefugeCF. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "OBSlider.h"
#import "rcfPodcast.h"

@interface rcfPodcastDetailView : UIViewController <AVAudioPlayerDelegate, AVAudioSessionDelegate>
@property (nonatomic) rcfPodcast *podcast;
@property (weak, nonatomic) IBOutlet UILabel *podcastTitle;
@property (weak, nonatomic) IBOutlet UILabel *podcastSubtitle;
@property (weak, nonatomic) IBOutlet UILabel *podcastDate;
@property (weak, nonatomic) IBOutlet UIWebView *podcastSummary;
@property (weak, nonatomic) IBOutlet OBSlider *playerSlider;
@property (weak, nonatomic) IBOutlet UILabel *elapsedTime;
@property (weak, nonatomic) IBOutlet UILabel *totalTime;
@property (weak, nonatomic) IBOutlet UIButton *playpausebtn;
@property (strong, nonatomic) AVPlayer *audioPlayer;
@property (nonatomic) NSTimer *playbackTimer;

//-(void)initWithPodcast:(rcfPodcast *)podcast;

@end