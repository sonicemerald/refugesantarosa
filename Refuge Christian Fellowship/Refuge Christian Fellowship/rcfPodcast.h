//
//  rcfPodcast.h
//  Refuge Christian Fellowship
//
//  Created by Micah Gemmell on 5/20/14.
//  Copyright (c) 2014 RefugeCF. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface rcfPodcast : NSObject

@property (nonatomic) NSString *title; 
@property (nonatomic) NSString *subtitle;
@property (nonatomic) NSString *author;
@property (nonatomic) NSDate *date;
@property (nonatomic) NSString *summary;
@property (nonatomic) NSURL *audiofile;
@end
