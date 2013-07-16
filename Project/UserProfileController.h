//
//  UserProfileController.h
//  SecondCircle
//
//  Created by Mikhail Larionov on 12/2/12.
//
//

#import <UIKit/UIKit.h>
#import "Person.h"
#import "GrowingTextViewController.h"

@class AsyncImageView;
@class Message;
@interface UserProfileController : GrowingTextViewController <UIAlertViewDelegate>
{
    Person* personThis;
    IBOutlet UITextView *messageHistory;
    UIBarButtonItem *buttonProfile;
    IBOutlet UILabel *labelFriendName;
    IBOutlet UILabel *labelDistance;
    IBOutlet UILabel *labelCircle;
    IBOutlet UILabel *labelTimePassed;
    IBOutlet UIButton *btnThingsInCommon;
    NSUInteger  nThingsInCommon;
    
    NSUInteger  messagesCount;
    IBOutlet FBProfilePictureView *profileImageView;
    
    Message*    currentMessage;
}

@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
- (IBAction)showMatchesList:(id)sender;

-(void) setPerson:(Person*)person;

@end