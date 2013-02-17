//
//  NewEventViewController.h
//  SecondCircle
//
//  Created by Mikhail Larionov on 1/5/13.
//
//

#import <UIKit/UIKit.h>
#import "Meetup.h"

@class FSVenue;

@interface NewMeetupViewController : UIViewController <UITextFieldDelegate>
{
    IBOutlet UITextField *subject;
    IBOutlet UISegmentedControl *privacy;
    IBOutlet UIDatePicker *dateTime;
    IBOutlet UIButton *location;
    IBOutlet UISwitch *notifySwitch;
    UINavigationController *venueNavViewController;
    Meetup* meetup;
}

@property (nonatomic,strong)FSVenue* selectedVenue;

- (IBAction)venueButtonDown:(id)sender;
- (IBAction)notifySwitched:(id)sender;
- (IBAction)privacySwitched:(id)sender;

-(void) setMeetup:(Meetup*)m;

@end