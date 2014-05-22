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
-(void)configureWithPodcast:(rcfPodcast *)podcast;
@end
