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
    
    MB_TOTAL_COUNT  = 8
};

@interface MeetupViewController : UIViewController <UITextViewDelegate, MKMapViewDelegate>
{
    Meetup* meetup;
    IBOutlet UITextView *comments;
    IBOutlet UITextView *newComment;
    IBOutlet MKMapView *mapView;
    IBOutlet UILabel *labelDate;
    IBOutlet UILabel *labelLocation;
    
    id delegate;
    NSMutableArray*    buttons;
    Boolean invite;
}

-(void) setMeetup:(Meetup*)m;
-(void) setInvite;

@property (nonatomic,strong) id delegate;

@end
