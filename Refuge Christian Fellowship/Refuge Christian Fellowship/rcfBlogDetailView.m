//
//  rcfBlogDetailView.m
//  Refuge Christian Fellowship
//
//  Created by Micah Gemmell on 7/4/14.
//  Copyright (c) 2014 RefugeCF. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "rcfBlogDetailView.H"

@implementation rcfBlogDetailView

-(void) viewDidLoad{
    //self.webview.delegate = self;
    self.webview.scalesPageToFit = YES;
    NSURL* url = [NSURL URLWithString:self.blog.link];
    NSURLRequest* request = [NSURLRequest requestWithURL:url];
    [self.webview loadRequest:request];
    //[self.webview loadHTMLString:self.blog.content baseURL:nil];
    
    [super viewDidLoad];
}
@end
