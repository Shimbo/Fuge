//
//  NewEventViewController.h
//  SecondCircle
//
//  Created by Mikhail Larionov on 1/5/13.
//
//

#import <UIKit/UIKit.h>
#import "Meetup.h"
#import "Person.h"

@class FSVenue;

@class MeetupInviteViewController;
@interface NewMeetupViewController : UIViewController <UITextFieldDelegate,UIGestureRecognizerDelegate, UIPickerViewDelegate, UIPickerViewDataSource>
{
    IBOutlet UITextField *subject;
    IBOutlet UIButton *dateBtn;
    IBOutlet UIButton *durationBtn;
    IBOutlet UIButton *location;
    IBOutlet UISwitch *notifySwitch;
    IBOutlet UIActivityIndicatorView *activityIndicator;
    UINavigationController *venueNavViewController;
    UIDatePicker *datePicker;
    UIPickerView *durationPicker;
    NSDate* meetupDate;
    NSUInteger meetupDurationDays;
    NSUInteger meetupDurationHours;
    Meetup* meetup;
    Person* invitee;
    NSUInteger meetupType;
    
    IBOutlet UIScrollView *scrollView;
    UITextField* activeField;
    IBOutlet UILabel *priceText;
    IBOutlet UITextField *priceField;
    IBOutlet UITextField *imageURLField;
    IBOutlet UITextField *originalURLField;
    IBOutlet UITextField *descriptionText;
}

@property (nonatomic,strong) FSVenue* selectedVenue;

- (IBAction)selectDateBtn:(id)sender;
- (IBAction)durationButton:(id)sender;
- (IBAction)venueButton:(id)sender;
- (IBAction)privacyChanged:(id)sender;

-(void) setMeetup:(Meetup*)m;
-(void) setInvitee:(Person*)i;
-(void) setType:(NSUInteger)t;

@end