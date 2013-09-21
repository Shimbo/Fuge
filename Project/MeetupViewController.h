//
//  MeetupViewController.h
//  SecondCircle
//
//  Created by Mikhail Larionov on 1/6/13.
//
//

#import <UIKit/UIKit.h>
#import "Meetup.h"
#import <EventKit/EventKit.h>
#import <EventKitUI/EventKitUI.h>
#import <MapKit/MapKit.h>
#import "MeetupAnnotation.h"
#import "PersonAnnotation.h"
#import "CommentsView.h"

@interface CustomScroll : UIScrollView
@end

enum EMeetupButtons
{
    MB_JOIN         = 0,
    MB_SUBSCRIBE    = 1,
    MB_DECLINE      = 2,
    MB_LEAVE        = 3,
    MB_CALENDAR     = 4,
    MB_INVITE       = 5,
    MB_CANCEL       = 6,
    MB_EDIT         = 7,
    MB_FEATURE      = 8,
    
    MB_TOTAL_COUNT  = 9
};
#import "GrowingTextViewController.h"

@interface MeetupViewController : GrowingTextViewController
<UITextViewDelegate, MKMapViewDelegate, UIWebViewDelegate, UITextFieldDelegate>
{
    Meetup* meetup;
    IBOutlet CommentsView *commentsView;
    IBOutlet MKMapView *mapView;
    IBOutlet UILabel *labelDate;
    IBOutlet UILabel *labelLocation;
    IBOutlet UILabel *labelSpotsAvailable;
    IBOutlet UIWebView *descriptionView;
    IBOutlet UIView *peopleCounters;
    IBOutlet UIScrollView *scrollView;
    IBOutlet UIActivityIndicatorView *activityIndicator;    
    IBOutlet UIButton *alertTicketsOnline;
    
    id delegate;
    NSMutableArray*    buttons;
    Boolean invite;
    MeetupAnnotation *currentMeetupAnnotation;
    PersonAnnotation *currentPersonAnnotation;
    
    NSMutableArray  *viewsList;
    IBOutlet UIButton *countersJoined;
    IBOutlet UIButton *countersDeclined;
    IBOutlet UIButton *countersInvited;
    NSMutableArray    *avatarList;
}

-(void) setMeetup:(Meetup*)m;
-(void) setInvite;

@property (nonatomic,strong) id delegate;
- (IBAction)alertTapped:(id)sender;

- (IBAction)countersJoinedTapped:(id)sender;
- (IBAction)countersDeclinedTapped:(id)sender;
- (IBAction)countersInvitedTapped:(id)sender;



@end
