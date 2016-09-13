//
//  ViewController.m
//  CalendarTest
//
//  Created by James Rochabrun on 9/6/16.
//  Copyright © 2016 James Rochabrun. All rights reserved.
//

#import "ViewController.h"
#import <EventKit/EventKit.h>


@interface ViewController ()<UITextFieldDelegate>
@property (nonatomic, strong) UIButton *eventbutton;
@property (nonatomic, assign) BOOL eventExists;
@property NSString *eventSavedId;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UILabel *eventLabel;
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, strong) EKEventStore *eventStore;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _eventbutton = [UIButton new];
    [_eventbutton addTarget:self action:@selector(onEventbuttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [_eventbutton setTitle:@"Add Event" forState:UIControlStateNormal];
    [_eventbutton setBackgroundColor:[UIColor orangeColor]];
    [self.view addSubview:_eventbutton];
    
    _textField = [UITextField new];
    _textField.backgroundColor = [UIColor yellowColor];
    [self.view addSubview:_textField];
    
    _eventLabel = [UILabel new];
    [self.view addSubview:_eventLabel];
    _eventLabel.textAlignment = NSTextAlignmentCenter;
    
    _deleteButton = [UIButton new];
    [_deleteButton addTarget:self action:@selector(deleteEvent:) forControlEvents:UIControlEventTouchUpInside];
    [_deleteButton setTitle:@"Delete" forState:UIControlStateNormal];
    [_deleteButton setBackgroundColor:[UIColor blackColor]];
    [self.view addSubview:_deleteButton];
    
    _eventStore = [EKEventStore new];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillLayoutSubviews {
    
    [super viewWillLayoutSubviews];
   
    CGRect frame = _eventbutton.frame;
    frame.size.width = 100;
    frame.size.height = 50;
    frame.origin.x = (self.view.frame.size.width - 100) / 2;
    frame.origin.y = self.view.frame.size.height / 2;
    _eventbutton.frame = frame;
    
    frame = _deleteButton.frame;
    frame.size.width = 100;
    frame.size.height = 50;
    frame.origin.x = (self.view.frame.size.width - 100) / 2;
    frame.origin.y = self.view.frame.size.height / 2 + 50;
    _deleteButton.frame = frame;
    
    frame = _textField.frame;
    frame.size.height  = 40;
    frame.size.width = 200;
    frame.origin.x = (self.view.frame.size.width - 200) / 2;
    frame.origin.y =  self.view.frame.size.height / 3.5;
    _textField.frame = frame;
    
    frame = _eventLabel.frame;
    frame.size.width = 200;
    frame.size.height = 40;
    frame.origin.x = (self.view.frame.size.width - 200) / 2;
    frame.origin.y = self.view.frame.size.height / 1.5;
    _eventLabel.frame = frame;
    
}

- (void)onEventbuttonTapped:(UIButton *)sender {
    
    if([_eventStore respondsToSelector:@selector(requestAccessToEntityType:completion:)]) {
        [_eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
            
            if (granted){
                [self ifUserAllowsCalendarPermission];
            }
            else
            {
                [self ifUserDontAllowCallendarPermission];
            }
        }];
    }
}

- (void)ifUserAllowsCalendarPermission {
    
    __weak ViewController *weakSelf = self;
    
    dispatch_async(dispatch_get_main_queue(), ^(void){
        
        UIAlertController *modalAlert = [UIAlertController alertControllerWithTitle:@"Save Event in your calendar?"
                                                                            message:@"You will be notified 1 hour before the Event starts"
                                                                     preferredStyle:UIAlertControllerStyleActionSheet];
        
        UIAlertAction *saveDate = [UIAlertAction actionWithTitle:@"Save"
                                                           style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                                               [weakSelf saveEventInCalendar];
                                                           }];//save data block end
        
        UIAlertAction *dontSaveDate = [UIAlertAction actionWithTitle:@"Cancel"
                                                               style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                                                   // NSLog(@"date dont saved");
                                                                   
                                                               }];
        [modalAlert addAction:saveDate];
        [modalAlert addAction:dontSaveDate];
        [weakSelf presentViewController:modalAlert animated:YES completion:nil];
    });
}

- (void)saveEventInCalendar {
    
    EKEvent *event = [EKEvent eventWithEventStore:_eventStore];
    event.title = _textField.text;
    event.notes = @"dont forget this event!!";
    
    NSDate *now = [NSDate date];
    event.startDate = now;
    
    event.endDate   = [[NSDate alloc] initWithTimeInterval:5400 sinceDate:event.startDate];
    event.URL = [NSURL URLWithString:@"https://itunes.apple.com/us/app/oomami/id1053373398?ls=1&mt=8"];
    [event setCalendar:[_eventStore defaultCalendarForNewEvents]];
    EKAlarm *alarm=[EKAlarm alarmWithRelativeOffset:-3600];
    [event addAlarm:alarm];
    
    [self checkIfEventExistswithEvent:event];
    
    if(!self.eventExists){
        NSError *err;
        BOOL save = [_eventStore saveEvent:event span:EKSpanThisEvent error:&err];
        self.eventSavedId = event.eventIdentifier;
        
        if (save) {
            NSLog(@"event saved this is the id %@" , self.eventSavedId);
            [self alertUserThatEventIsSaved];
        }
    }else{
        NSLog(@"this event is already saved %@ ", event.title);
        
        [self alertUserThatEventWasAlreadySaved];
    }
    
    _eventLabel.text = event.title;
}

- (void)checkIfEventExistswithEvent:(EKEvent*)event {
    
    NSPredicate *predicate = [_eventStore predicateForEventsWithStartDate:event.startDate endDate:event.endDate calendars:nil];
    NSArray *eventsOnDate = [_eventStore eventsMatchingPredicate:predicate];
    self.eventExists  = NO;
    [eventsOnDate enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        EKEvent *eventToCheck = (EKEvent*)obj;
        if([event.title isEqualToString:eventToCheck.title])
        {
            self.eventExists = YES;
            *stop = YES;
        }
    }];
}

- (void)alertUserThatEventWasAlreadySaved {
    
    __weak ViewController *weakSelf = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle: @"this event its already added to your calendar"
                                                                       message: nil
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [weakSelf presentViewController:alert animated:YES completion:nil];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [alert dismissViewControllerAnimated:YES completion:nil];
        });
    });
}

- (void)ifUserDontAllowCallendarPermission {
    
    __weak ViewController *weakSelf = self;

    dispatch_async(dispatch_get_main_queue(), ^(void){
        UIAlertController *settingAlert = [UIAlertController alertControllerWithTitle:@"Please go to your app settings and allow us to acces your calendar"
                                                                              message:@"You don't want to miss this event, do you?"
                                                                       preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel"
                                                         style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                                             //NSLog(@"ill do it later");
                                                         }];
        UIAlertAction *go = [UIAlertAction actionWithTitle:@"Go"
                                                     style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                                         [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                                                     }];
        
        [settingAlert addAction:cancel];
        [settingAlert addAction:go];
        [weakSelf presentViewController:settingAlert animated:YES completion:nil];
    });
}


- (void)alertUserThatEventIsSaved {
    
    __weak ViewController *weakSelf = self;
    
    dispatch_async(dispatch_get_main_queue(), ^(void){
        UIAlertController *alert = [UIAlertController alertControllerWithTitle: @"Saved!"
                                                                       message: nil
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [weakSelf presentViewController:alert animated:YES completion:nil];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [alert dismissViewControllerAnimated:YES completion:nil];
        });
    });
}

- (void)deleteEvent:(UIButton *)sender {
    
    EKEvent *eventToDelete = [_eventStore eventWithIdentifier:_eventSavedId];

    if (eventToDelete != nil) {
        NSError* error = nil;
        [_eventStore removeEvent:eventToDelete span:EKSpanThisEvent error:&error];
        NSLog(@"the event %@, was deleted", eventToDelete.title);

    }
    
}







@end
