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
}
@property (strong, nonatomic) IBOutlet UITableView *tableView;

-(NSArray*)selectedPersons;

-(void)setMeetup:(Meetup*)m;
-(void)addInvitee:(Person*)i;


@end
