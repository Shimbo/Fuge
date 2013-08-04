
#import "MainViewController.h"

#define sortingModeTitles @[@"Match me!", @"By distance", @"Engagement"]

typedef enum ESortingRank
{
    SORTING_RANK        = 0,
    SORTING_DISTANCE    = 1,
    SORTING_ENGAGEMENT  = 2,
    
    SORTING_MODES_COUNT = 3
}SortingRank;

@interface RootViewController : MainViewController {
    NSUInteger      sortingMode;
    UIBarButtonItem *matchBtn;
    NSMutableArray  *arrayEngagementUsers;
    UIRefreshControl *refreshControl;
}

@property (nonatomic,retain) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;


@end