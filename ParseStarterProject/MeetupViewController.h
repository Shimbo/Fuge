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

@interface MeetupViewController : UIViewController <UITextViewDelegate, MKMapViewDelegate>
{
    Meetup* meetup;
    PFObject* invite;
    IBOutlet UITextView *comments;
    IBOutlet UITextView *newComment;
    IBOutlet MKMapView *mapView;
    IBOutlet UILabel *labelDate;
    IBOutlet UILabel *labelLocation;
    
    id delegate;
}

-(void) setMeetup:(Meetup*)m;
-(void) setInvite:(PFObject*)i;

@property (nonatomic,strong) id delegate;

@end
