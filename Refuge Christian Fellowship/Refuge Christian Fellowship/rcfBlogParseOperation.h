//
//  rcfBlogParseOperation.h
//  Refuge Christian Fellowship
//
//  Created by Micah Gemmell on 5/21/14.
//  Copyright (c) 2014 RefugeCF. All rights reserved.
//

#import <Foundation/Foundation.h>

// NSNotification name for sending Blog data back to the app delegate
extern NSString *kAddBlogPostNotification;
// NSNotification userInfo key for obtaining the earthquake data
extern NSString *kBlogResultsKey;

// NSNotification name for reporting errors
extern NSString *kBlogErrorNotification;
// NSNotification userInfo key for obtaining the error message
extern NSString *kBlogMessageErrorKey;

@interface rcfBlogParseOperation : NSOperation

@property (copy, readonly) NSData *BlogData;
-(id)initWithData:(NSData *)parseData;

@end
