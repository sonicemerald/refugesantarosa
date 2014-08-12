//
//  rcfBlog.h
//  Refuge Christian Fellowship
//
//  Created by Micah Gemmell on 7/4/14.
//  Copyright (c) 2014 RefugeCF. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface rcfBlog : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *link;
@property (nonatomic, copy) NSString *pubDate;
@property (nonatomic, copy) NSString *creator;
@property (nonatomic, copy) NSString *category;
@property (nonatomic, copy) NSString *content;
@end

/*
 <title>February 27, 2014</title>
 <link>http://refugecf.com/february-27-2014/</link>
 <comments>http://refugecf.com/february-27-2014/#comments</comments>
 <pubDate>Thu, 27 Feb 2014 03:00:52 +0000</pubDate>
 <dc:creator>
 <![CDATA[ Nicolai Pedersen ]]>
 </dc:creator>
 <category>
 <![CDATA[ Prayer ]]>
 </category>
 <category>
 <![CDATA[ prayer guide ]]>
 </category>
 <guid isPermaLink="false">http://refugecf.com/?p=1286</guid>
 <description>
 <![CDATA[ ]]>
 </description>
*/