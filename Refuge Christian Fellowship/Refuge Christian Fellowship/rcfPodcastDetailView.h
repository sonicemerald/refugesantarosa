//
//  rcfPodcastDetailView.h
//  Refuge Christian Fellowship
//
//  Created by Micah Gemmell on 5/26/14.
//  Copyright (c) 2014 RefugeCF. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "rcfPodcast.h"

@interface rcfPodcastDetailView : UIViewController
@property (nonatomic) rcfPodcast *podcast;
@property (weak, nonatomic) IBOutlet UILabel *podcastTitle;
@property (weak, nonatomic) IBOutlet UILabel *podcastSubtitle;
@property (weak, nonatomic) IBOutlet UILabel *podcastDate;
@property (weak, nonatomic) IBOutlet UIWebView *podcastSummary;
-(void)initWithPodcast:(rcfPodcast *)podcast;
@end