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

@end

@implementation rcfPodcastTableViewCell

-(void)configureWithPodcast:(rcfPodcast *)podcast
{
    self.deleteButton.hidden = YES;
    self.downloadButton.hidden = NO;
    self.episodeTitle.text = podcast.title;
 //   self.episodeTitle.textColor = [UICOLor ]
    self.episodeSubtitle.text = podcast.subtitle;
    self.episodeDate.text = podcast.date;
    self.backgroundColor = [UIColor colorWithRed:245/255.0f green:245/255.0f blue:245/255.0f alpha:1.0f];
    
    
    [self.downloadButton setTitle:@"Download" forState:UIControlStateNormal];
    
    NSString *file = podcast.guidlink;
    NSLog(@"configuring %@", file);
    file = [file stringByReplacingOccurrencesOfString:@"http://www.podtrac.com/pts/redirect.mp3/www.refugecf.com/podcast/" withString:@"podcasts/"];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"/podcasts"];
    NSError *error;

    if (![[NSFileManager defaultManager] fileExistsAtPath:dataPath])
        [[NSFileManager defaultManager] createDirectoryAtPath:dataPath withIntermediateDirectories:NO attributes:nil error:&error]; //Create folder

    
    NSURL *url = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", documentsDirectory, file]];
    NSString *urlPATH = [url path];
    urlPATH = [urlPATH stringByRemovingPercentEncoding];
    
    NSDictionary *diction = [[NSFileManager defaultManager] attributesOfItemAtPath:urlPATH error:&error];
    NSString *filesize = [diction valueForKey:@"NSFileSize"];
    
    if(filesize)
        NSLog(@"filesize: %@", filesize);
    
    NSLog(@"file might be found! %@", urlPATH);

    if([[NSFileManager defaultManager] fileExistsAtPath:urlPATH]){
        NSLog(@"file found! %@", urlPATH);
        self.downloadButton.hidden = YES;
        self.deleteButton.hidden = NO;
}

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


-(void)setTheProgressIndicator:(double)currentProgress with:(NSInteger) currentlyDownloading{
    if(self.tag == currentlyDownloading){
        self.progressIndicator.hidden = NO;
        self.progressIndicator.progress = currentProgress;
        
    }
}
@end
