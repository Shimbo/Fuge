
@interface RootViewController : UITableViewController {
	NSArray *displayList;
    
    UIActivityIndicatorView* activityIndicator;
}

- (void) reloadData;

@property (nonatomic, retain) NSArray *displayList;

@property (nonatomic, retain) UIActivityIndicatorView *activityIndicator;

@property BOOL initialized;

@end


