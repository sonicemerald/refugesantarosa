//
//  rcfPodcastParseOperation.h
//  Refuge Christian Fellowship
//
//  Created by Micah Gemmell on 5/21/14.
//  Copyright (c) 2014 RefugeCF. All rights reserved.
//

#import <Foundation/Foundation.h>

// NSNotification name for sending podcast data back to the app delegate
extern NSString *kAddPodcastEpisodeNotification;
// NSNotification userInfo key for obtaining the earthquake data
extern NSString *kPodcastResultsKey;

// NSNotification name for reporting errors
extern NSString *kPodcastErrorNotification;
// NSNotification userInfo key for obtaining the error message
extern NSString *kPodcastMessageErrorKey;

@interface rcfPodcastParseOperation : NSOperation

@property (copy, readonly) NSData *podcastData;
-(id)initWithData:(NSData *)parseData;

@end
