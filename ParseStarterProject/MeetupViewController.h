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

@interface MeetupViewController : UIViewController <UITextViewDelegate>
{
    Meetup* meetup;
    __unsafe_unretained IBOutlet UITextView *comments;
    __unsafe_unretained IBOutlet UITextView *newComment;
}

-(void) setMeetup:(Meetup*)m;

@end
