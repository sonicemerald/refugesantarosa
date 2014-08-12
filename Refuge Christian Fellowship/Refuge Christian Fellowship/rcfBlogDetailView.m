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

-(void) viewWillAppear:(BOOL)animated{

    
    self.webview.delegate = self;
    self.webview.scalesPageToFit = YES;
    NSURL* url = [NSURL URLWithString:self.blog.link];
    NSURLRequest* request = [NSURLRequest requestWithURL:url];
    [self.webview loadRequest:request];
}

-(void) viewDidLoad{
    
    
//    float width = [UIScreen mainScreen].bounds.size.width;
//    float height = [UIScreen mainScreen].bounds.size.height;
//    self.view.frame = CGRectMake(0.0f, 20.0f, width, height);
//    CGRect frame = CGRectMake(0.0f, -60.0f, width, height+220.0f);
//    self.webview = [[UIWebView alloc] initWithFrame:frame];
//    [self.view addSubview:self.webview];
    self.webview = [[UIWebView alloc] init];
    self.webview.backgroundColor = [UIColor colorWithRed:245/255.0f green:245/255.0f blue:245/255.0f alpha:1.0f];
    
    self.webview.scrollView.bounces = NO;
    [self.view addSubview:self.webview];
    
    self.activityIndicatorObject = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    
    // Set Center Position for ActivityIndicator
    
    self.activityIndicatorObject.center = CGPointMake(150, 150);
    
    // Add ActivityIndicator to your view
    [self.view addSubview:self.activityIndicatorObject];
    
    
    [super viewDidLoad];
}

-(void) viewWillLayoutSubviews{
    CGFloat width = CGRectGetWidth(self.view.bounds);
    CGFloat height = CGRectGetHeight(self.view.bounds);
    self.view.frame = CGRectMake(0.0f, 20.0f, width, height);
    CGRect frame = CGRectMake(0.0f, -80.0f, width, height+220.0f);
    self.webview.frame = frame;
}

-(void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [self.activityIndicatorObject startAnimating];
}


- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    NSLog(@"Failed to load");
}


- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self.activityIndicatorObject stopAnimating];
}

@end
