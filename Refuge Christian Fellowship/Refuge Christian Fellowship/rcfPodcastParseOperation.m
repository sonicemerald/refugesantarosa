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
NSString *kPodcastResultsKey = @"EarthquakeResultsKey";

// NSNotification name for reporting errors
NSString *kPocastErrorNotification = @"PodcastErrorNotif";

// NSNotification userInfo key for obtaining the error message
NSString *kPodcastMessageErrorKey = @"PodcastMsgErrorKey";

@interface rcfPodcastParseOperation () <NSXMLParserDelegate>
@property (nonatomic) rcfPodcast *currentPodcastObject;
@property (nonatomic) NSMutableArray *currentParseBatch;
@property (nonatomic) NSMutableString *currentParsedCharacterData;
@end

@implementation rcfPodcastParseOperation
{
    NSDateFormatter *_dateFormatter;
    BOOL _accumulatingParsedCharacterData;
    BOOL _didAbortParsing;
    NSUInteger _parsedEarthquakesCounter;
}

- (id)initWithData:(NSData *)parseData {
    
    self = [super init];
    if (self) {
        _podcastData = [parseData copy];
        
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        [_dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
        [_dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
        
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
 Limit the number of parsed podcast episodes to 50?).
 */
static const NSUInteger kMaximumNumberOfPodcastEpisodesToParse = 50;

/*
 When an Podcast object has been fully constructed, it must be passed to the main thread and the table view in RootViewController must be reloaded to display it. It is not efficient to do this for every Podcast object - the overhead in communicating between the threads and reloading the table exceed the benefit to the user. Instead, we pass the objects in batches, sized by the constant below. In your application, the optimal batch size will vary depending on the amount of data in the object and other factors, as appropriate.
 */
static NSUInteger const kSizeOfPodcastsBatch = 10;

// Reduce potential parsing errors by using string constants declared in a single place.
static NSString * const kItemElementName = @"item";
static NSString * const kTitleElementName = @"title";
static NSString * const kSubTitleElementName = @"subtitle";
static NSString * const kAuthorElementName = @"author";
static NSString * const kPubDateElementName = @"PubDate";
static NSString * const kSummaryElementName = @"summary";
static NSString * const kLinkElementName = @"url";


#pragma mark - NSXMLParser delegate methods

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    
    /*
     If the number of parsed podcasts is greater than kMaximumNumberOfpodcastsToParse, abort the parse.
     */
    if (_parsedPodcastsCounter >= kMaximumNumberOfPodcastEpisodesToParse) {
        /*
         Use the flag didAbortParsing to distinguish between this deliberate stop and other parser errors.
         */
        _didAbortParsing = YES;
        [parser abortParsing];
    }
    if ([elementName isEqualToString:kItemElementName]) {
        rcfPodcast *podcast = [[rcfPodcast alloc] init];
        self.currentPodcastObject = podcast;
    }
    else if ([elementName isEqualToString:kTitleElementName] ||
             [elementName isEqualToString:kSubTitleElementName] ||
             [elementName isEqualToString:kAuthorElementName] ||
             [elementName isEqualToString:kPubDateElementName] ||
             [elementName isEqualToString:kSummaryElementName] ){
        // For the 'title', 'subtitle', 'author', 'pubdate' or 'summary' element begin accumulating parsed character data.
        // The contents are collected in parser:foundCharacters:.
            _accumulatingParsedCharacterData = YES;
        // The mutable string needs to be reset to empty.
            [self.currentParsedCharacterData setString:@""];
    }
}


@end
