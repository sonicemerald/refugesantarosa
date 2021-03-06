//
//  rcfBlogDetailView.h
//  Refuge Christian Fellowship
//
//  Created by Micah Gemmell on 7/4/14.
//  Copyright (c) 2014 RefugeCF. All rights reserved.
//

#import "rcfBlog.h"

@interface rcfBlogDetailView : UIViewController <UIWebViewDelegate>

@property (nonatomic) rcfBlog *blog;
@property (nonatomic) UIWebView *webview;
@property (nonatomic) UIActivityIndicatorView *activityIndicatorObject;
@end