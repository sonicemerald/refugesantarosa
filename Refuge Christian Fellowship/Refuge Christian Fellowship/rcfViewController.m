
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
#import <EventKit/EventKit.h>

@interface rcfViewController ()

@property (nonatomic) VRGCalendarView *vrgcal;
@property (nonatomic) MXLCalendarEvent *currentEvent;

@end

static EKEventStore *eventStore = nil;

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
    
    self.currentEvent = currentEvent;
//    [self setUpCalendarWithEvent:self.currentEvent];
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:currentEvent.eventDescription
                                                      message:currentEvent.eventSummary
                                                     delegate:self
                                            cancelButtonTitle:@"Ok"
                                            otherButtonTitles:@"Add to Calendar", nil];
    [message show];
    
//    EKEventStore *store = [[EKEventStore alloc] init];
    
    NSLog(@"Event: %@", currentEvent.eventDescription);
    NSLog(@"Event ID: %@", currentEvent.eventUniqueID);
    NSLog(@"Descr: %@", currentEvent.eventSummary);
    NSLog(@"Start: %@", currentEvent.eventStartDate);
    NSLog(@"End  : %@", currentEvent.eventEndDate);
}

//Store Event to phone's calendar.
+ (void)requestAccess:(void (^)(BOOL granted, NSError *error))callback;
{
    if (eventStore == nil) {
        eventStore = [[EKEventStore alloc] init];
    }
    // request permissions
    [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:callback];
}

-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 1) {
        [alertView dismissWithClickedButtonIndex:0 animated:NO];
        
        
        [self setUpCalendarWithEvent:self.currentEvent];
    }

}
-(BOOL) setUpCalendarWithEvent:(MXLCalendarEvent *)curEvent{
    NSLog(@"setting up calendar");
    EKEvent *event = [EKEvent eventWithEventStore:eventStore];
    EKCalendar *calendar = nil;
    NSString *calendarIdentifier = [[NSUserDefaults standardUserDefaults] valueForKey:@"refugeEventsCalendar"];
    
    // when identifier exists, my calendar probably already exists
    // note that user can delete my calendar. In that case I have to create it again.
    if (calendarIdentifier) {
        calendar = [eventStore calendarWithIdentifier:calendarIdentifier];
    }
    
    // calendar doesn't exist, create it and save it's identifier
    if (!calendar) {
        calendar = [EKCalendar calendarForEntityType:EKEntityTypeEvent eventStore:eventStore];
        
        // set calendar name. This is what users will see in their Calendar app
        // [calendar setTitle:[KKCalendar calendarName]];
        [calendar setTitle:@"RefugeCF"];
        
        // find appropriate source type. I'm interested only in local calendars but
        // there are also calendars in iCloud, MS Exchange, ...
        // look for EKSourceType in manual for more options
        for (EKSource *s in eventStore.sources) {
            if (s.sourceType == EKSourceTypeLocal) {
                calendar.source = s;
                break;
            }
        }
        
        // save this in NSUserDefaults data for retrieval later
        NSString *calendarIdentifier = [calendar calendarIdentifier];
        
        NSError *error = nil;
        BOOL saved = [eventStore saveCalendar:calendar commit:YES error:&error];
        if (saved) {
            NSLog(@"saved event");
            [[NSUserDefaults standardUserDefaults] setObject:calendarIdentifier forKey:@"refugeEventsCalendar"];
        } else {
            // unable to save calendar
            return NO;
        }
    }
    
    // this shouldn't happen
    if (!calendar) {
        return NO;
    }

    // assign basic information to the event; location is optional
    event.calendar = calendar;
    event.title = curEvent.eventDescription;
    event.notes = curEvent.eventSummary;
    event.startDate = curEvent.eventStartDate;
    event.endDate = curEvent.eventEndDate;
    event.location = curEvent.eventLocation;
    
//    NSURL *url = [NSURL URLWithString:@"calshow://"];
//    [[UIApplication sharedApplication] openURL:url];
    
    NSError *error = nil;
    // save event to the callendar
    BOOL result = [eventStore saveEvent:event span:EKSpanThisEvent commit:YES error:&error];
    if (result) {
        return YES;
    } else {
        NSLog(@"Error saving event: %@", error);
        // unable to save event to the calendar
        return NO;
    }
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
    NSURL *url = [NSURL URLWithString:@"http://www.google.com/calendar/ical/refugecf.com_eovqll344uloicj5ckkv8qpv30%40group.calendar.google.com/private-cbfebf6d4c4e241205cfe2a96603ce1f/basic.ics"];
    
    [calendarManager scanICSFileAtRemoteURL:url withCompletionHandler:^(MXLCalendar *calendar, NSError *error) {
        currentCalendar = [[MXLCalendar alloc] init];
        currentCalendar = calendar;
        NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:[NSDate date]];
        [self calendarView:self.vrgcal switchedToMonth:[components month] year:[components year] numOfDays:[[NSDate date] numDaysInMonth] targetHeight:[self.vrgcal calendarHeight] animated:NO];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [eventsTableView reloadData];
            
        });
    }];
    // Do any additional setup after loading the view, typically from a nib.
    
    [rcfViewController requestAccess:^(BOOL granted, NSError *error) {
        if (granted) {
            NSLog(@"granted access");
        } else {
            NSLog(@"no premissions to use calendar");
            // you don't have permissions to access calendars
        }
    }];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
