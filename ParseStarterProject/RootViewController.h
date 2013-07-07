
#import "MainViewController.h"

#define sortingModeTitles @[@"Match me!", @"By distance"]
#define SORTING_DISTANCE    0
#define SORTING_RANK        1

@interface RootViewController : MainViewController {
    NSUInteger      sortingMode;
    UIBarButtonItem *matchBtn;
}

@property (nonatomic,retain) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;


@end