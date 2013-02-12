
#import "MainViewController.h"

@interface RootViewController : MainViewController {
    
    UIActivityIndicatorView* activityIndicator;
}

@property (nonatomic,retain) IBOutlet UITableView *tableView;
- (void) reloadData;
- (void) reloadFinished;

@property (nonatomic, retain) UIActivityIndicatorView *activityIndicator;

@property BOOL initialized;


@end