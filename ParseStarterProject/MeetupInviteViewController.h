//
//  MeetupInviteViewController.h
//  SecondCircle
//
//  Created by Constantine Fry on 3/8/13.
//
//

#import <UIKit/UIKit.h>


@class MeetupInviteSearch;
@interface MeetupInviteViewController : UIViewController{
    MeetupInviteSearch *searcher;
    NSMutableDictionary *selected;
}
@property (strong, nonatomic) IBOutlet UITableView *tableView;



-(NSArray*)selectedPersons;


@end
