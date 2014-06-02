//
//  rcfPodcastDetailView.m
//  Refuge Christian Fellowship
//
//  Created by Micah Gemmell on 5/26/14.
//  Copyright (c) 2014 RefugeCF. All rights reserved.
//

#import "rcfPodcastDetailView.h"
#import <AVFoundation/AVFoundation.h>

@implementation rcfPodcastDetailView

AVPlayer *player;
NSTimer *playbackTimer;
BOOL isPlaying;

- (void) viewDidLoad{

    self.podcastTitle.text = self.podcast.title;
    self.podcastSubtitle.text = self.podcast.subtitle;
    self.podcastDate.text = self.podcast.date;
    [self.podcastSummary loadHTMLString:self.podcast.summary baseURL:nil];
    NSURL *urlStream = [NSURL URLWithString:self.podcast.guidlink];
    
    AVAsset *asset = [AVURLAsset URLAssetWithURL:urlStream options:nil];
    AVPlayerItem *anItem = [AVPlayerItem playerItemWithAsset:asset];
    
    player = [AVPlayer playerWithPlayerItem:anItem];
    [player addObserver:self forKeyPath:@"status" options:0 context:nil];
    
    [self.playpausebtn addTarget:self action:@selector(didPressPlay:) forControlEvents:UIControlEventTouchUpInside];
    
    isPlaying = false;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if (object == player && [keyPath isEqualToString:@"status"]) {
        if (player.status == AVPlayerStatusFailed) {
            NSLog(@"AVPlayer Failed");
        } else if (player.status == AVPlayerStatusReadyToPlay) {
            NSLog(@"AVPlayer Ready to Play");
        } else if (player.status == AVPlayerItemStatusUnknown) {
            NSLog(@"AVPlayer Unknown");
        }
    }
}


-(void)didPressPlay:(UITapGestureRecognizer *) sender{
    if(!isPlaying){
        [player play];
        NSLog(@"Playing audio");
        isPlaying = true; }
    else {
        [player pause];
        NSLog(@"Pausing audio");
        isPlaying = false;
    }
}


@end