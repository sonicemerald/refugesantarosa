 //
//  rcfBlogTableViewController.m
//  Refuge Christian Fellowship
//
//  Created by Micah Gemmell on 5/20/14.
//  Copyright (c) 2014 RefugeCF. All rights reserved.
//

#import "rcfBlogTableViewController.h"
#import "rcfBlogTableViewCell.h"
#import "rcfBlog.h"
#import "rcfBlogParseOperation.h"
#import "rcfBlogDetailView.h"

@interface rcfBlogTableViewController ()
@property (nonatomic) rcfBlog *Blog;
@property (nonatomic) NSMutableArray *BlogList;
@property (nonatomic) NSOperationQueue *parseQuene;

@end

@implementation rcfBlogTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.BlogList = [NSMutableArray array];
    
    self.tableView.backgroundColor = [UIColor whiteColor];
    [[UIView appearanceWhenContainedIn:[UITabBar class], nil]
     setTintColor:[UIColor colorWithRed:48/255.0f green:113/255.0f blue:121/255.0f alpha:1.0f]];
    
    
    /*
     Use NSURLConnection to asynchronously download the data. This means the main thread will not be blocked - the application will remain responsive to the user.
     
     IMPORTANT! The main thread of the application should never be blocked!
     Also, avoid synchronous network access on any thread.
     */
    static NSString *feedURLString = @"http://refugecf.com/blog-2/feed/";
    NSURLRequest *BlogURLRequest =
    [NSURLRequest requestWithURL:[NSURL URLWithString:feedURLString]];
    
    // send the async request (note that the completion block will be called on the main thread)
    //
    // note: using the block-based "sendAsynchronousRequest" is preferred, and useful for
    // small data transfers that are likely to succeed. If you doing large data transfers,
    // consider using the NSURLConnectionDelegate-based APIs.
    
    [NSURLConnection sendAsynchronousRequest:BlogURLRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
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
                rcfBlogParseOperation *parseOperation = [[rcfBlogParseOperation alloc] initWithData:data];
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addBlogs:) name:kAddBlogPostNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(BlogError:) name:kBlogErrorNotification object:nil];
    
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
-(void)BlogError:(NSNotification *)notif {
    assert(([NSThread isMainThread]));
    [self handleError:[[notif userInfo] valueForKey:kBlogMessageErrorKey]];
}

-(void)addBlogs:(NSNotification *)notif
{
    assert([NSThread isMainThread]);
    [self addBlogsToList:[[notif userInfo] valueForKey:kBlogResultsKey]];
}

-(void)addBlogsToList:(NSArray *)Blogs {
    NSInteger startingRow = [self.BlogList count];
    NSInteger BlogCount = [Blogs count];
    NSMutableArray *indexPaths = [[NSMutableArray alloc] initWithCapacity:BlogCount];
    
    for(NSInteger row = startingRow; row < (startingRow + BlogCount); row++){
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
        [indexPaths addObject:indexPath];
    }
    
    [self.BlogList addObjectsFromArray:Blogs];
    [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - UITableViewDelagate
//# of rows is equal to number of Blogs in array
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [self.BlogList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // for the cell I need the title, author, and date.
    static NSString *cellDQ = @"blogCell";
    
    rcfBlogTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellDQ forIndexPath:indexPath];
    // Configure the cell...
    
    //get specefic Blog
    rcfBlog *Blog = [self.BlogList objectAtIndex:indexPath.row];
    //    rcfBlog *Blog = (self.BlogList)[indexPath.row];
    NSLog(@"Blog being populated: %@", Blog);
    
    [cell configureWithBlog:Blog];
    return cell;
}

//when a user taps a item in the table, display a new view with the Blog information
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //load a new view initialized with contents of Blog Post;
    // rcfBlogDetailView * detailView = [[rcfBlogDetailView alloc] init];
    //    rcfBlog *Blog = [self.BlogList objectAtIndex:indexPath.row];
    //    self.Blog = Blog;
    //    [detailView initWithBlog:Blog];
    //  [self.navigationController pushViewController:detailView animated:YES];
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([segue.identifier isEqualToString:@"BlogPost2Detail"])
    {
        NSIndexPath *myIndexPath = [self.tableView indexPathForSelectedRow];
        rcfBlogDetailView *controller = [segue destinationViewController];
        controller.Blog = [self.BlogList objectAtIndex:myIndexPath.row];
    }
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    
    return 1;
}

//- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
//{
//    if( section == 0 )
//        return 65;
//    return 45;
//}
//
//- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
//{
//    NSString *text = @"Blogs";
//    return text;
//}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kAddBlogPostNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kBlogErrorNotification object:nil];
}

@end
