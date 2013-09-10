
#import <UIKit/UIKit.h>

@interface PeopleViewController : UIViewController {
    NSArray*        idsList;
    NSMutableArray* personList;
}

@property (nonatomic,retain) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

-(void) setIdsList:(NSArray*)people;

@end
