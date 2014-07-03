//
//  rcfPodcastTableViewCell.m
//  Refuge Christian Fellowship
//
//  Created by Micah Gemmell on 5/21/14.
//  Copyright (c) 2014 RefugeCF. All rights reserved.
//

#import "rcfPodcastTableViewCell.h"
#import "rcfPodcast.h"

@interface rcfPodcastTableViewCell ()
@property (weak, nonatomic) IBOutlet UILabel *episodeTitle;
@property (weak, nonatomic) IBOutlet UILabel *episodeSubtitle;
@property (weak, nonatomic) IBOutlet UILabel *episodeDate;
@property (weak, nonatomic) IBOutlet UIImageView *episodePicture;
@end

@implementation rcfPodcastTableViewCell

-(void)configureWithPodcast:(rcfPodcast *)podcast
{
    self.episodeTitle.text = podcast.title;
 //   self.episodeTitle.textColor = [UICOLor ]
    self.episodeSubtitle.text = podcast.subtitle;
    self.episodeDate.text = podcast.date;
    
    self.backgroundColor = [UIColor colorWithRed:245/255.0f green:245/255.0f blue:245/255.0f alpha:100];
}


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
