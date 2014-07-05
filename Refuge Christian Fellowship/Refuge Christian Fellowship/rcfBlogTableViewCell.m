//
//  rcfBlogTableViewCell.m
//  Refuge Christian Fellowship
//
//  Created by Micah Gemmell on 7/4/14.
//  Copyright (c) 2014 RefugeCF. All rights reserved.
//


#import "rcfBlogTableViewCell.h"
#import "rcfBlog.h"

@interface rcfBlogTableViewCell ()
@property (weak, nonatomic) IBOutlet UILabel *BlogPostTitle;
@property (weak, nonatomic) IBOutlet UILabel *BlogPostCreator;
@property (weak, nonatomic) IBOutlet UILabel *BlogPostDate;


@end

@implementation rcfBlogTableViewCell

-(void)configureWithBlog:(rcfBlog *)Blog
{
    self.BlogPostTitle.text = Blog.title;
    self.BlogPostCreator.text = Blog.creator;
    self.BlogPostDate.text = Blog.pubDate;
    
    self.backgroundColor = [UIColor colorWithRed:245/255.0f green:245/255.0f blue:245/255.0f alpha:1.0f];
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
