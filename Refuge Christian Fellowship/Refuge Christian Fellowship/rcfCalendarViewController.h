//
//  rcfSecondViewController.h
//  Refuge Christian Fellowship
//
//  Created by Micah Gemmell on 5/20/14.
//  Copyright (c) 2014 RefugeCF. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VRGCalendarView.h"
@class MXLCalendar;
@class MXLCalendarManager;

@interface rcfCalendarViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, VRGCalendarViewDelegate> {
    
//    IBOutlet UITableView *eventsTableView;
    MXLCalendar *currentCalendar;
    MXLCalendarManager *calendarManager;
    NSDate *selectedDate;
    NSMutableDictionary *savedDates;
    
    NSMutableArray *currentEvents;
}

+(void)requestAccess:(void (^)(BOOL granted, NSError *error))callback;

@end
