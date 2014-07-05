//
//  rcfBlogParseOperation.m
//  Refuge Christian Fellowship
//
//  Created by Micah Gemmell on 5/21/14.
//  Copyright (c) 2014 RefugeCF. All rights reserved.
//

#import "rcfBlogParseOperation.h"
#import "rcfBlog.h"

// NSNotification name for sending Blog data back to the app delegate
NSString *kAddBlogPostNotification = @"AddPostNotif";

// NSNotification userInfo key for obtaining the earthquake data
NSString *kBlogResultsKey = @"EarthquakeResultsKey";

// NSNotification name for reporting errors
NSString *kBlogErrorNotification = @"BlogErrorNotif";

// NSNotification userInfo key for obtaining the error message
NSString *kBlogMessageErrorKey = @"BlogMsgErrorKey";

@interface rcfBlogParseOperation () <NSXMLParserDelegate>
@property (nonatomic) rcfBlog *currentBlogObject;
@property (nonatomic) NSMutableArray *currentParseBatch;
@property (nonatomic) NSMutableString *currentParsedCharacterData;
@end

@implementation rcfBlogParseOperation
{
    BOOL _accumulatingParsedCharacterData;
    BOOL _didAbortParsing;
    NSUInteger _parsedBlogCounter;
}

- (id)initWithData:(NSData *)parseData {
    
    self = [super init];
    if (self) {
        _BlogData = [parseData copy];
        
        _currentParseBatch = [[NSMutableArray alloc] init];
        _currentParsedCharacterData = [[NSMutableString alloc] init];
    }
    return self;
}

- (void)addBlogPostsToList:(NSArray *)BlogPosts {
    
    assert([NSThread isMainThread]);
    [[NSNotificationCenter defaultCenter] postNotificationName:kAddBlogPostNotification object:self userInfo:@{kBlogResultsKey: BlogPosts}];
}

// The main function for this NSOperation, to start the parsing.
- (void)main {
    
    /*
     It's also possible to have NSXMLParser download the data, by passing it a URL, but this is not desirable because it gives less control over the network, particularly in responding to connection errors.
     */
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:self.BlogData];
    [parser setDelegate:self];
    [parser parse];
    
    /*
     Depending on the total number of Blog Posts parsed, the last batch might not have been a "full" batch, and thus not been part of the regular batch transfer. So, we check the count of the array and, if necessary, send it to the main thread.
     */
    if ([self.currentParseBatch count] > 0) {
        [self performSelectorOnMainThread:@selector(addBlogPostsToList:) withObject:self.currentParseBatch waitUntilDone:NO];
    }
}

/*
 Limit the number of parsed Blog Posts to 500).
 */
static const NSUInteger kMaximumNumberOfBlogPostsToParse = 500;

/*
 When an Blog object has been fully constructed, it must be passed to the main thread and the table view in RootViewController must be reloaded to display it. It is not efficient to do this for every Blog object - the overhead in communicating between the threads and reloading the table exceed the benefit to the user. Instead, we pass the objects in batches, sized by the constant below. In your application, the optimal batch size will vary depending on the amount of data in the object and other factors, as appropriate.
 */
static NSUInteger const kSizeOfBlogsBatch = 10;

// Reduce potential parsing errors by using string constants declared in a single place.
static NSString * const kItemElementName = @"item";
static NSString * const kTitleElementName = @"title";
static NSString * const kLinkElementName = @"link";
static NSString * const kPubDateElementName = @"pubDate";
static NSString * const kCreatorElementName = @"dc:creator";
static NSString * const kCategoryElementName = @"category";
static NSString * const kContentElementName = @"content:encoded";


#pragma mark - NSXMLParser delegate methods

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    
    /*
     If the number of parsed Blogs is greater than kMaximumNumberOfBlogsToParse, abort the parse.
     */
    if (_parsedBlogCounter >= kMaximumNumberOfBlogPostsToParse) {
        /*
         Use the flag didAbortParsing to distinguish between this deliberate stop and other parser errors.
         */
        _didAbortParsing = YES;
        [parser abortParsing];
    }
    if ([elementName isEqualToString:kItemElementName]) {
        //create the Blog object.
        rcfBlog *Blog = [[rcfBlog alloc] init];
        self.currentBlogObject = Blog;
    }
    else if (
             ([elementName isEqualToString:kTitleElementName] ||
             [elementName isEqualToString:kLinkElementName] ||
             [elementName isEqualToString:kPubDateElementName] ||
             [elementName isEqualToString:kCreatorElementName] ||
             [elementName isEqualToString:kCategoryElementName] ||
             [elementName isEqualToString:kContentElementName]) && (self.currentBlogObject)){
        // For the 'title', 'link', 'pubDate', 'creator', 'category', or 'content' element begin accumulating parsed character data.
        // The contents are collected in parser:foundCharacters:.
            _accumulatingParsedCharacterData = YES;
        // The mutable string needs to be reset to empty.
            [self.currentParsedCharacterData setString:@""];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    
    /*
     <item>
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
     <content:encoded>
     <![CDATA[
     <div class="toggles "> <div class="toggle accent-color"><h3><a href="#" id="link_53b773f6bf94c"><i class="icon-plus-sign"></i>Introduction</a><script>_kmq.push(["trackClickOnOutboundLink","link_53b773f6bf94c","Article link clicked",{"Title":"<i class=\"icon-plus-sign\"><\/i>Introduction","Page":"February 27, 2014"}]);</script></h3><div>Compassionate Lord, Thy mercies have brought me to the dawn of another day. Vain will be its gift unless I grow in grace, increase in knowledge, ripen for spiritual harvest&#8230;</p> </div></div> <div class="toggle accent-color"><h3><a href="#" id="link_53b773f6bfa2e"><i class="icon-plus-sign"></i>Prayers &amp; Psalms for Meditation</a><script>_kmq.push(["trackClickOnOutboundLink","link_53b773f6bfa2e","Article link clicked",{"Title":"<i class=\"icon-plus-sign\"><\/i>Prayers &amp; Psalms for Meditation","Page":"February 27, 2014"}]);</script></h3><div> <p>&#8220;Rejoice always, pray without ceasing, give thanks in all circumstances; for this is the will of God in Christ Jesus for you. – 1 1 Thessalonians 5 :16-18</p> <p>&#8220;The Church must give itself to unceasing prayer. Never was prayer to cease in the Church. This was the will of God concerning His Church on earth.</p> <p>Paul was not only given to prayer himself, but he continually and earnestly urged it in a way that showed its vital importance. He was not only insistent in urging prayer upon the Church in his day, but he urged persistent praying. &#8216;Continue in prayer and watch in the same,&#8217; was the keynote of all his exhortations on prayer. &#8216;Praying always with all prayer and supplication,&#8217; was the way he pressed this important matter upon the people. &#8216;I will, therefore,&#8217; I exhort, this is my desire, my mind upon this question, &#8216;that men pray everywhere, without wrath and doubting.&#8217; As he prayed after this fashion himself, he could afford to press it upon those to whom he ministered.&#8221; – E. M. Bounds, <em>Prayer and Praying Men</em></p> </div></div> <div class="toggle accent-color"><h3><a href="#" id="link_53b773f6bfb0a"><i class="icon-plus-sign"></i>Intercession For Others</a><script>_kmq.push(["trackClickOnOutboundLink","link_53b773f6bfb0a","Article link clicked",{"Title":"<i class=\"icon-plus-sign\"><\/i>Intercession For Others","Page":"February 27, 2014"}]);</script></h3><div><i class="icon-tiny icon-pushpin accent-color"></i>Since The Lord is with you always, today pray concerning everything and every thought. As things come to mind, be in that constant state of prayer and give it over to The Lord.</p> </div></div> <div class="toggle accent-color"><h3><a href="#" id="link_53b773f6bfbe9"><i class="icon-plus-sign"></i>The Lord's Prayer</a><script>_kmq.push(["trackClickOnOutboundLink","link_53b773f6bfbe9","Article link clicked",{"Title":"<i class=\"icon-plus-sign\"><\/i>The Lord's Prayer","Page":"February 27, 2014"}]);</script></h3><div>Our Father in heaven,<br /> hallowed be your name.<br /> Your kingdom come,<br /> your will be done,<br /> on earth as it is in heaven.<br /> Give us this day our daily bread,<br /> and forgive us our debts,<br /> as we also have forgiven our debtors.<br /> And lead us not into temptation,<br /> but deliver us from evil.</div></div> <div class="toggle accent-color"><h3><a href="#" id="link_53b773f6bfcbe"><i class="icon-plus-sign"></i>Benediction</a><script>_kmq.push(["trackClickOnOutboundLink","link_53b773f6bfcbe","Article link clicked",{"Title":"<i class=\"icon-plus-sign\"><\/i>Benediction","Page":"February 27, 2014"}]);</script></h3><div>Prayer is not always an event. It is also a constant and consistent attitude. This type of prayer takes practice. Today, practice such prayer. May every breath be chased by a inner word to The Lord.</p> </div></div> </div>
     ]]>
     </content:encoded>
     <wfw:commentRss>http://refugecf.com/february-27-2014/feed/</wfw:commentRss>
     <slash:comments>0</slash:comments>
     </item>

     */
    
if(self.currentBlogObject != nil){
    if ([elementName isEqualToString:kItemElementName]) {
        [self.currentParseBatch addObject:self.currentBlogObject];
        _parsedBlogCounter++;
        
        if ([self.currentParseBatch count] >= kSizeOfBlogsBatch) {
            [self performSelectorOnMainThread:@selector(addBlogPostsToList:) withObject:self.currentParseBatch waitUntilDone:NO];
            self.currentParseBatch = [NSMutableArray array];
        }
        return;
    }
    
    if ([elementName isEqualToString:kTitleElementName]) {
        /*
         here's an example of the title
         <title>February 27, 2014</title>
        */
        self.currentBlogObject.title = self.currentParsedCharacterData;
        NSLog(@"the title is %@", self.currentParsedCharacterData);
        return;
    }
    
    if ([elementName isEqualToString:kLinkElementName]) {
        /*
         here's an example of the link
         <link>http://refugecf.com/february-27-2014/</link>
         */

        self.currentBlogObject.link = self.currentParsedCharacterData;
        NSLog(@"the link is %@", self.currentParsedCharacterData);
        return;
    }
    
    if ([elementName isEqualToString:kPubDateElementName]) {
        
        NSString *date = [self.currentParsedCharacterData substringToIndex:[self.currentParsedCharacterData length]-15];
        
        self.currentBlogObject.pubDate = date;
        NSLog(@"the date is %@", self.currentParsedCharacterData);
        return;
    }
    
    if ([elementName isEqualToString:kCreatorElementName]) {
        NSLog(@"the creator is %@", self.currentParsedCharacterData);
        self.currentBlogObject.creator = self.currentParsedCharacterData;
        return;
    }
    
    if ([elementName isEqualToString:kCategoryElementName]) {
        self.currentBlogObject.category = self.currentParsedCharacterData;
        NSLog(@"The category is %@", self.currentParsedCharacterData);
        return;
    }
    
    if ([elementName isEqualToString:kContentElementName]) {
        self.currentBlogObject.content = self.currentParsedCharacterData;
        NSLog(@"the content is %@", self.currentParsedCharacterData);
        return;
    }
    
    // Stop accumulating parsed character data. We won't start again until specific elements begin.
    _accumulatingParsedCharacterData = NO;

    }

    if(self.currentBlogObject != nil){
        NSLog(@"the currentBlogobject is: %@", self.currentBlogObject);
    }
}

/**
 This method is called by the parser when it find parsed character data ("PCDATA") in an element. The parser is not guaranteed to deliver all of the parsed character data for an element in a single invocation, so it is necessary to accumulate character data until the end of the element is reached.
 */
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    
    if (_accumulatingParsedCharacterData) {
        // If the current element is one whose content we care about, append 'string'
        // to the property that holds the content of the current element.
        //
        [self.currentParsedCharacterData appendString:string];
    }
}

/**
 An error occurred while parsing the Blog data: post the error as an NSNotification to our app delegate.
 */
- (void)handleBlogsError:(NSError *)parseError {
    
    assert([NSThread isMainThread]);
    [[NSNotificationCenter defaultCenter] postNotificationName:kBlogErrorNotification object:self userInfo:@{kBlogMessageErrorKey: parseError}];
}

/**
 An error occurred while parsing the Blog data, pass the error to the main thread for handling.
 (Note: don't report an error if we aborted the parse due to a max limit of earthquakes.)
 */
- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    
    if ([parseError code] != NSXMLParserDelegateAbortedParseError && !_didAbortParsing) {
        [self performSelectorOnMainThread:@selector(handleBlogsError:) withObject:parseError waitUntilDone:NO];
    }
}



@end
