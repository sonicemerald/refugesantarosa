//
//  rcfPodcast.h
//  Refuge Christian Fellowship
//
//  Created by Micah Gemmell on 5/20/14.
//  Copyright (c) 2014 RefugeCF. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface rcfPodcast : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *author;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, copy) NSString *summary;
@property (nonatomic, copy) NSString *guidlink;
@property (nonatomic, copy) NSString *date;
//@property (nonatomic, copy) NSString *duration;
@end
