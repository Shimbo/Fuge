//
//  NewEventViewController.h
//  SecondCircle
//
//  Created by Mikhail Larionov on 1/5/13.
//
//

#import <UIKit/UIKit.h>

@class FSVenue;
@interface NewEventViewController : UIViewController <UITextFieldDelegate>
{
    IBOutlet UITextField *subject;
    IBOutlet UISegmentedControl *privacy;
    IBOutlet UIDatePicker *dateTime;
    IBOutlet UIButton *location;
    IBOutlet UISwitch *notifySwitch;
    UINavigationController *venueNavViewController;
}

@property (nonatomic,strong)FSVenue* selectedVenue;

- (IBAction)cancelButtonDown:(id)sender;
- (IBAction)createButtonDown:(id)sender;
- (IBAction)venueButtonDown:(id)sender;
- (IBAction)notifySwitched:(id)sender;
- (IBAction)privacySwitched:(id)sender;

@end