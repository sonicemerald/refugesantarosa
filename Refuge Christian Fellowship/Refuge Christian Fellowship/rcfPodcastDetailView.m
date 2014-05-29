//
//  rcfPodcastDetailView.m
//  Refuge Christian Fellowship
//
//  Created by Micah Gemmell on 5/26/14.
//  Copyright (c) 2014 RefugeCF. All rights reserved.
//

#import "rcfPodcastDetailView.h"
@implementation rcfPodcastDetailView

- (void) viewDidLoad{

    self.podcastTitle.text = self.podcast.title;
    self.podcastSubtitle.text = self.podcast.subtitle;
    self.podcastDate.text = self.podcast.date;
    [self.podcastSummary loadHTMLString:self.podcast.summary baseURL:nil];
    NSURL *url = [NSURL URLWithString:self.podcast.guidlink];
}
@end