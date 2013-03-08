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

@class MeetupInviteViewController;
@interface NewMeetupViewController : UIViewController <UITextFieldDelegate>
{
    IBOutlet UITextField *subject;
    IBOutlet UIDatePicker *dateTime;
    IBOutlet UIButton *location;
    IBOutlet UISwitch *notifySwitch;
    UINavigationController *venueNavViewController;
    Meetup* meetup;
    PFUser* invitee;
    
    MeetupInviteViewController *inviteController;
}

@property (nonatomic,strong)FSVenue* selectedVenue;

- (IBAction)venueButtonDown:(id)sender;

-(void) setMeetup:(Meetup*)m;
-(void) setInvitee:(PFUser*)i;

@end