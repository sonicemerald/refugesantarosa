//
//  rcfBlogTableViewCell.h
//  Refuge Christian Fellowship
//
//  Created by Micah Gemmell on 7/4/14.
//  Copyright (c) 2014 RefugeCF. All rights reserved.
//

#import <UIKit/UIKit.h>

@class rcfBlog;

@interface rcfBlogTableViewCell : UITableViewCell
-(void)configureWithBlog:(rcfBlog *)blog;
@end
