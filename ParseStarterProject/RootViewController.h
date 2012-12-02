
@interface RootViewController : UITableViewController {
	NSArray *displayList;
    Boolean initialized;
    UIBarButtonItem* buttonProfile;
    UIBarButtonItem* buttonFilter;
}

- (void) reloadData;

@property (nonatomic, retain) NSArray *displayList;

@property (nonatomic, strong) UIBarButtonItem *buttonProfile;
@property (nonatomic, strong) UIBarButtonItem *buttonFilter;

@property Boolean initialized;

@end
