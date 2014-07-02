//
//  rcfPodcastDetailView.m
//  Refuge Christian Fellowship
//
//  Created by Micah Gemmell on 5/26/14.
//  Copyright (c) 2014 RefugeCF. All rights reserved.
//

#import "rcfPodcastDetailView.h"
#import "rcfPodcastTableViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolBox/AudioSession.h>

@implementation rcfPodcastDetailView

- (void) viewDidLoad{
    [super viewDidLoad];
    
    self.podcastTitle.text = self.podcast.title;
    self.podcastSubtitle.text = self.podcast.subtitle;
    self.podcastDate.text = self.podcast.date;
    [self.podcastSummary loadHTMLString:self.podcast.summary baseURL:nil];
    
    //Hide the time because it won't be correct
    self.elapsedTime.hidden = YES;
    self.totalTime.hidden = YES;
    
    [self.playpausebtn addTarget:self action:@selector(didPressPlay:) forControlEvents:UIControlEventTouchUpInside];
    [self.audioPlayer addObserver:self forKeyPath:@"status" options:0 context:nil];
    NSError *setCategoryError = nil;
    NSError *activationError = nil;
    [[AVAudioSession sharedInstance] setActive:YES error:&activationError];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&setCategoryError];
    [self setUpRemoteControl];
}
- (void) viewWillAppear:(BOOL)animated{
    NSURL *urlStream = [NSURL URLWithString:self.podcast.guidlink];
    AVPlayerItem *item = [[AVPlayerItem alloc] initWithURL:urlStream];
    if(self.audioPlayer.currentItem) { //if another episode is playing...
        AVURLAsset *currURL = (AVURLAsset *)[self.audioPlayer.currentItem asset];
        AVURLAsset *pendingURL = [AVURLAsset URLAssetWithURL:urlStream options:nil];
        if (![currURL.URL isEqual: pendingURL.URL]) {
            //New episode, pause old one, replace, play and start timer
            [self.audioPlayer pause];
            NSLog(@"pausing audioPlayer, %@, to change what is playing", self.audioPlayer);
            [self.audioPlayer replaceCurrentItemWithPlayerItem:item];
            [self.audioPlayer play];
            self.playbackTimer = [NSTimer scheduledTimerWithTimeInterval:0.01
                                                                  target:self
                                                                selector:@selector(updateTime:)
                                                                userInfo:nil
                                                                 repeats:YES];
        }
    } else {
            self.audioPlayer = [self.audioPlayer initWithPlayerItem:item];
            //wait for status to be "ready to play" to play.
    }
    
    self.playbackTimer = [NSTimer scheduledTimerWithTimeInterval:0.01
                                                          target:self
                                                        selector:@selector(updateTime:)
                                                        userInfo:nil
                                                         repeats:YES];
}
-(void) viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    //Once the view has loaded then we can register to begin recieving controls and we can become the first responder
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
}

- (void)didPressPlay:(UITapGestureRecognizer *) sender{
    if([self.audioPlayer rate] == 0.0){
        [self.audioPlayer play];
        NSLog(@"Playing audio");
    } else {
        [self.audioPlayer pause];
        NSLog(@"Pausing audio");
    }
}

- (NSString*)timeFormat:(float)value{
    
    float minutes = floor(lroundf(value)/60);
    float seconds = lroundf((value) - (minutes * 60));
    
    int roundedSeconds = lroundf(seconds);
    int roundedMinutes = lroundf(minutes);
    
    NSString *time = [[NSString alloc]
                      initWithFormat:@"%d:%02d",
                      roundedMinutes, roundedSeconds];
    return time;
}
- (void)updateTime:(NSTimer *)timer {
    self.elapsedTime.hidden = NO;
    self.totalTime.hidden = NO;
    self.elapsedTime.text = [NSString stringWithFormat:@"%@",
                             [self timeFormat: ceilf(CMTimeGetSeconds(self.audioPlayer.currentTime))]];
    
    self.totalTime.text = [NSString stringWithFormat:@"-%@",
                          [self timeFormat: (CMTimeGetSeconds(self.audioPlayer.currentItem.asset.duration)
                                             - ceilf((CMTimeGetSeconds(self.audioPlayer.currentTime))))]];
}
- (void)setUpRemoteControl{
    NSDictionary *nowPlaying = @{MPMediaItemPropertyArtist: self.podcast.author,
                                 MPMediaItemPropertyTitle: self.podcast.title,
                                 MPMediaItemPropertyAlbumTitle: self.podcast.subtitle,
                                 MPMediaItemPropertyPlaybackDuration:[NSValue valueWithCMTime:self.audioPlayer.currentItem.asset.duration],
                                 MPNowPlayingInfoPropertyPlaybackRate:@1.0f
                                 };
    
    
    
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:nowPlaying];
}

-(bool)canBecomeFirstResponder{
    return YES;
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent {
    
    if (receivedEvent.type == UIEventTypeRemoteControl) {
        switch (receivedEvent.subtype) {
            case UIEventSubtypeRemoteControlPlay:
                [self.audioPlayer play];
                break;
            case UIEventSubtypeRemoteControlPause:
                [self.audioPlayer pause];
                break;
            case UIEventSubtypeRemoteControlTogglePlayPause:
                if(self.audioPlayer.currentItem)
                    [self.audioPlayer pause];
                else {
                    [self.audioPlayer play];
                }
                break;
            default:
                break;
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if (object == self.audioPlayer && [keyPath isEqualToString:@"status"]) {
        if (self.audioPlayer.status == AVPlayerStatusFailed) {
            NSLog(@"AVPlayer Failed");
        } else if (self.audioPlayer.status == AVPlayerStatusReadyToPlay) {
            NSLog(@"AVPlayer Ready to Play");
            [self.audioPlayer play];
            self.playbackTimer = [NSTimer scheduledTimerWithTimeInterval:0.01
                                                                  target:self
                                                                selector:@selector(updateTime:)
                                                                userInfo:nil
                                                                 repeats:YES];
            
            } else if (self.audioPlayer.status == AVPlayerItemStatusUnknown) {
            NSLog(@"AVPlayer Unknown");
        }
    }
}


-(void)viewWillDisappear:(BOOL)animated{
// End receiving events
    //[self.audioPlayer pause];
    //[[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    //[self resignFirstResponder];
    
    [super viewWillDisappear:animated];
}

@end