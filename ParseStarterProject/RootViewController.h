
@interface RootViewController : UITableViewController {
	NSArray *displayList;
    Boolean initialized;
    
    UIActivityIndicatorView* activityIndicator;
}

- (void) reloadData;

@property (nonatomic, retain) NSArray *displayList;

@property (nonatomic, retain) UIActivityIndicatorView *activityIndicator;

@property Boolean initialized;

@end


