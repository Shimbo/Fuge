

#import <Parse/Parse.h>

#import "CoreLocation/CLLocationManager.h"
#import <CoreLocation/CoreLocation.h>
#import "UIKit/UIActivityIndicatorView.h"

#import "RootViewController.h"
#import "FilterViewController.h"
#import "UserProfileController.h"
#import "NewMeetupViewController.h"
#import "PersonCell.h"
#import "Person.h"
#import "Circle.h"
#import "GlobalVariables.h"
#import "GlobalData.h"
#import "FacebookLoader.h"
#import "AppDelegate.h"
#import "AsyncImageView.h"
#import "InAppPurchaseManager.h"
#import "LeftMenuController.h"
#import "NewOpportunityViewController.h"
#import "CreateOpportunityCell.h"

#import "TestFlightSDK/TestFlight.h"

@implementation RootViewController

#define MAX_INDUSTRIES_TO_FILTER    20

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[NSNotificationCenter defaultCenter]addObserver:self
                                                selector:@selector(reloadAllFinished)
                                                name:kLoadingCirclesComplete
                                                object:nil];
        [[NSNotificationCenter defaultCenter]addObserver:self
                                                selector:@selector(reloadEncountersFinished)
                                                name:kLoadingEncountersComplete
                                                object:nil];
        [[NSNotificationCenter defaultCenter]addObserver:self
                                                selector:@selector(loadingFailed)
                                                name:kLoadingCirclesFailed
                                                object:nil];
        [[NSNotificationCenter defaultCenter]addObserver:self
                                                selector:@selector(opsHidden:)
                                                name:kOpportunitiesHidden
                                                object:nil];
    }
    return self;
}


#pragma mark -
#pragma mark Buttons


- (void)filterClicked{
    FilterViewController *filterViewController = [[FilterViewController alloc] initWithNibName:@"FilterView" bundle:nil];
    [self.navigationController pushViewController:filterViewController animated:YES];
}

- (void) matchClicked
{
    sortingMode++;
    if ( ! bIsAdmin && sortingMode == SORTING_ENGAGEMENT )  // Skip engagement for non-admins
        sortingMode++;
    if ( sortingMode == SORTING_MODES_COUNT )
        sortingMode = 0;
    
    NSUInteger titleNum = sortingMode+1;
    if ( ! bIsAdmin && titleNum == SORTING_ENGAGEMENT )  // Skip engagement for non-admins
        titleNum++;
    if ( titleNum == SORTING_MODES_COUNT )
        titleNum = 0;
    
    [matchBtn setTitle:sortingModeTitles[titleNum]];
    
    // Data reload
    [self recalcAndSortUsers];
    [self reloadTableAndScroll:TRUE];
}

- (void) shoutoutClicked
{
    [inAppManager requestProductData];
}


#pragma mark -
#pragma mark View loading


- (void) recalcAndSortUsers
{
    sortedUsers = [NSMutableArray arrayWithCapacity:100];
    for ( Circle* circle in [globalData getCircles] )
        if ( circle.idCircle != CIRCLE_FBOTHERS )
            if ( sortingMode != SORTING_RANK || circle.idCircle != CIRCLE_FB )  // exclude friends from ranking
                [sortedUsers addObjectsFromArray:circle.getPersons];
    if ( sortingMode == SORTING_ENGAGEMENT )
    {
        [sortedUsers sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            Person* p1 = obj1;
            Person* p2 = obj2;
            if ( [p1 getConversationCountStats:TRUE onlyMessages:FALSE] > [p2 getConversationCountStats:TRUE onlyMessages:FALSE] )
                return NSOrderedAscending;
            else
                return NSOrderedDescending;
        }];
    }
    else if ( sortingMode == SORTING_RANK )
    {
        usersHereNow = [NSMutableArray arrayWithCapacity:100];
        usersNearbyToday = [NSMutableArray arrayWithCapacity:100];
        usersRecent = [NSMutableArray arrayWithCapacity:100];
        for ( Person* person in sortedUsers )
        {
            if ( searchString )
                if ( [person searchRating:searchString] == 0 )
                    continue;
            if ( person.matchesRank > 0 )
            {
                if ( ! person.isNotActive && person.distance && [person.distance floatValue] < PERSON_HERE_DISTANCE )
                    [usersHereNow addObject:person];
                else if ( ! person.isOutdated && person.distance && [person.distance floatValue] < PERSON_NEARBY_DISTANCE )
                    [usersNearbyToday addObject:person];
                else
                    [usersRecent addObject:person];
            }
        }
        
        [usersHereNow sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            if ( ((Person*)obj1).matchesRank > ((Person*)obj2).matchesRank )
                return NSOrderedAscending;
            else
                return NSOrderedDescending;
        }];
        [usersNearbyToday sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            if ( ((Person*)obj1).matchesRank > ((Person*)obj2).matchesRank )
                return NSOrderedAscending;
            else
                return NSOrderedDescending;
        }];
        [usersRecent sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            if ( ((Person*)obj1).matchesRank > ((Person*)obj2).matchesRank )
                return NSOrderedAscending;
            else
                return NSOrderedDescending;
        }];
    }
    else if ( sortingMode == SORTING_DISTANCE )
    {
        usersHereNow = [NSMutableArray arrayWithCapacity:100];
        usersNearbyToday = [NSMutableArray arrayWithCapacity:100];
        usersRecent = [NSMutableArray arrayWithCapacity:100];
        for ( Person* person in sortedUsers )
        {
            if ( searchString )
                if ( [person searchRating:searchString] == 0 )
                    continue;
#ifdef TARGET_S2C
            if ( ! searchString )
            {
                if ( filterSelector != 0 && filterSelector != MAX_INDUSTRIES_TO_FILTER+1 && [person.industryInfo compare:filterButtonLabels[ filterSelector ]] != NSOrderedSame )
                    continue;
                if ( filterSelector == MAX_INDUSTRIES_TO_FILTER+1 )
                {
                    Boolean bFound = false;
                    for ( NSUInteger n = 1; n < MAX_INDUSTRIES_TO_FILTER+1; n++ )
                        if ( [person.industryInfo compare:filterButtonLabels[ n ]] == NSOrderedSame )
                        {
                            bFound = true;
                            break;
                        }
                    if ( bFound )
                        continue;
                }
            }
#endif
            if ( ! person.isNotActive && person.distance && [person.distance floatValue] < PERSON_HERE_DISTANCE )
                [usersHereNow addObject:person];
            else if ( ! person.isOutdated && person.distance && [person.distance floatValue] < PERSON_NEARBY_DISTANCE )
                [usersNearbyToday addObject:person];
            else
                [usersRecent addObject:person];
        }
        
        [usersHereNow sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            Person* p1 = obj1;
            Person* p2 = obj2;
            if ( p1.visibleOpportunities.count > 0 )
                return NSOrderedAscending;
            if ( p2.visibleOpportunities.count > 0 )
                return NSOrderedDescending;
            if ( ! p1.distance )
                return NSOrderedDescending;
            if ( ! p2.distance )
                return NSOrderedAscending;
            if ( p1.distance.doubleValue < p2.distance.doubleValue )
                return NSOrderedAscending;
            else
                return NSOrderedDescending;
        }];
        [usersNearbyToday sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            Person* p1 = obj1;
            Person* p2 = obj2;
            if ( p1.visibleOpportunities.count > 0 )
                return NSOrderedAscending;
            if ( p2.visibleOpportunities.count > 0 )
                return NSOrderedDescending;
            if ( ! p1.distance )
                return NSOrderedDescending;
            if ( ! p2.distance )
                return NSOrderedAscending;
            if ( p1.distance.doubleValue < p2.distance.doubleValue )
                return NSOrderedAscending;
            else
                return NSOrderedDescending;
        }];
        [usersRecent sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            Person* p1 = obj1;
            Person* p2 = obj2;
            if ( p1.visibleOpportunities.count > 0 )
                return NSOrderedAscending;
            if ( p2.visibleOpportunities.count > 0 )
                return NSOrderedDescending;
            if ( ! p1.distance )
                return NSOrderedDescending;
            if ( ! p2.distance )
                return NSOrderedAscending;
            if ( p1.distance.doubleValue < p2.distance.doubleValue )
                return NSOrderedAscending;
            else
                return NSOrderedDescending;
        }];
    }
    _currentPerson = currentPerson;
}

- (void) reloadTableAndScroll:(Boolean)hideSearch;
{
    [tableView reloadData];
    if ( hideSearch )
        if ( [self tableView:tableView numberOfRowsInSection:0] > 0 )
            [tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:TRUE];
        //[tableView scrollRectToVisible:CGRectMake(0, searchView.frame.size.height/*tableView.frame.origin.y*/, tableView.frame.size.width, tableView.frame.size.width) animated:TRUE];
    /*CGSize size = CGSizeMake(tableView.frame.size.width, tableView.frame.size.height + searchView.frame.size.height);
    [scrollView setContentSize:size];
    [scrollView scrollRectToVisible:CGRectMake(0, searchView.frame.size.height, 1, searchView.frame.size.height+1) animated:TRUE];*/
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
    sortingMode = SORTING_DISTANCE;
    
    // Navigation bar
    //[self.navigationItem setHidesBackButton:true animated:false];
    //[self.navigationController.navigationBar setBackgroundImage:[UIImage alloc] forBarMetrics:UIBarMetricsDefault];
    //[self.navigationController.navigationBar setBackgroundImage:[UIImage alloc] forBarMetrics:UIBarMetricsLandscapePhone];
    //[self.navigationController.navigationBar setBackgroundColor:[UIColor greenColor]];
    //[self.navigationController.navigationBar setBarTintColor:[UIColor greenColor]];
    
    // Table view
    UINib *nib = [UINib nibWithNibName:@"PersonCell" bundle:nil];
    [tableView registerNib:nib forCellReuseIdentifier:@"PersonCell"];
    nib = [UINib nibWithNibName:@"CreateOpportunityCell" bundle:nil];
    [tableView registerNib:nib forCellReuseIdentifier:@"CreateOpportunityCell"];
    tableView.tableFooterView = [[UIView alloc]init];
    tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    //tableView.rowHeight = ROW_HEIGHT;
    
    // Table search
    tableView.tableHeaderView = searchView;
    [self reloadTableAndScroll:TRUE];
    
    // Buttons
    //UIBarButtonItem *shoutoutBtn = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"BUTTONS_SHOUTOUT",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(shoutoutClicked)];
#ifdef TARGET_FUGE
    matchBtn = [[UIBarButtonItem alloc] initWithTitle:sortingModeTitles[SORTING_RANK] style:UIBarButtonItemStyleBordered target:self action:@selector(matchClicked)];
    [self.navigationItem setRightBarButtonItems:@[matchBtn]];
#elif defined TARGET_S2C
    filterButton = [[UIBarButtonItem alloc] initWithTitle:@"Filter" style:UIBarButtonItemStyleBordered target:self action:@selector(filterSelectorClicked)];
    [self recalcFilterTexts];
    [self.navigationItem setRightBarButtonItems:@[filterButton/*, shoutoutBtn*/]];
#endif
    
    // Users sorting (if loaded)
    if ( [globalData getLoadingStatus:LOADING_CIRCLES] == LOAD_OK )
        [self recalcAndSortUsers];
    
    // Refresh control
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshView:) forControlEvents:UIControlEventValueChanged];
    [tableView addSubview:refreshControl];
    
    // Status
#ifdef TARGET_S2C
    /*NSDate* latestStatus = [pCurrentUser objectForKey:@"profileStatusDate"];
    NSString* strStatus = [pCurrentUser objectForKey:@"profileStatus"];
    if ( ! strStatus )
        strStatus = @"";
    Boolean showStatus = false;
    if ( ! latestStatus )
        showStatus = true;
    else if ( [latestStatus compare:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)-86400*7] ] == NSOrderedAscending && strStatus.length < 10 )
        showStatus = true;
    else if ( [latestStatus compare:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)-86400*30] ] == NSOrderedAscending )
        showStatus = true;
    
    if ( showStatus )
        [(LeftMenuController*)AppDelegate.revealController.leftViewController askStatus];*/
#endif
}

- (void) viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    //if ( [globalData getLoadingStatus:LOADING_CIRCLES] == LOAD_STARTED )
    if ( ! _currentPerson )
        [activityIndicator startAnimating];
    
    [self reloadTableAndScroll:FALSE];
}

- (void) reloadEncountersFinished
{
    // Create labels
    [self recalcFilterTexts];
    
    // Sort users
    [self recalcAndSortUsers];
    
    // Hide animations
    [activityIndicator stopAnimating];
    tableView.userInteractionEnabled = TRUE;
    
    // Show data and scroll
    [self reloadTableAndScroll:TRUE];
}

- (void) reloadAllFinished
{
    // Update labels
    [self recalcFilterTexts];
    
    // Sort users
    [self recalcAndSortUsers];
    
    // Hide animations
    [activityIndicator stopAnimating];
    tableView.userInteractionEnabled = TRUE;
    [refreshControl endRefreshing];
    
    // Show data
    [tableView reloadData];
}

- (void) loadingFailed
{
    [activityIndicator stopAnimating];
    tableView.userInteractionEnabled = TRUE;
}

- (void) opsHidden:(NSNotification *)notification
{
    Person* person = [notification object];
        
    NSUInteger section = 0;
    NSUInteger row = 0;
    
    for ( NSUInteger n = 0; n < usersHereNow.count; n++ )
    {
        Person* testPerson = usersHereNow[n];
        if ( [testPerson.strId isEqualToString:person.strId] )
        {
            section = 1;
            row = n;
        }
    }
    for ( NSUInteger n = 0; n < usersNearbyToday.count; n++ )
    {
        Person* testPerson = usersNearbyToday[n];
        if ( [testPerson.strId isEqualToString:person.strId] )
        {
            section = 2;
            row = n;
        }
    }
    for ( NSUInteger n = 0; n < usersRecent.count; n++ )
    {
        Person* testPerson = usersRecent[n];
        if ( [testPerson.strId isEqualToString:person.strId] )
        {
            section = 3;
            row = n;
        }
    }
    
    if ( section != 0 )
    {
        NSIndexPath* personPath = [NSIndexPath indexPathForRow:row inSection:section];
        [tableView reloadRowsAtIndexPaths:@[personPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}


#pragma mark -
#pragma mark Table view datasource and delegate methods

-(void)refreshView:(UIRefreshControl *)refreshControl {

    tableView.userInteractionEnabled = FALSE;
    [globalData reloadFriendsInBackground];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView {
    
    if ( sortingMode == SORTING_DISTANCE )
#ifdef TARGET_FUGE
        return 5;
#elif defined TARGET_S2C
        return 4;
#endif
    else if ( sortingMode == SORTING_RANK )
        return 4;
    else // SORTING_ENGAGEMENT
        return 1;
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
	
    switch (sortingMode)
    {
        case SORTING_DISTANCE:
        case SORTING_RANK:
            switch (section)
            {
#ifdef TARGET_FUGE
                case 0: return 0;
#elif defined TARGET_S2C
                case 0: if ( _currentPerson ) return 1; return 0;
#endif
                case 1: return usersHereNow.count;
                case 2: return usersNearbyToday.count;
                case 3: return usersRecent.count;
                case 4: return [globalData getCircle:CIRCLE_FBOTHERS].getPersons.count;
            }
        default:    // ENGAGEMENT
            return sortedUsers.count;
    }
}

- (NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section {
    
	switch ( sortingMode )
    {
        case SORTING_DISTANCE:
        case SORTING_RANK:
            if ( section == 0 )
            {
#ifdef TARGET_FUGE
                return nil;
#elif defined TARGET_S2C
                if ( _currentPerson )
                {
                    if ( currentPerson.visibleOpportunities && currentPerson.visibleOpportunities.count > 0 )
                        return @"This is you";
                    else
                        return @"You could be here";
                }
                else
                    return nil;
#endif
            }
            if ( section == 1 )
            {
                if ( usersHereNow.count > 0 )
                    return @"Here and now";
                return @"";
            }
            if ( section == 2 )
            {
                if ( usersNearbyToday.count > 0 )
                    return @"Nearby today";
                return @"";
            }
            if ( section == 3 )
            {
                if ( usersRecent.count > 0 )
                    return @"Recent";
                return @"";
            }
            if ( section == 4 )
            {
                if ( [globalData getCircle:CIRCLE_FBOTHERS].getPersons.count > 0 )
                    return [Circle getCircleName:[globalData getCircle:CIRCLE_FBOTHERS].idCircle];
            }
            break;
        case SORTING_ENGAGEMENT:
            return @"Sorting by engagement";
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)table heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    Circle *circle;
    Person* person = nil;
    
    switch ( sortingMode )
    {
        case SORTING_DISTANCE:
        case SORTING_RANK:
            
            switch (indexPath.section )
            {
            case 0: person = currentPerson; break;
            case 1: if ( indexPath.row < usersHereNow.count) person = usersHereNow[indexPath.row]; break;
            case 2: if ( indexPath.row < usersNearbyToday.count) person = usersNearbyToday[indexPath.row]; break;
            case 3: if ( indexPath.row < usersRecent.count) person = usersRecent[indexPath.row]; break;
            case 4:
                circle = [globalData getCircle:CIRCLE_FBOTHERS];
                person = [circle getPersons][indexPath.row];
                break;
            }
            break;
        default:    // ENGAGEMENT
            person = sortedUsers[indexPath.row];
            break;
    }
    
    return 60 + person.visibleOpportunitiesHeight;
}

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath  {
    
    // Opportunities
    if ( indexPath.section == 0 )
    {
        if ( ! currentPerson.visibleOpportunities || currentPerson.visibleOpportunities.count == 0 )
        {
            CreateOpportunityCell *createOpportunityCell = (CreateOpportunityCell *)[tableView dequeueReusableCellWithIdentifier:@"CreateOpportunityCell"];
            [createOpportunityCell.avatarImage loadImageFromURL:currentPerson.smallAvatarUrl];
            return createOpportunityCell;
        }
    }
    
    // Persons
	PersonCell *personCell = (PersonCell *)[tableView dequeueReusableCellWithIdentifier:@"PersonCell"];
    //[personCell setNeedsDisplay];
    Circle *circle;
	Person *person;
    
    switch ( sortingMode )
    {
        case SORTING_DISTANCE:
        case SORTING_RANK:
            switch (indexPath.section )
            {
                case 0: person = currentPerson; break;
                case 1: person = usersHereNow[indexPath.row]; break;
                case 2: person = usersNearbyToday[indexPath.row]; break;
                case 3: person = usersRecent[indexPath.row]; break;
                case 4:
                    circle = [globalData getCircle:CIRCLE_FBOTHERS];
                    person = [circle getPersons][indexPath.row];
                    break;
            }
            break;
        default:    // ENGAGEMENT
            person = sortedUsers[indexPath.row];
            break;
    }
    
    [personCell initWithPerson:person engagement:(sortingMode == SORTING_ENGAGEMENT)];
    
	return personCell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    //cell.backgroundColor = ((PersonCell*)cell).color;
}

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [self.view endEditing:YES];
    
    // Opportunities
    if ( indexPath.section == 0 )
    {
        if ( ! currentPerson.visibleOpportunities || currentPerson.visibleOpportunities.count == 0 )
        {
            NewOpportunityViewController *opController = [[NewOpportunityViewController alloc]init];
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:opController];
            [self presentViewController:nav animated:YES completion:nil];
            return;
        }
    }
    
    Circle *circle;
    Person* person = nil;
    
    switch ( sortingMode )
    {
        case SORTING_DISTANCE:
        case SORTING_RANK:
            
            switch (indexPath.section )
            {
                case 0: person = currentPerson; break;
                case 1: if ( indexPath.row < usersHereNow.count) person = usersHereNow[indexPath.row]; break;
                case 2: if ( indexPath.row < usersNearbyToday.count) person = usersNearbyToday[indexPath.row]; break;
                case 3: if ( indexPath.row < usersRecent.count) person = usersRecent[indexPath.row]; break;
                case 4:
                    circle = [globalData getCircle:CIRCLE_FBOTHERS];
                    person = [circle getPersons][indexPath.row];
                    break;
            }
            break;
        default:    // ENGAGEMENT
            person = sortedUsers[indexPath.row];
            break;
    }
    
    if ( person )
    {
        // Empty profile, should open invite window
        if ( person.idCircle == CIRCLE_FBOTHERS ) {
            
            [fbLoader showInviteDialog:[NSArray arrayWithObject:person.strId] message:NSLocalizedString(@"FB_INVITE_MESSAGE_SIMPLE",nil)];
        }
        else {
            UserProfileController *userProfileController = [[UserProfileController alloc] initWithNibName:@"UserProfile" bundle:nil];
            [userProfileController setPerson:person];
    #ifdef TARGET_S2C
            [userProfileController setProfileMode:PROFILE_MODE_SUMMARY];
    #endif
            [self.navigationController pushViewController:userProfileController animated:YES];
        }
    }
    
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.view endEditing:YES];
}


#pragma mark -
#pragma mark Picker View delegate


- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    
    return 1;
    
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    
    return filterButtonLabels.count;
}

/*- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    
    return filterSelectionLabels[row];
}*/

// this method runs whenever the user changes the selected list option

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    
    filterButton.title = filterButtonLabels[ row ];
    filterSelector = row;
    
    // Sort users
    [self recalcAndSortUsers];
    
    // Data refresh
    [self reloadTableAndScroll:TRUE];
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
    return 36.0f;
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
    UILabel *retval = (id)view;
    if (!retval) {
        retval= [[UILabel alloc] initWithFrame:CGRectMake(20.0f, 0.0f, [pickerView rowSizeForComponent:component].width-20, [pickerView rowSizeForComponent:component].height)];
    }
    
    retval.font = [UIFont boldSystemFontOfSize:16];
    retval.text = filterSelectionLabels[ row ];
    retval.backgroundColor = [UIColor clearColor];
    return retval;
}

- (void) filterSelectorClicked {
    
    // Picker view
    CGRect pickerFrame = CGRectMake(0, 40, 320, 445);
    UIPickerView *pickerView = [[UIPickerView alloc] initWithFrame:pickerFrame];
    pickerView.showsSelectionIndicator = YES;
    pickerView.dataSource = self;
    pickerView.delegate = self;
    [pickerView selectRow:filterSelector inComponent:0 animated:NO];
    
    // Close button
    UISegmentedControl *closeBtn = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObject:@"Close"]];
    closeBtn.momentary = YES;
    closeBtn.frame = CGRectMake(260, 7, 50, 30);
    closeBtn.segmentedControlStyle = UISegmentedControlStyleBar;
    closeBtn.tintColor = [UIColor blackColor];
    [closeBtn addTarget:self action:@selector(dismissPopup) forControlEvents:UIControlEventValueChanged];
    
    if ( IPAD )
    {
        // View and VC
        UIView *view = [[UIView alloc] init];
        [view addSubview:pickerView];
        [view addSubview:closeBtn];
        UIViewController *vc = [[UIViewController alloc] init];
        [vc setView:view];
        [vc setContentSizeForViewInPopover:CGSizeMake(320, 260)];
        
        if ( ! popover )
            popover = [[UIPopoverController alloc] initWithContentViewController:vc];
        [popover presentPopoverFromBarButtonItem:filterButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
    else
    {
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:nil cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
        [actionSheet setActionSheetStyle:UIActionSheetStyleBlackTranslucent];
        [actionSheet addSubview:pickerView];
        [actionSheet addSubview:closeBtn];
        [actionSheet showInView:self.view];
        [actionSheet setBounds:CGRectMake(0, 0, 320, 485)];
    }
}

- (void) dismissPopup {
    
    if ( IPAD )
        [popover dismissPopoverAnimated:TRUE];
    else
        [actionSheet dismissWithClickedButtonIndex:0 animated:YES];
}

- (void)recalcFilterTexts
{
#ifdef TARGET_FUGE
    return;
#endif
    // Create temporary array of all users
    NSMutableArray* allUsers = [NSMutableArray arrayWithCapacity:100];
    for ( Circle* circle in [globalData getCircles] )
        if ( circle.idCircle != CIRCLE_FBOTHERS )
            [allUsers addObjectsFromArray:circle.getPersons];
    
    // Gather all industries
    NSMutableDictionary* industryPairs = [NSMutableDictionary dictionaryWithCapacity:10];
    for ( Person* person in allUsers )
    {
        NSString* strIndustry = person.industryInfo;
        if ( ! strIndustry )
            continue;
        NSNumber* count = [industryPairs objectForKey:strIndustry];
        if ( ! count )
            count = [NSNumber numberWithInteger:1];
        else
            count = [NSNumber numberWithInteger:[count integerValue] + 1];
        [industryPairs setObject:count forKey:strIndustry];
    }
    NSArray* sortedKeys = [industryPairs keysSortedByValueUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSNumber* n1 = obj1; NSNumber* n2 = obj2;
        if ( [n1 integerValue] > [n2 integerValue] )
            return NSOrderedAscending;
        else
            return NSOrderedDescending;
    }];
    
    if ( sortedKeys.count > MAX_INDUSTRIES_TO_FILTER )
        for ( NSUInteger n = MAX_INDUSTRIES_TO_FILTER; n < sortedKeys.count; n++ )
             [industryPairs removeObjectForKey:sortedKeys[n]];
    
    // Texts for buttons
    NSUInteger otherIndustriesCount = allUsers.count;
    filterButtonLabels = [NSMutableArray arrayWithCapacity:15];
    filterSelectionLabels = [NSMutableArray arrayWithCapacity:15];
    [filterButtonLabels addObject:@"All Industries"];
    [filterSelectionLabels addObject:[NSString stringWithFormat:@"All Industries (%d)", allUsers.count]];
    for ( NSString* key in sortedKeys )
    {
        NSString* shorterTitle = key;
        if ( key.length > 26 )
            shorterTitle = [NSString stringWithFormat:@"%@...",[key substringToIndex:26]];
        
        NSNumber* count = (NSNumber*)[industryPairs objectForKey:key];
        if ( ! count )
            continue;
        NSString *industryString = [NSString stringWithFormat:@"%@ (%d)", shorterTitle, [count integerValue]];
        [filterButtonLabels addObject:key];
        [filterSelectionLabels addObject:industryString];
        otherIndustriesCount -= [count integerValue];
    }
    if ( sortedKeys.count > MAX_INDUSTRIES_TO_FILTER )
    {
        [filterButtonLabels addObject:@"Other Industries"];
        [filterSelectionLabels addObject:[NSString stringWithFormat:@"Other Industries (%d)", otherIndustriesCount]];
    }
    
    filterButton.title = filterButtonLabels[ filterSelector ];
}

#pragma mark -
#pragma mark Search View delegate

static NSUInteger oldActivityIndicatorPos;

- (void)searchFinished
{
    [activityIndicator stopAnimating];
    activityIndicator.originY = oldActivityIndicatorPos;
    [self recalcAndSortUsers];
    [self reloadTableAndScroll:FALSE];
}

- (void)searchForString
{
    oldActivityIndicatorPos = activityIndicator.originY;
    activityIndicator.originY = searchView.frame.origin.y + searchView.frame.size.height + 70;
    [activityIndicator startAnimating];
    [globalData loadPersonsBySearchString:searchString target:self selector:@selector(searchFinished)];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
    if ( searchText.length == 0 )
    {
        searchString = nil;
        //[searchBar performSelector:@selector(resignFirstResponder) withObject:nil afterDelay:0.1];
    }
    else
        searchString = [searchText lowercaseString];
    
    [self recalcAndSortUsers];
    [self reloadTableAndScroll:FALSE];
    if (usersHereNow.count == 0 && usersNearbyToday.count == 0 && usersRecent.count == 0 && searchString)
    {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        [self performSelector:@selector(searchForString) withObject:nil afterDelay:0.7];
    }
}
- (void)searchBarCancelButtonClicked:(UISearchBar *) searchBar{
    searchString = nil;
    [self.view endEditing:YES];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}


- (void)viewDidUnload {
    searchView = nil;
    [super viewDidUnload];
}
@end
