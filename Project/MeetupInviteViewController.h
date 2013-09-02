//
//  MeetupInviteViewController.h
//  SecondCircle
//
//  Created by Constantine Fry on 3/8/13.
//
//

#import <UIKit/UIKit.h>
#import "Meetup.h"
#import "Person.h"

@class MeetupInviteSearch;
@interface MeetupInviteViewController : UIViewController{
    MeetupInviteSearch *searcher;
    NSMutableDictionary *selected;
    Meetup *meetup;
    Boolean bNewMeetup;
    
    NSArray *_recentPersons;
    NSArray *_firstCircle;
    NSArray *_otherPersons;
    NSArray *_facebookFriends;
    
    IBOutlet UITableView *tableViewInvites;
    
    Boolean bSelectAllTurnOn;
}

-(NSArray*)selectedPersons;

-(void)setMeetup:(Meetup*)m newMeetup:(Boolean)new;
-(void)addInvitee:(Person*)i;


@end
