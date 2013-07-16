
#import <UIKit/UIKit.h>
#import "Person.h"

@interface MatchesViewController : UIViewController {
    Person* personThis;
    NSMutableArray* matchedFriends;
    NSMutableArray* matchedFriends2O;
    NSMutableArray* matched2OFriends;
    NSArray* matchedLikes;
}

@property (nonatomic,retain) IBOutlet UITableView *tableView;

-(void) setPerson:(Person*)person;

@end
