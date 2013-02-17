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
    IBOutlet UITextView *comments;
    IBOutlet UITextView *newComment;
    IBOutlet MKMapView *mapView;
}

-(void) setMeetup:(Meetup*)m;

@end
