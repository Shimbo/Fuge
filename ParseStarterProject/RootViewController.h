
@interface RootViewController : UITableViewController {
	NSArray *displayList;
    Boolean initialized;
    UIBarButtonItem* buttonProfile;
    UIBarButtonItem* buttonFilter;
    
    UIActivityIndicatorView* activityIndicator;
}

- (void) reloadData;

@property (nonatomic, retain) NSArray *displayList;

@property (nonatomic, retain) UIActivityIndicatorView *activityIndicator;

@property (nonatomic, strong) UIBarButtonItem *buttonProfile;
@property (nonatomic, strong) UIBarButtonItem *buttonFilter;

@property Boolean initialized;

@end


