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
#import "CommentsView.h"

enum EUserProfileMode
{
    PROFILE_MODE_MESSAGES   = 0,
    PROFILE_MODE_SUMMARY    = 1
};

@class AsyncImageView;
@class Message;
@interface UserProfileController : GrowingTextViewController <UIAlertViewDelegate, UIWebViewDelegate>
{
    Person* personThis;
    IBOutlet CommentsView *messagesView;
    UIBarButtonItem *buttonProfile;
    IBOutlet UILabel *labelFriendName;
    IBOutlet UILabel *labelDistance;
    IBOutlet UILabel *labelStatus;
    IBOutlet UILabel *labelTimePassed;
    IBOutlet UIButton *btnThingsInCommon;
    NSUInteger  nThingsInCommon;
    
    NSUInteger  profileMode;
    IBOutlet UIWebView *webView;
    
    NSUInteger  messagesCount;
    //IBOutlet FBProfilePictureView *profileImageView;
    IBOutlet AsyncImageView *profileImage;
    IBOutlet UIScrollView *scrollView;
    
    UIBarButtonItem* messageBtn;
    IBOutlet UILabel *strJobInfo;
    IBOutlet UILabel *strIndustry;
    
    Message*    currentMessage;
}

@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
- (IBAction)showMatchesList:(id)sender;

-(void) setPerson:(Person*)person;
-(void) setProfileMode:(NSUInteger)mode;

@end