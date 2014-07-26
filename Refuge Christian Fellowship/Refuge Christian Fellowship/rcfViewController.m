
//
//  rcfSecondViewController.m
//  Refuge Christian Fellowship
//
//  Created by Micah Gemmell on 5/20/14.
//  Copyright (c) 2014 RefugeCF. All rights reserved.
//

#import "rcfViewController.h"
#import "MXLCalendarManager.h"
#import "MBProgressHUD.h"
#import "NSDate+convenience.h"

@interface rcfViewController ()

@property (nonatomic) VRGCalendarView *vrgcal;

@end

@implementation rcfViewController

-(void)calendarView:(VRGCalendarView *)calendarView switchedToMonth:(int)month year:(int)year numOfDays:(int)days targetHeight:(float)targetHeight animated:(BOOL)animated {
    // If this month hasn't already loaded and been cached, start loading events
    NSLog(@"savedDates: %@", [[savedDates objectForKey:[NSNumber numberWithInt:year]] objectForKey:[NSNumber numberWithInt:month]]);
    savedDates = nil;
    if (![[savedDates objectForKey:[NSNumber numberWithInt:year]] objectForKey:[NSNumber numberWithInt:month]]) {
        
        // Show a loading HUD (https://github.com/jdg/MBProgressHUD)
        MBProgressHUD *loadingHUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [loadingHUD setMode:MBProgressHUDModeIndeterminate];
        [loadingHUD setLabelText:@"Loading..."];
        
        // Check the month on a background thread
        dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            NSMutableArray *daysArray = [[NSMutableArray alloc] init];
            
            // Create a formatter to provide the date
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"yyyyddMM"];
            
            // For this initial check, all we need to know is whether there's at least ONE event on each day, nothing more.
            // So we loop through each event...
            for (MXLCalendarEvent *event in currentCalendar.events) {
                NSLog(@"events: %@", event);
                NSDateComponents *components = [[NSCalendar currentCalendar] components:NSMonthCalendarUnit | NSDayCalendarUnit fromDate:[event eventStartDate]];
                
                // If the event starts this month, add it to the array
                if ([components month] == month) {
                    [daysArray addObject:[NSNumber numberWithInteger:[components day]]];
                    [currentCalendar addEvent:event onDateString:[dateFormatter stringFromDate:[event eventStartDate]]];
                    NSLog(@"dateString: %@", [dateFormatter stringFromDate:[event eventStartDate]]);
                } else {
                    // We loop through each day, check if there's an event already there
                    // and if there is, we move onto the next one and repeat until we find a day WITHOUT an event on.
                    // Then we check if this current event occurs then.
                    // This is a way of reducing the number of checkDate: runs we need to do. It also means the algorithm speeds up as it progresses
                    for (int i = 1; i <= days; i++) {
                        if (![daysArray containsObject:[NSNumber numberWithInt:i]]) {
                            if ([event checkDay:i month:month year:year]) {
                                [daysArray addObject:[NSNumber numberWithInteger:i]];
                                [currentCalendar addEvent:event onDay:i month:month year:year];
                            }
                        }
                    }
                }
            }
            
            // Cache the events
            if (![savedDates objectForKey:[NSNumber numberWithInt:year]]) {
                [savedDates setObject:[NSMutableDictionary dictionaryWithObject:@[] forKey:[NSNumber numberWithInt:month]] forKey:[NSNumber numberWithInt:year]];
            }
            [[savedDates objectForKey:[NSNumber numberWithInt:year]] setObject:daysArray forKey:[NSNumber numberWithInt:month]];
            
            // Refresh the UI on main thread
            dispatch_async( dispatch_get_main_queue(), ^{
                [calendarView markDates:daysArray];
                NSLog(@"daysArray: %@", daysArray.description);
                [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            });
        });
    } else {
        // If it's already cached, we're done
        [calendarView markDates:[[savedDates objectForKey:[NSNumber numberWithInt:year]] objectForKey:[NSNumber numberWithInt:month]]];
    }
}

-(void)calendarView:(VRGCalendarView *)calendarView dateSelected:(NSDate *)date {
    // Check if all the events on this day have loaded
    NSLog(@"the actual date is: %@", date);
    if (![currentCalendar hasLoadedAllEventsForDate:date]) {
        // If not, show a loading HUD
        MBProgressHUD *progressHUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [progressHUD setMode:MBProgressHUDModeIndeterminate];
        [progressHUD setLabelText:@"Loading..."];
    }
    
    // Run on a background thread
    dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // If the day hasn't already loaded events...
        if (![currentCalendar hasLoadedAllEventsForDate:date]) {
            // Loop through each event and check whether it occurs on the selected date
            for (MXLCalendarEvent *event in currentCalendar.events) {
                // If it does, save it for the date
                if ([event checkDate:date]) {
                    [currentCalendar addEvent:event onDate:date];
                }
            }
            // Set that the calendar HAS loaded all the events for today
            [currentCalendar loadedAllEventsForDate:date];
        }
        
        // load up the events for today
        currentEvents = [currentCalendar eventsForDate:date];
        //        NSUInteger count = 0;
        //        for (MXLCalendarEvent *event in currentCalendar.events) {
        //            NSLog(@"object: %@, %lu", event.eventSummary, (unsigned long)count);
        //            count++;
        //            if(!(event.eventStartDate)){
        //                count--;
        //                NSLog(@"removing %@ count: %lu", event.eventSummary, count);
        //                [[currentCalendar eventsForDate:date] removeObjectAtIndex:count];
        //            }
        //        }
        //        currentEvents = [currentCalendar eventsForDate:date];
        
        NSLog(@"current, %@", currentEvents.description);
        
        // Refresh UI
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            NSLog(@"How did date become this? %@", date);
            selectedDate = date;
            [eventsTableView reloadData];
        });
    });
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [currentEvents count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        [cell.textLabel setAdjustsFontSizeToFitWidth:YES];
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm:ss"];
    
    NSString *string = [NSString stringWithFormat:@"%@ – %@", [[currentEvents objectAtIndex:indexPath.row] eventSummary], [dateFormatter stringFromDate:[[currentEvents objectAtIndex:indexPath.row] eventStartDate]]];
    [cell.textLabel setText:string];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MXLCalendarEvent *currentEvent = [[currentCalendar eventsForDate:selectedDate] objectAtIndex:indexPath.row];
    
    NSLog(@"Event: %@", currentEvent.eventDescription);
    NSLog(@"Event ID: %@", currentEvent.eventUniqueID);
    NSLog(@"Descr: %@", currentEvent.eventSummary);
    NSLog(@"Start: %@", currentEvent.eventStartDate);
    NSLog(@"End  : %@", currentEvent.eventEndDate);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    savedDates = [[NSMutableDictionary alloc] init];
    
    self.vrgcal = [[VRGCalendarView alloc] init];
    [self.vrgcal setFrame:CGRectMake(0.0f, 20.0f, 320.0f, 320.0f)];
    [self.vrgcal setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"PDT"]];
    
    [self.vrgcal setDelegate:self];
    [self.view addSubview:self.vrgcal];
    eventsTableView.delegate = self;
    eventsTableView.dataSource = self;
    
    MXLCalendarManager *calendarManager = [[MXLCalendarManager alloc] init];
    NSURL *url = [NSURL URLWithString:@"https://www.google.com/calendar/ical/1jq6o2vq83ep2vqhce4q194jdk%40group.calendar.google.com/private-e83371d9b013453954693b3b871fc027/basic.ics"];
    
    [calendarManager scanICSFileAtRemoteURL:url withCompletionHandler:^(MXLCalendar *calendar, NSError *error) {
        currentCalendar = [[MXLCalendar alloc] init];
        currentCalendar = calendar;
        NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:[NSDate date]];
        NSLog(@"calaendar %@", self.vrgcal.description);
        [self calendarView:self.vrgcal switchedToMonth:[components month] year:[components year] numOfDays:[[NSDate date] numDaysInMonth] targetHeight:[self.vrgcal calendarHeight] animated:NO];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [eventsTableView reloadData];
            
        });
    }];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
