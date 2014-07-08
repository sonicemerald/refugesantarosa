//
//  rcfPodcastTableViewCell.h
//  Refuge Christian Fellowship
//
//  Created by Micah Gemmell on 5/21/14.
//  Copyright (c) 2014 RefugeCF. All rights reserved.
//

#import <UIKit/UIKit.h>

@class rcfPodcast;

@interface rcfPodcastTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIButton *downloadButton;


@property (weak, nonatomic) IBOutlet UILabel *testLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *progressIndicator;

-(void)setTheProgressIndicator:(double)currentProgress with:(NSInteger) currentlyDownloading;
-(void)configureWithPodcast:(rcfPodcast *)podcast;

@end 
