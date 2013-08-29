

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

#import "TestFlightSDK/TestFlight.h"

@implementation RootViewController

#define ROW_HEIGHT  60
#define MAX_INDUSTRIES_TO_FILTER    10

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[NSNotificationCenter defaultCenter]addObserver:self
                                                selector:@selector(reloadFinished)
                                                name:kLoadingCirclesComplete
                                                object:nil];
        [[NSNotificationCenter defaultCenter]addObserver:self
                                                selector:@selector(loadingFailed)
                                                name:kLoadingCirclesFailed
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
            if ( [((Person*)obj1) getConversationCountStats:TRUE onlyMessages:FALSE] > [((Person*)obj2) getConversationCountStats:TRUE onlyMessages:FALSE] )
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
                if ( [[person.fullName lowercaseString] rangeOfString:searchString].location == NSNotFound )
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
                if ( [[person.fullName lowercaseString] rangeOfString:searchString].location == NSNotFound )
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
            if ( ! ((Person*)obj1).distance )
                return NSOrderedDescending;
            if ( ! ((Person*)obj2).distance )
                return NSOrderedAscending;
            if ( ((Person*)obj1).distance.doubleValue < ((Person*)obj2).distance.doubleValue )
                return NSOrderedAscending;
            else
                return NSOrderedDescending;
        }];
        [usersNearbyToday sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            if ( ! ((Person*)obj1).distance )
                return NSOrderedDescending;
            if ( ! ((Person*)obj2).distance )
                return NSOrderedAscending;
            if ( ((Person*)obj1).distance.doubleValue < ((Person*)obj2).distance.doubleValue )
                return NSOrderedAscending;
            else
                return NSOrderedDescending;
        }];
        [usersRecent sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            if ( ! ((Person*)obj1).distance )
                return NSOrderedDescending;
            if ( ! ((Person*)obj2).distance )
                return NSOrderedAscending;
            if ( ((Person*)obj1).distance.doubleValue < ((Person*)obj2).distance.doubleValue )
                return NSOrderedAscending;
            else
                return NSOrderedDescending;
        }];
    }
}

- (void) reloadTableAndScroll:(Boolean)hideScroll;
{
    [tableView reloadData];
    if ( hideScroll )
        [tableView scrollRectToVisible:CGRectMake(0, searchView.frame.size.height, tableView.frame.size.width, tableView.frame.size.height) animated:TRUE];
    /*CGSize size = CGSizeMake(tableView.frame.size.width, tableView.frame.size.height + searchView.frame.size.height);
    [scrollView setContentSize:size];
    [scrollView scrollRectToVisible:CGRectMake(0, searchView.frame.size.height, 1, searchView.frame.size.height+1) animated:TRUE];*/
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
    sortingMode = SORTING_DISTANCE;
    
    // Navigation bar
    [self.navigationItem setHidesBackButton:true animated:false];
    
    // Table view
    UINib *nib = [UINib nibWithNibName:@"PersonCell" bundle:nil];
    [tableView registerNib:nib forCellReuseIdentifier:@"PersonCell"];
    tableView.tableFooterView = [[UIView alloc]init];
    tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    tableView.rowHeight = ROW_HEIGHT;
    
    // Table search
    tableView.tableHeaderView = searchView;
    [self reloadTableAndScroll:TRUE];
    
    // Buttons
#ifdef TARGET_FUGE
    matchBtn = [[UIBarButtonItem alloc] initWithTitle:sortingModeTitles[SORTING_RANK] style:UIBarButtonItemStyleBordered target:self action:@selector(matchClicked)];
    //UIBarButtonItem *reloadBtn = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"BUTTONS_RELOAD",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(reloadClicked)];
    [self.navigationItem setRightBarButtonItems:@[matchBtn]];
#elif defined TARGET_S2C
    filterButton = [[UIBarButtonItem alloc] initWithTitle:@"Filter" style:UIBarButtonItemStyleBordered target:self action:@selector(filterSelectorClicked)];
    [self recalcFilterTexts];
    [self.navigationItem setRightBarButtonItems:@[filterButton]];
#endif
    
    // Users sorting
    [self recalcAndSortUsers];
    
    // Refresh control
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshView:) forControlEvents:UIControlEventValueChanged];
    [tableView addSubview:refreshControl];
}

- (void) viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    if ( [globalData getLoadingStatus:LOADING_CIRCLES] == LOAD_STARTED )
    {
        [activityIndicator startAnimating];
        tableView.userInteractionEnabled = FALSE;
    }
    else
        tableView.userInteractionEnabled = TRUE;
    
    [self reloadTableAndScroll:FALSE];
}

- (void) reloadFinished
{
    // Create labels
    [self recalcFilterTexts];
    
    // Sort users
    [self recalcAndSortUsers];
    
    // Data refresh
    [activityIndicator stopAnimating];
    tableView.userInteractionEnabled = TRUE;
    [refreshControl endRefreshing];
    
    // Show data
    [self reloadTableAndScroll:TRUE];
}

- (void) loadingFailed
{
    [activityIndicator stopAnimating];
    tableView.userInteractionEnabled = TRUE;
}


#pragma mark -
#pragma mark Table view datasource and delegate methods

-(void)refreshView:(UIRefreshControl *)refreshControl {

    tableView.userInteractionEnabled = FALSE;
    [globalData reloadFriendsInBackground:TRUE];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView {
    
    if ( sortingMode == SORTING_DISTANCE )
#ifdef TARGET_FUGE
        return 4;
#elif defined TARGET_S2C
        return 3;
#endif
    else if ( sortingMode == SORTING_RANK )
        return 3;
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
                case 0: return usersHereNow.count;
                case 1: return usersNearbyToday.count;
                case 2: return usersRecent.count;
                case 3: return [globalData getCircle:CIRCLE_FBOTHERS].getPersons.count;
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
                if ( usersHereNow.count > 0 )
                    return @"Here and now";
                return @"";
            }
            if ( section == 1 )
            {
                if ( usersNearbyToday.count > 0 )
                    return @"Nearby today";
                return @"";
            }
            if ( section == 2 )
            {
                if ( usersRecent.count > 0 )
                    return @"Recent";
                return @"";
            }
            if ( section == 3 )
            {
                if ( [globalData getCircle:CIRCLE_FBOTHERS].getPersons.count > 0 )
                    return [Circle getCircleName:[globalData getCircle:CIRCLE_FBOTHERS].idCircle];
            }
        default:    // ENGAGEMENT
            return @"Sorting by engagement";
    }
}

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath  {
		
	static NSString *CellIdentifier = @"PersonCell";
    
	PersonCell *personCell = (PersonCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    [personCell setNeedsDisplay];
	
    Circle *circle;
	Person *person;
    
    switch ( sortingMode )
    {
        case SORTING_DISTANCE:
        case SORTING_RANK:
            switch (indexPath.section )
            {
                case 0: person = usersHereNow[indexPath.row]; break;
                case 1: person = usersNearbyToday[indexPath.row]; break;
                case 2: person = usersRecent[indexPath.row]; break;
                case 3:
                    circle = [globalData getCircle:CIRCLE_FBOTHERS];
                    person = [circle getPersons][indexPath.row];
                    break;
            }
            break;
        default:    // ENGAGEMENT
            person = sortedUsers[indexPath.row];
            break;
    }
    
    [personCell.personImage loadImageFromURL:person.smallAvatarUrl];
    
#ifdef TARGET_FUGE
    personCell.personName.text = [person fullName];
#elif defined TARGET_S2C
    NSMutableString* strPersonName = [NSMutableString stringWithString:[person fullName]];
    if ( person.idCircle == CIRCLE_FB )
        [strPersonName appendString:@" (1st)"];
    else if ( person.idCircle == CIRCLE_2O )
        [strPersonName appendString:@" (2nd)"];
    personCell.personName.text = strPersonName;
#endif
    if ( person.idCircle == CIRCLE_FBOTHERS )
        personCell.personDistance.text = @"Invite!";
    else
    {
        NSString* distanceString = [person distanceString:FALSE];
        if ( distanceString.length > 0 )
            personCell.personDistance.text = distanceString;
        else
            personCell.personDistance.text = @"Unknown";
    }
    
    personCell.color = [UIColor whiteColor];
    personCell.personInfo.text = @"";
    personCell.shouldDrawMatches = FALSE;
    
#ifdef TARGET_S2C
    personCell.personStatus.text = person.strStatus;
    personCell.personRole.text = [person jobInfo];
#elif defined TARGET_FUGE
    // Matches
    if ( person.idCircle != CIRCLE_FBOTHERS )
    {
        if ( person.matchesTotal )
            personCell.personInfo.text = @"Match:    ";
        if ( person.idCircle != CIRCLE_FB )
        {
            NSUInteger matchesRank = person.matchesRank;
            float fColor = 1.0f - ((float)(matchesRank > MATCHING_COLOR_RANK_MAX ? MATCHING_COLOR_RANK_MAX : matchesRank))/MATCHING_COLOR_RANK_MAX / MATCHING_COLOR_BRIGHTNESS;
            personCell.color = [UIColor
                        colorWithRed: (MATCHING_COLOR_COMPONENT_R+(255.0f-MATCHING_COLOR_COMPONENT_R)*fColor)/255.0f
                        green:(MATCHING_COLOR_COMPONENT_G+(255.0f-MATCHING_COLOR_COMPONENT_G)*fColor)/255.0f
                        blue:(MATCHING_COLOR_COMPONENT_B+(255.0f-MATCHING_COLOR_COMPONENT_B)*fColor)/255.0f alpha:1.0f];
            if ( matchesRank > 0 )
                personCell.shouldDrawMatches = TRUE;
        }
        else
            personCell.personInfo.text = @"FB friend";
    }
    
    // Engagement details
    if ( sortingMode == SORTING_ENGAGEMENT )
    {
        NSString* strMatches = [NSString stringWithFormat:@"%d/%d/%d/%d", [person getConversationCountStats:TRUE onlyMessages:FALSE], [person getConversationCountStats:FALSE onlyMessages:FALSE], [person getConversationCountStats:TRUE onlyMessages:TRUE], [person getConversationCountStats:FALSE onlyMessages:TRUE]];
        personCell.personInfo.text = strMatches;
    }
    if ( person.strStatus && person.strStatus.length > 0 )
    {
        personCell.personStatus.text = person.strStatus;
        personCell.personStatus.textColor = [UIColor blueColor];
    }
    else
    {
        personCell.personStatus.text = [person jobInfo];
        personCell.personStatus.textColor = [UIColor blackColor];
    }
#endif
    
	return personCell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    //cell.backgroundColor = ((PersonCell*)cell).color;
}

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [self.view endEditing:YES];
    
    Circle *circle;
    Person* person;
    
    switch ( sortingMode )
    {
        case SORTING_DISTANCE:
        case SORTING_RANK:
            
            switch (indexPath.section )
            {
                case 0: person = usersHereNow[indexPath.row]; break;
                case 1: person = usersNearbyToday[indexPath.row]; break;
                case 2: person = usersRecent[indexPath.row]; break;
                case 3:
                    circle = [globalData getCircle:CIRCLE_FBOTHERS];
                    person = [circle getPersons][indexPath.row];
                    break;
            }
            break;
        default:    // ENGAGEMENT
            person = sortedUsers[indexPath.row];
            break;
    }
    
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
    activityIndicator.originY = searchView.frame.origin.y + searchView.frame.size.height + 20;
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
