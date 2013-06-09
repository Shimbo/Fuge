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
@interface NewMeetupViewController : UIViewController <UITextFieldDelegate,UIGestureRecognizerDelegate>
{
    IBOutlet UITextField *subject;
    IBOutlet UIButton *dateBtn;
    IBOutlet UIButton *location;
    IBOutlet UISwitch *notifySwitch;
    IBOutlet UIActivityIndicatorView *activityIndicator;
    UINavigationController *venueNavViewController;
    UIActionSheet *actionSheet;
    UIDatePicker *datePicker;
    NSDate* meetupDate;
    Meetup* meetup;
    Person* invitee;
    NSUInteger meetupType;
}

@property (nonatomic,strong) FSVenue* selectedVenue;

- (IBAction)selectDateBtn:(id)sender;
- (IBAction)venueButton:(id)sender;
- (IBAction)privacyChanged:(id)sender;

-(void) setMeetup:(Meetup*)m;
-(void) setInvitee:(Person*)i;
-(void) setType:(NSUInteger)t;

@end