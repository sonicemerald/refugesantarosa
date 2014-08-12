//
//  rcfPodcastParseOperation.m
//  Refuge Christian Fellowship
//
//  Created by Micah Gemmell on 5/21/14.
//  Copyright (c) 2014 RefugeCF. All rights reserved.
//

#import "rcfPodcastParseOperation.h"
#import "rcfPodcast.h"

// NSNotification name for sending podcast data back to the app delegate
NSString *kAddPodcastEpisodeNotification = @"AddEpisodeNotif";

// NSNotification userInfo key for obtaining the earthquake data
NSString *kPodcastResultsKey = @"PodcastResultsKey";

// NSNotification name for reporting errors
NSString *kPodcastErrorNotification = @"PodcastErrorNotif";

// NSNotification userInfo key for obtaining the error message
NSString *kPodcastMessageErrorKey = @"PodcastMsgErrorKey";

@interface rcfPodcastParseOperation () <NSXMLParserDelegate>
@property (nonatomic) rcfPodcast *currentPodcastObject;
@property (nonatomic) NSMutableArray *currentParseBatch;
@property (nonatomic) NSMutableString *currentParsedCharacterData;
@property (nonatomic) NSString *imageurl;
@end

@implementation rcfPodcastParseOperation
{
    BOOL _accumulatingParsedCharacterData;
    BOOL _didAbortParsing;
    NSUInteger _parsedPodcastCounter;
}

- (id)initWithData:(NSData *)parseData {
    
    self = [super init];
    if (self) {
        _podcastData = [parseData copy];
        
        _currentParseBatch = [[NSMutableArray alloc] init];
        _currentParsedCharacterData = [[NSMutableString alloc] init];
    }
    return self;
}

- (void)addPodcastEpisodesToList:(NSArray *)podcastEpisodes {
    
    assert([NSThread isMainThread]);
    [[NSNotificationCenter defaultCenter] postNotificationName:kAddPodcastEpisodeNotification object:self userInfo:@{kPodcastResultsKey: podcastEpisodes}];
}

// The main function for this NSOperation, to start the parsing.
- (void)main {
    
    /*
     It's also possible to have NSXMLParser download the data, by passing it a URL, but this is not desirable because it gives less control over the network, particularly in responding to connection errors.
     */
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:self.podcastData];
    [parser setDelegate:self];
    [parser parse];
    
    /*
     Depending on the total number of podcast episodes parsed, the last batch might not have been a "full" batch, and thus not been part of the regular batch transfer. So, we check the count of the array and, if necessary, send it to the main thread.
     */
    if ([self.currentParseBatch count] > 0) {
        [self performSelectorOnMainThread:@selector(addPodcastEpisodesToList:) withObject:self.currentParseBatch waitUntilDone:NO];
    }
}

/*
 Limit the number of parsed podcast episodes to 500).
 */
static const NSUInteger kMaximumNumberOfPodcastEpisodesToParse = 500;

/*
 When an Podcast object has been fully constructed, it must be passed to the main thread and the table view in RootViewController must be reloaded to display it. It is not efficient to do this for every Podcast object - the overhead in communicating between the threads and reloading the table exceed the benefit to the user. Instead, we pass the objects in batches, sized by the constant below. In your application, the optimal batch size will vary depending on the amount of data in the object and other factors, as appropriate.
 */
static NSUInteger const kSizeOfPodcastsBatch = 10;

// Reduce potential parsing errors by using string constants declared in a single place.
static NSString * const kItemElementName = @"item";
static NSString * const kImageElementName = @"image";
static NSString * const kImageUrlElementName = @"url";
static NSString * const kTitleElementName = @"title";
static NSString * const kSubTitleElementName = @"itunes:subtitle";
static NSString * const kAuthorElementName = @"itunes:author";
static NSString * const kPubDateElementName = @"pubDate";
static NSString * const kSummaryElementName = @"itunes:summary";
static NSString * const kLinkElementName = @"guid";


#pragma mark - NSXMLParser delegate methods

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    
    /*
     If the number of parsed podcasts is greater than kMaximumNumberOfpodcastsToParse, abort the parse.
     */
    if (_parsedPodcastCounter >= kMaximumNumberOfPodcastEpisodesToParse) {
        /*
         Use the flag didAbortParsing to distinguish between this deliberate stop and other parser errors.
         */
        _didAbortParsing = YES;
        [parser abortParsing];
    }
    
    if ([elementName isEqualToString:kImageUrlElementName]){
        // The contents are collected in parser:foundCharacters:.
        _accumulatingParsedCharacterData = YES;
        // The mutable string needs to be reset to empty.
        [self.currentParsedCharacterData setString:@""];
    } else if ([elementName isEqualToString:kItemElementName]) {
        //create the podcast object.
        rcfPodcast *podcast = [[rcfPodcast alloc] init];
        self.currentPodcastObject = podcast;
    } else if (
             ([elementName isEqualToString:kTitleElementName] ||
             [elementName isEqualToString:kAuthorElementName] ||
             [elementName isEqualToString:kSubTitleElementName] ||
             [elementName isEqualToString:kSummaryElementName] ||
             [elementName isEqualToString:kLinkElementName] ||
             [elementName isEqualToString:kPubDateElementName]) && (self.currentPodcastObject)){
        // For the 'title', 'subtitle', 'author', 'pubdate' or 'summary' element begin accumulating parsed character data.
        // The contents are collected in parser:foundCharacters:.
            _accumulatingParsedCharacterData = YES;
        // The mutable string needs to be reset to empty.
            [self.currentParsedCharacterData setString:@""];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    
    /*
     <item>
     <title>John 5:1-15</title>
     <itunes:author>Refuge Christian Fellowship</itunes:author>
     <description>...</description>
     <itunes:subtitle>The Compelling Grace of God</itunes:subtitle>
     <itunes:summary/>
     <enclosure url="http://www.podtrac.com/pts/redirect.mp3/www.refugecf.com/podcast/John%205_1-15.mp3" type="audio/mpeg" length="53692136"/>
     <guid>
     http://www.podtrac.com/pts/redirect.mp3/www.refugecf.com/podcast/John%205_1-15.mp3
     </guid>
     <pubDate>Sun, 18 May 2014 10:58:20 -0700</pubDate>
     <category>Christianity</category>
     <itunes:explicit>no</itunes:explicit>
     <itunes:duration>00:55:54</itunes:duration>
     <itunes:keywords>
     Christianity, Bible Teaching, Sermon, Spirituality, Jesus, Refuge, Refuge Christian, Refuge Christian Fellowship, Santa Rosa, Char, Char Brodersen, Refuge Audio, Church, Fellowship, Brodersen,
     </itunes:keywords>
     </item>
     */
    if([elementName isEqualToString:kImageUrlElementName]){
        self.imageurl = self.currentParsedCharacterData;
        self.imageurl = [self.imageurl stringByReplacingOccurrencesOfString:@"http://www.podtrac.com/pts/redirect.mp3/" withString:@"http://"];
        NSLog(@"the image url is %@", self.imageurl);
    }

    
if(self.currentPodcastObject != nil){
    self.currentPodcastObject.imageurl = self.imageurl;
    if ([elementName isEqualToString:kItemElementName]) {
        [self.currentParseBatch addObject:self.currentPodcastObject];
        _parsedPodcastCounter++;
        
        if ([self.currentParseBatch count] >= kSizeOfPodcastsBatch) {
            [self performSelectorOnMainThread:@selector(addPodcastEpisodesToList:) withObject:self.currentParseBatch waitUntilDone:NO];
            self.currentParseBatch = [NSMutableArray array];
        }
        return;
    }
    
    if ([elementName isEqualToString:kTitleElementName]) {
        /*
         here's an example of the title
         <title>John 5:1-15</title>
        */
        self.currentPodcastObject.title = self.currentParsedCharacterData;
        NSLog(@"the title is %@", self.currentParsedCharacterData);
        return;
    }
    
    if ([elementName isEqualToString:kAuthorElementName]) {
        /*
         here's an example of the author
         <itunes:author>Refuge Christian Fellowship</itunes:author>
         */

        self.currentPodcastObject.author = self.currentParsedCharacterData;
        NSLog(@"the author is %@", self.currentParsedCharacterData);
        return;
    }
    
    if ([elementName isEqualToString:kSubTitleElementName]) {
        self.currentPodcastObject.subtitle = self.currentParsedCharacterData;
        NSLog(@"The subtitle is: %@", self.currentParsedCharacterData);
        return;
    }
    
    if ([elementName isEqualToString:kSummaryElementName]) {
        NSLog(@"the summary is %@", self.currentParsedCharacterData);
        self.currentPodcastObject.summary = self.currentParsedCharacterData;
        return;
    }
    
    if ([elementName isEqualToString:kLinkElementName]) {
        /*
         an example:
         <guid>http://www.podtrac.com/pts/redirect.mp3/www.refugecf.com/podcast/John%205_1-15.mp3</guid>*/
        self.currentPodcastObject.guidlink = self.currentParsedCharacterData;
        NSLog(@"The gui link is %@", self.currentParsedCharacterData);
        return;
    }
    
    if ([elementName isEqualToString:kPubDateElementName]) {
        
        NSString *date = [self.currentParsedCharacterData substringToIndex:[self.currentParsedCharacterData length]-15];
        
        self.currentPodcastObject.date = date;
        NSLog(@"the date is %@", self.currentParsedCharacterData);
        return;
    }
    
    // Stop accumulating parsed character data. We won't start again until specific elements begin.
    _accumulatingParsedCharacterData = NO;

    }

    if(self.currentPodcastObject != nil){
        NSLog(@"the currentPodcastobject is: %@", self.currentPodcastObject);
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
 An error occurred while parsing the podcast data: post the error as an NSNotification to our app delegate.
 */
- (void)handlePodcastsError:(NSError *)parseError {
    
    assert([NSThread isMainThread]);
    [[NSNotificationCenter defaultCenter] postNotificationName:kPodcastErrorNotification object:self userInfo:@{kPodcastMessageErrorKey: parseError}];
}

/**
 An error occurred while parsing the podcast data, pass the error to the main thread for handling.
 (Note: don't report an error if we aborted the parse due to a max limit of earthquakes.)
 */
- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    
    if ([parseError code] != NSXMLParserDelegateAbortedParseError && !_didAbortParsing) {
        [self performSelectorOnMainThread:@selector(handlePodcastsError:) withObject:parseError waitUntilDone:NO];
    }
}



@end
