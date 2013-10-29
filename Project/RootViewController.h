
#import "MainViewController.h"

#define sortingModeTitles @[@"Match me!", @"By distance", @"Engagement"]

typedef enum ESortingRank
{
    SORTING_RANK        = 0,
    SORTING_DISTANCE    = 1,
    SORTING_ENGAGEMENT  = 2,
    
    SORTING_MODES_COUNT = 3
}SortingRank;

@class Person;
@interface RootViewController : MainViewController <UIPickerViewDelegate, UIPickerViewDataSource, UIActionSheetDelegate, UISearchBarDelegate>
{
    NSUInteger      sortingMode;
    UIBarButtonItem *matchBtn;
    NSMutableArray  *sortedUsers;
    NSMutableArray  *usersHereNow;
    NSMutableArray  *usersNearbyToday;
    NSMutableArray  *usersRecent;
    Person          *_currentPerson;
    UIRefreshControl *refreshControl;
    
    UIBarButtonItem*        filterButton;
    UIPopoverController*    popover;
    UIActionSheet*          actionSheet;
    NSMutableArray*         filterButtonLabels;
    NSMutableArray*         filterSelectionLabels;
    NSUInteger              filterSelector;
    
    NSString                *searchString;
    
    IBOutlet UITableView    *tableView;
    IBOutlet UISearchBar    *searchView;
    IBOutlet UIActivityIndicatorView *activityIndicator;
}

//@property (nonatomic,retain) IBOutlet UITableView *tableView;
//@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end