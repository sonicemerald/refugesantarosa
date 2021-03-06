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
//    self.view.backgroundColor = [UIColor colorWithRed:245/255.0f green:245/255.0f blue:245/255.0f alpha:100];
    self.playerSlider.thumbTintColor = [UIColor colorWithRed:48/255.0f green:113/255.0f blue:121/255.0f alpha:1.0f];
    
    NSURL *imageURL = [NSURL URLWithString:self.podcast.imageurl];
    NSLog(@"%@", self.podcast.imageurl);
    NSData *imageData = [NSData dataWithContentsOfURL:imageURL];
    self.artwork = [UIImage imageWithData:imageData];
    self.podcastImage.image = self.artwork;
//
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
//        NSData *imageData = [NSData dataWithContentsOfURL:imageURL];
//        
//        dispatch_async(dispatch_get_main_queue(), ^{
//            // Update the UI
//            self.podcastImage.image = [UIImage imageWithData:imageData];
//        });
//    });    
    self.podcastTitle.text = self.podcast.title;
    self.podcastSubtitle.text = self.podcast.subtitle;
    self.podcastDate.text = self.podcast.date;
    self.podcastAuthor.text = self.podcast.author;
    [self.podcastSummary loadHTMLString:self.podcast.summary baseURL:nil];
    
    //Hide the time because it won't be correct
    self.elapsedTime.hidden = YES;
    self.totalTime.hidden = YES;
    self.playerSlider.hidden = YES;
    self.loading.hidden = NO;
    self.cantplay = NO;
    
    [self.playpausebtn setTitle:@"Pause" forState:UIControlStateNormal];
    [self.minus15 addTarget:self action:@selector(didPressMinus15) forControlEvents:UIControlEventTouchUpInside];
    [self.playpausebtn addTarget:self action:@selector(didPressPlay:) forControlEvents:UIControlEventTouchUpInside];
    [self.plus15 addTarget:self action:@selector(didPressPlus15) forControlEvents:UIControlEventTouchUpInside];
    [self.audioPlayer addObserver:self forKeyPath:@"status" options:0 context:nil];
    NSError *setCategoryError = nil;
    NSError *activationError = nil;
    [[AVAudioSession sharedInstance] setActive:YES error:&activationError];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&setCategoryError];
    [self setUpRemoteControl];
    [self.playerSlider addTarget:self action:@selector(beginScrubbing:) forControlEvents:UIControlEventTouchDown];
    [self.playerSlider addTarget:self action:@selector(endScrubbing:) forControlEvents:UIControlEventTouchUpInside];
    [self.playerSlider addTarget:self action:@selector(endScrubbing:) forControlEvents:UIControlEventTouchUpOutside];
    [self.playerSlider addTarget:self action:@selector(scrub:) forControlEvents:UIControlEventValueChanged];
    
    
}
- (void) viewWillAppear:(BOOL)animated{
    
    NSString *file = self.podcast.guidlink;
    NSLog(@"%@", file);
    file = [file stringByReplacingOccurrencesOfString:@"http://www.podtrac.com/pts/redirect.mp3/www.refugecf.com/podcast/" withString:@"podcasts/"];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"/podcasts"];
    NSError *error;
    if (![[NSFileManager defaultManager] fileExistsAtPath:dataPath])
        [[NSFileManager defaultManager] createDirectoryAtPath:dataPath withIntermediateDirectories:NO attributes:nil error:&error]; //Create folder
    
    NSString *urlPATH = [NSString stringWithFormat:@"%@/%@", documentsDirectory, file];
    NSURL *localURL = [NSURL fileURLWithPath:urlPATH];
    NSString *u = [localURL path];
    u = [u stringByRemovingPercentEncoding];
    localURL = [NSURL fileURLWithPath:u];
    NSURL *urlStream = [NSURL URLWithString:self.podcast.guidlink];
    
    self.item = [[AVPlayerItem alloc] initWithURL:localURL];
    if(!self.item.asset.playable){//    if(self.item.duration.value == CMTimeMake(0, 0).value){
        NSLog(@"using stream");
        self.item = [[AVPlayerItem alloc] initWithURL:urlStream];
    }
    [self.audioPlayer.currentItem addObserver:self forKeyPath:@"status" options:0 context:nil];
    if(self.audioPlayer.currentItem) { //if another episode is playing...
        [self.playpausebtn setTitle:@"Pause" forState:UIControlStateNormal];
        AVURLAsset *currURL = (AVURLAsset *)[self.audioPlayer.currentItem asset];
        AVURLAsset *pendingURL = [AVURLAsset URLAssetWithURL:urlStream options:nil];
        if (![currURL.URL isEqual: pendingURL.URL]) {
            //New episode, pause old one, replace, play and start timer
            [self.audioPlayer pause];
            NSLog(@"pausing audioPlayer, %@, to change what is playing", self.audioPlayer);
            [self.audioPlayer replaceCurrentItemWithPlayerItem:self.item];
            self.loading.hidden = YES;
            [self.audioPlayer play];
            self.playbackTimer = [NSTimer scheduledTimerWithTimeInterval:0.01
                                                                  target:self
                                                                selector:@selector(updateTime:)
                                                                userInfo:nil
                                                                 repeats:YES];
            self.playerSlider.hidden = NO;
        }
    } else {
            self.audioPlayer = [self.audioPlayer initWithPlayerItem:self.item];
            //wait for status to be "ready to play" to play.
    }
    
    self.playbackTimer = [NSTimer scheduledTimerWithTimeInterval:0.01
                                                          target:self
                                                        selector:@selector(updateTime:)
                                                        userInfo:nil
                                                         repeats:YES];
}
- (void) viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
//    //Once the view has loaded then we can register to begin recieving controls and we can become the first responder
//    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
//    [self becomeFirstResponder];
    NSNumber *dur = [NSNumber numberWithFloat:ceilf((CMTimeGetSeconds(self.audioPlayer.currentItem.asset.duration)))];
    NSLog(@"%@ duration:", dur);
    [self.songInfo setObject:dur forKey:MPMediaItemPropertyPlaybackDuration];
    
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:self.songInfo];
}
- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if (object == self.audioPlayer && [keyPath isEqualToString:@"status"]) {
        if (self.audioPlayer.status == AVPlayerStatusFailed) {
            NSLog(@"AVPlayer Failed");
        } else if (self.audioPlayer.status == AVPlayerStatusReadyToPlay) {
            NSLog(@"AVPlayer Ready to Play");
            self.loading.hidden = YES;
            [self.audioPlayer play];
            self.playerSlider.hidden = NO;
            self.playbackTimer = [NSTimer scheduledTimerWithTimeInterval:0.01
                                                                  target:self
                                                                selector:@selector(updateTime:)
                                                                userInfo:nil
                                                                 repeats:YES];
           [self initScrubberTimer];
        } else if (self.audioPlayer.status == AVPlayerItemStatusUnknown) {
            NSLog(@"AVPlayer Unknown");
        }
    }

}

/* UI CONTROLS (in order they appear)*/
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
/* UISLIDER (SCRUBBER) 
 [adapted from http://stackoverflow.com/questions/20050964/scrubber-uislider-in-avplayer?rq=1]
 */
- (void)initScrubberTimer {
    double interval = .1f;
    CMTime playerDuration = self.audioPlayer.currentItem.asset.duration;
    if (CMTIME_IS_INVALID(playerDuration))
        return;
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration)){
        CGFloat width = CGRectGetWidth([self.playerSlider bounds]);
        interval = 0.5f * duration / width;
    }
                         
    __weak id weakSelf = self;
    CMTime intervalSeconds = CMTimeMakeWithSeconds(interval, NSEC_PER_SEC);
    mTimeObserver = [self.audioPlayer addPeriodicTimeObserverForInterval:intervalSeconds
    queue:dispatch_get_main_queue()
    usingBlock:^(CMTime time) {
    [weakSelf syncScrubber];
    }];
                         
}
                         
- (void)syncScrubber
{
    CMTime playerDuration = self.audioPlayer.currentItem.asset.duration;
    if (CMTIME_IS_INVALID(playerDuration))
    {
        self.playerSlider.minimumValue = 0.0;
        return;
    }
    
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration))
    {
        float minValue = [self.playerSlider minimumValue];
        float maxValue = [self.playerSlider maximumValue];
        double time = CMTimeGetSeconds([self.audioPlayer currentTime]);
        
        [self.playerSlider setValue:(maxValue - minValue) * time / duration + minValue];
    }
}

- (IBAction)beginScrubbing:(id)sender
{
    mRestoreAfterScrubbingRate = [self.audioPlayer rate];
    [self.audioPlayer setRate:0.f];
    
    [self removePlayerTimeObserver];
}


- (IBAction)scrub:(id)sender
{
    if ([sender isKindOfClass:[OBSlider class]])
    {
        OBSlider* slider = sender;
        
        CMTime playerDuration = self.audioPlayer.currentItem.asset.duration;
        if (CMTIME_IS_INVALID(playerDuration))
        {
            return;
        }
        
        double duration = CMTimeGetSeconds(playerDuration);
        if (isfinite(duration))
        {
            float minValue = [slider minimumValue];
            float maxValue = [slider maximumValue];
            float value = [slider value];
            
            double time = duration * (value - minValue) / (maxValue - minValue);
            
            [self.audioPlayer seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC)];
        }
    }
}

- (IBAction)endScrubbing:(id)sender
{
    if (!mTimeObserver)
    {
        CMTime playerDuration = self.audioPlayer.currentItem.asset.duration;
        if (CMTIME_IS_INVALID(playerDuration))
        {
            return;
        }
        
        double duration = CMTimeGetSeconds(playerDuration);
        if (isfinite(duration))
        {
            CGFloat width = CGRectGetWidth([self.playerSlider bounds]);
            double tolerance = 0.5f * duration / width;
            
            __weak id weakSelf = self;
            CMTime intervalSeconds = CMTimeMakeWithSeconds(tolerance, NSEC_PER_SEC);
            mTimeObserver = [self.audioPlayer addPeriodicTimeObserverForInterval:intervalSeconds
                                                                      queue:dispatch_get_main_queue()
                                                                 usingBlock: ^(CMTime time) {
                                                                     [weakSelf syncScrubber];
                                                                 }];
        }
    }
    
    if (mRestoreAfterScrubbingRate)
    {
        [self.audioPlayer setRate:mRestoreAfterScrubbingRate];
        mRestoreAfterScrubbingRate = 0.f;
    }
}

- (void)removePlayerTimeObserver
{
    if (mTimeObserver)
    {
        [self.audioPlayer removeTimeObserver:mTimeObserver];
        mTimeObserver = nil;
    }
}

- (void)didPressPlay:(UITapGestureRecognizer *) sender{
    if([self.audioPlayer rate] == 0.0){
        [self.audioPlayer play];
        [self.playpausebtn setTitle:@"Pause" forState:UIControlStateNormal];
        NSLog(@"Playing audio");
    } else {
        [self.audioPlayer pause];
        [self.playpausebtn setTitle:@"Play" forState:UIControlStateNormal];
        NSLog(@"Pausing audio");
    }
}

-(void)didPressMinus15{
    CMTime fifteen = CMTimeMakeWithSeconds(-115, 6000);
    CMTime time = CMTimeAdd([self.audioPlayer currentTime], fifteen);
    [self.audioPlayer seekToTime:time];
//    [self.audioPlayer see]
}

-(void)didPressPlus15{
    CMTime fifteen = CMTimeMakeWithSeconds(15, 6000);
    CMTime time = CMTimeAdd([self.audioPlayer currentTime], fifteen);
    [self.audioPlayer seekToTime:time];

}

- (void)setUpRemoteControl{
    
    self.songInfo = [[NSMutableDictionary alloc] init];
    [self.songInfo setObject:self.podcast.subtitle forKey:MPMediaItemPropertyTitle];
    [self.songInfo setObject:self.podcast.author forKey:MPMediaItemPropertyArtist];
    [self.songInfo setObject:self.podcast.title forKey:MPMediaItemPropertyAlbumTitle];
      
    MPMediaItemArtwork *albumArt = [[MPMediaItemArtwork alloc] initWithImage:self.artwork];
    [self.songInfo setObject:albumArt forKey:MPMediaItemPropertyArtwork];
    NSLog(@"%@", self.songInfo);
    
    //[[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:self.songInfo];
    //Set the MPNowPlayingInfo at the end of viewwillappear so that I get the audio duration.
}
- (bool)canBecomeFirstResponder{
    return YES;
}
//- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent {
//    
//    if (receivedEvent.type == UIEventTypeRemoteControl) {
//        switch (receivedEvent.subtype) {
//            case UIEventSubtypeRemoteControlPlay:
//                [self.audioPlayer play];
//                [self.playpausebtn setTitle:@"Pause" forState:UIControlStateNormal];
//                break;
//            case UIEventSubtypeRemoteControlPause:
//                [self.audioPlayer pause];
//                [self.playpausebtn setTitle:@"Play" forState:UIControlStateNormal];
//                break;
//            case UIEventSubtypeRemoteControlTogglePlayPause:
//                if(self.audioPlayer.currentItem){
//                    [self.audioPlayer pause];
//                    [self.playpausebtn setTitle:@"Play" forState:UIControlStateNormal];
//                } else {
//                    [self.audioPlayer play];
//                    [self.playpausebtn setTitle:@"Pause" forState:UIControlStateNormal];
//                }
//                break;
//            default:
//                break;
//        }
//    }
//}


/* END */
-(void)viewWillDisappear:(BOOL)animated{
// End receiving events
    //[self.audioPlayer pause];
    //[[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    //[self resignFirstResponder];
    
    [super viewWillDisappear:animated];
}

@end