//
//  NewEventViewController.h
//  SecondCircle
//
//  Created by Mikhail Larionov on 1/5/13.
//
//

#import <UIKit/UIKit.h>
#import "FUGEvent.h"
#import "Person.h"

@class FSVenue;

@class MeetupInviteViewController;
@interface NewMeetupViewController : UIViewController <UITextFieldDelegate,UIGestureRecognizerDelegate, UIPickerViewDelegate, UIPickerViewDataSource>
{
    IBOutlet UITextField *subject;
    IBOutlet UIButton *dateBtn;
    IBOutlet UIButton *durationBtn;
    IBOutlet UIButton *location;
    IBOutlet UISwitch *privacySwitch;
    IBOutlet UIActivityIndicatorView *activityIndicator;
    UINavigationController *venueNavViewController;
    UIDatePicker *datePicker;
    UIPickerView *durationPicker;
    UIPopoverController*    popover;
    UIActionSheet*          actionSheet;
    NSDate* meetupDate;
    NSUInteger meetupDurationDays;
    NSUInteger meetupDurationHours;
    NSUInteger meetupIcon;
    FUGEvent* meetup;
    Person* invitee;
    NSUInteger meetupType;
    
    IBOutlet UIScrollView *scrollView;
    UITextField* activeField;
    IBOutlet UILabel *priceText;
    IBOutlet UILabel *maxGuestsText;
    IBOutlet UITextField *priceField;
    IBOutlet UITextField *maxGuestsField;
    IBOutlet UITextField *imageURLField;
    IBOutlet UITextField *originalURLField;
    IBOutlet UITextField *descriptionText;
    IBOutlet UIButton *iconButton;
    
    Boolean bLocationChanged, bDateChanged, bDurationChanged;
}

@property (nonatomic,strong) FSVenue* selectedVenue;

- (IBAction)selectDateBtn:(id)sender;
- (IBAction)durationButton:(id)sender;
- (IBAction)venueButton:(id)sender;
- (IBAction)privacyChanged:(id)sender;
- (IBAction)iconChanged:(id)sender;

-(void) setMeetup:(FUGEvent*)m;
-(void) setInvitee:(Person*)i;
-(void) setType:(NSUInteger)t;

@end