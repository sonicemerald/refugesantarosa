//
//  rcfPodcastTableViewController.m
//  Refuge Christian Fellowship
//
//  Created by Micah Gemmell on 5/20/14.
//  Copyright (c) 2014 RefugeCF. All rights reserved.
//

#import "rcfAppDelegate.h"
#import "rcfPodcastTableViewController.h"
#import "rcfPodcastTableViewCell.h"
#import "rcfPodcast.h"
#import "rcfPodcastParseOperation.h"
#import "rcfPodcastDetailView.h"

@interface rcfPodcastTableViewController () {
    NSURLSession *inProcessSession;
    NSURLSessionDownloadTask *cancellableTask;
    NSData *partialDownload;
    rcfPodcastTableViewCell *cell;
}
@property (nonatomic) rcfPodcast *podcast;
@property (nonatomic) NSMutableArray *podcastList;
@property (nonatomic) NSOperationQueue *parseQuene;
@property (nonatomic) NSIndexPath *indexpath;
@property (strong, nonatomic) NSURLSessionDownloadTask *resumableTask;
@end

@implementation rcfPodcastTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.bounces = NO;
    self.podcastList = [NSMutableArray array];

    self.tableView.backgroundColor = [UIColor whiteColor];
    [[UIView appearanceWhenContainedIn:[UITabBar class], nil]
     setTintColor:[UIColor colorWithRed:48/255.0f green:113/255.0f blue:121/255.0f alpha:1.0f]];

    self.backgroundSession.sessionDescription = @"BackgroundSession";
    self.currentlyDownloading = 99999;
    /*
     Use NSURLConnection to asynchronously download the data. This means the main thread will not be blocked - the application will remain responsive to the user.
     
     IMPORTANT! The main thread of the application should never be blocked!
     Also, avoid synchronous network access on any thread.
     */
    static NSString *feedURLString = @"http://refugecf.com/podcast/podcast.xml";
    NSURLRequest *podcastURLRequest =
    [NSURLRequest requestWithURL:[NSURL URLWithString:feedURLString]];
    
    // send the async request (note that the completion block will be called on the main thread)
    //
    // note: using the block-based "sendAsynchronousRequest" is preferred, and useful for
    // small data transfers that are likely to succeed. If you doing large data transfers,
    // consider using the NSURLConnectionDelegate-based APIs.
    
    [NSURLConnection sendAsynchronousRequest:podcastURLRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
    // on main thread, check for errors, if no errors, commence parsing.
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
        //check for any error from server, and http response errors.
        if(error != nil){
            [self handleError:error];
        } else {
            //check for any response errors
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if ((([httpResponse statusCode]/100) == 2) && [[response MIMEType] isEqual:@"application/rss+xml"]) {
                
                // Update the UI and start parsing the data,
                // Spawn an NSOperation to parse the earthquake data so that the UI is not
                // blocked while the application parses the XML data.
                //
                   rcfPodcastParseOperation *parseOperation = [[rcfPodcastParseOperation alloc] initWithData:data];
                [self.parseQuene addOperation:parseOperation];
            }
            else {
                NSString *errorString =
                NSLocalizedString(@"HTTP Error", @"Error message displayed when receving a connection error.");
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey : errorString};
                NSError *reportError = [NSError errorWithDomain:@"HTTP"
                                                           code:[httpResponse statusCode]
                                                       userInfo:userInfo];
                [self handleError:reportError];
            }
        }
    }];
    
    // Start the status bar network activity indicator.
    // We'll turn it off when the connection finishes or experiences an error.
    //
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    self.parseQuene = [NSOperationQueue new];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addPodcasts:) name:kAddPodcastEpisodeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(podcastError:) name:kPodcastErrorNotification object:nil];
    
    if(self.audioPlayer == nil)
        self.audioPlayer = [[AVPlayer alloc] init];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

-(void)handleError:(NSError *)error {
    NSString *errorMessage = [error localizedDescription];
    NSString *alertTitle = NSLocalizedString(@"Error", @"Title for alert displayed when download or parse error occurs");
    NSString *okTitle = NSLocalizedString(@"OK", @"OK Title for displaying when download or parse error occurs");
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:alertTitle message:errorMessage delegate:nil cancelButtonTitle:okTitle otherButtonTitles:nil];
    [alertView show];
}

//NSNotification callback from the running NSOperation when a parsing error has occured
-(void)podcastError:(NSNotification *)notif {
    assert(([NSThread isMainThread]));
    [self handleError:[[notif userInfo] valueForKey:kPodcastMessageErrorKey]];
}

-(void)addPodcasts:(NSNotification *)notif
{
    assert([NSThread isMainThread]);
    [self addPodcastsToList:[[notif userInfo] valueForKey:kPodcastResultsKey]];
}

-(void)addPodcastsToList:(NSArray *)podcasts {
    NSInteger startingRow = [self.podcastList count];
    NSInteger podcastCount = [podcasts count];
    NSMutableArray *indexPaths = [[NSMutableArray alloc] initWithCapacity:podcastCount];
    
    for(NSInteger row = startingRow; row < (startingRow + podcastCount); row++){
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
        [indexPaths addObject:indexPath];
    }
    
    [self.podcastList addObjectsFromArray:podcasts];
    [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - UITableViewDelagate
//# of rows is equal to number of podcasts in array
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [self.podcastList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // for the cell I need the title, author, and date.
    static NSString *cellDQ = @"DQ";
    
    cell = [tableView dequeueReusableCellWithIdentifier:cellDQ forIndexPath:indexPath];
    // Configure the cell...
    
    //get specefic podcast
    rcfPodcast *podcast = [self.podcastList objectAtIndex:indexPath.row];
    NSLog(@"Podcast being populated: %@", podcast);
    
    //set up downloadButtonimage
//    [imageview setUserInteractionEnabled:YES];
//    UITapGestureRecognizer *singleTap =  [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapping:)];
//    [singleTap setNumberOfTapsRequired:1];
//    [imageview addGestureRecognizer:singleTap];
    
    [cell.downloadButton addTarget:self action:@selector(downloadItem:) forControlEvents:UIControlEventTouchUpInside];
    [cell setTag:indexPath.row];
    [cell.downloadButton setTag:indexPath.row];
    NSLog(@"cellTag: %ld : downloadbtn: %ld", (long)cell.tag, (long)cell.downloadButton.tag);
    cell.progressIndicator.hidden = YES;
    [cell configureWithPodcast:podcast];
    
    if(cell.tag == self.currentlyDownloading){
        cell.progressIndicator.hidden = NO;
        [cell.downloadButton setTitle:@"Cancel" forState:UIControlStateNormal];
    }
    return cell;
}

//when a user taps a item in the table, display a new view with the podcast information
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //load a new view initialized with contents of podcast episode;
   // rcfPodcastDetailView * detailView = [[rcfPodcastDetailView alloc] init];
//    rcfPodcast *podcast = [self.podcastList objectAtIndex:indexPath.row];
//    self.podcast = podcast;
//    [detailView initWithPodcast:podcast];
  //  [self.navigationController pushViewController:detailView animated:YES];
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([segue.identifier isEqualToString:@"PodcastList2Detail"])
    {
        NSIndexPath *myIndexPath = [self.tableView indexPathForSelectedRow];
        rcfPodcastDetailView *controller = [segue destinationViewController];
        controller.podcast = [self.podcastList objectAtIndex:myIndexPath.row];
        controller.audioPlayer = self.audioPlayer;
        NSLog(@"sending audioPlayer, %@, to detailView", self.audioPlayer);
            
    }

}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    
    return 1;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}





- (void)downloadItem:(UITapGestureRecognizer *) sender{
    
    UIButton *button = (UIButton *)sender;
    NSLog(@"the tag clicked %ld",(long)button.tag);
//    button.titleLabel.text = @"Downloading...";
    rcfPodcast *podcast = [self.podcastList objectAtIndex:button.tag];
    NSString *url = podcast.guidlink;
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    if(self.backgroundTask){
        [self.backgroundTask cancel];
        self.backgroundTask = nil;
        [button setTitle:@"Download" forState:UIControlStateNormal];
        return;
    }
    self.backgroundTask = [self.backgroundSession downloadTaskWithRequest:request];
    self.currentlyDownloading = button.tag;
    
    // Start the download
    [self.backgroundTask resume];

    
    self.indexpath = [NSIndexPath indexPathForRow:button.tag inSection:0];
    rcfPodcastTableViewCell *acell = (rcfPodcastTableViewCell *)[self.tableView cellForRowAtIndexPath:self.indexpath];
    NSArray *aArray = [NSArray arrayWithObject:self.indexpath];
    acell.downloadButton.titleLabel.text = @"...";
    [self.tableView reloadRowsAtIndexPaths:aArray withRowAnimation:UITableViewRowAnimationFade];

}

- (NSURLSession *)backgroundSession
{
    static NSURLSession *backgroundSession = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"com.micahgemmell.rcf.Refuge Christian Fellowship.BackgroundSession"];
        
        backgroundSession = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    });
    return backgroundSession;
}

#pragma mark - NSURLSessionDownloadDelegate methods
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    double currentProgress = totalBytesWritten / (double)totalBytesExpectedToWrite;
    dispatch_async(dispatch_get_main_queue(), ^{
        [cell setTheProgressIndicator:(double)currentProgress with:self.currentlyDownloading];
        NSLog(@"tag currently... %ld", (long)self.currentlyDownloading);
        NSLog(@"downloading byte %f of %lld", currentProgress, totalBytesExpectedToWrite);
    });
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes
{
    // Leave this for now
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    // We've successfully finished the download. Let's save the file
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSArray *URLs = [fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *documentsDirectory = URLs[0];
    
    NSURL *destinationPath = [documentsDirectory URLByAppendingPathComponent:[location lastPathComponent]];
    NSError *error;
    NSLog(@"DestinationPath=%@", destinationPath);
    
    // Make sure we overwrite anything that's already there
    [fileManager removeItemAtURL:destinationPath error:NULL];
    BOOL success = [fileManager copyItemAtURL:location toURL:destinationPath error:&error];
    
    if (success)
    {
        NSLog(@"finished downloading: %@", location);
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"%@", [destinationPath path]);
        });
    }
    else
    {
        NSLog(@"Couldn't copy the downloaded file");
    }
    
    if(downloadTask == cancellableTask) {
        cancellableTask = nil;
    } else if (downloadTask == self.resumableTask) {
        self.resumableTask = nil;
        partialDownload = nil;
    } else if (session == self.backgroundSession) {
        self.backgroundTask = nil;
        // Get hold of the app delegate
        
        rcfAppDelegate *appDelegate = (rcfAppDelegate *)[[UIApplication sharedApplication] delegate];
        if(appDelegate.backgroundURLSessionCompletionHandler) {
            // Need to copy the completion handler
            void (^handler)() = appDelegate.backgroundURLSessionCompletionHandler;
            appDelegate.backgroundURLSessionCompletionHandler = nil;
            handler();
        }
    }
    
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        cell.progressIndicator.hidden = YES;
    });
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

-(void)dealloc {
    //no longer interested in these notifcations
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kAddPodcastEpisodeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kPodcastErrorNotification object:nil];
}

@end
