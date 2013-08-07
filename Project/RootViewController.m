

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

#import "AppDelegate.h"
#import "AsyncImageView.h"

#import "TestFlightSDK/TestFlight.h"

@implementation RootViewController

#define ROW_HEIGHT  60

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
    [[self tableView] reloadData];
}


#pragma mark -
#pragma mark View loading

- (void) recalcAndSortUsers
{
    sortedUsers = [NSMutableArray arrayWithCapacity:100];
    for ( Circle* circle in [globalData getCircles] )
        if ( circle.idCircle != CIRCLE_FBOTHERS)
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
    else if ( sortingMode == SORTING_DISTANCE )
    {
        [sortedUsers sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
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

- (void) viewDidLoad {
    [super viewDidLoad];
    
    sortingMode = SORTING_DISTANCE;
    
    // Navigation bar
    [self.navigationItem setHidesBackButton:true animated:false];
    
    // Table view
    UINib *nib = [UINib nibWithNibName:@"PersonCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"PersonCell"];
    self.tableView.tableFooterView = [[UIView alloc]init];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.rowHeight = ROW_HEIGHT;
    
    // Buttons
#ifdef TARGET_FUGE
    matchBtn = [[UIBarButtonItem alloc] initWithTitle:sortingModeTitles[sortingMode+1] style:UIBarButtonItemStyleBordered target:self action:@selector(matchClicked)];
    //UIBarButtonItem *reloadBtn = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"BUTTONS_RELOAD",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(reloadClicked)];
    [self.navigationItem setRightBarButtonItems:@[matchBtn]];
#endif
    
    // Users sorting
    [self recalcAndSortUsers];
    
    // Refresh control
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshView:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:refreshControl];
}

- (void) viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    if ( [globalData getLoadingStatus:LOADING_CIRCLES] == LOAD_STARTED )
    {
        [self.activityIndicator startAnimating];
        self.navigationController.view.userInteractionEnabled = FALSE;
    }
    else
        self.navigationController.view.userInteractionEnabled = TRUE;
    
    [[self tableView] reloadData];
}

- (void) reloadFinished
{
    // Sort users
    [self recalcAndSortUsers];
    
    // Data refresh
    [self.activityIndicator stopAnimating];
    self.navigationController.view.userInteractionEnabled = TRUE;
    [refreshControl endRefreshing];
    [[self tableView] reloadData];
}

- (void) loadingFailed
{
    [self.activityIndicator stopAnimating];
    self.navigationController.view.userInteractionEnabled = TRUE;
}


#pragma mark -
#pragma mark Table view datasource and delegate methods

-(void)refreshView:(UIRefreshControl *)refreshControl {

    self.navigationController.view.userInteractionEnabled = FALSE;
    [globalData reloadFriendsInBackground];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView {
    
    if ( sortingMode == SORTING_DISTANCE )
#ifdef TARGET_FUGE
        return 2;
#elif defined TARGET_S2C
        return 1;
#endif
    else if ( sortingMode == SORTING_RANK )
        return 2;
    else // SORTING_ENGAGEMENT
        return 1;
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
	
    Circle *circle;
    switch (sortingMode)
    {
        case SORTING_DISTANCE:
            return (section == 0 ? sortedUsers.count : [globalData getCircle:CIRCLE_FBOTHERS].getPersons.count );
        case SORTING_RANK:
            circle = [globalData getCircle:(section == 0 ? CIRCLE_2O : CIRCLE_RANDOM )];
            return [circle getPersons].count;
        default:    // ENGAGEMENT
            return sortedUsers.count;
    }
}

- (NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section {
#ifdef TARGET_S2C
    return nil;
#endif
    Circle *circle;
	switch ( sortingMode )
    {
        case SORTING_DISTANCE:
            if ( section == 0 )
                return @"Active users";
            circle = [globalData getCircle:CIRCLE_FBOTHERS];
            return [Circle getCircleName:circle.idCircle];
        case SORTING_RANK:
            circle = [globalData getCircle:(section == 0 ? CIRCLE_2O : CIRCLE_RANDOM )];
            return [Circle getCircleName:circle.idCircle];
        default:    // ENGAGEMENT
            return @"Sorting by engagement";
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath  {
		
	static NSString *CellIdentifier = @"PersonCell";
    
	PersonCell *personCell = (PersonCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    [personCell setNeedsDisplay];
	
    Circle *circle;
	Person *person;
    
    switch ( sortingMode )
    {
        case SORTING_DISTANCE:
            if ( indexPath.section == 0 )
                person = sortedUsers[indexPath.row];
            else
            {
                circle = [globalData getCircle:CIRCLE_FBOTHERS];
                person = [circle getPersons][indexPath.row];
            }
            break;
        case SORTING_RANK:
            circle = [globalData getCircle:(indexPath.section == 0 ? CIRCLE_2O : CIRCLE_RANDOM )];
            person = [circle getPersonsSortedByRank][indexPath.row];
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger nRow = indexPath.row;
    NSInteger nSection = indexPath.section;
    Circle *circle;
    Person* person;
    
    switch ( sortingMode )
    {
        case SORTING_DISTANCE:
            if ( indexPath.section == 0 )
                person = sortedUsers[indexPath.row];
            else
            {
                circle = [globalData getCircle:CIRCLE_FBOTHERS];
                person = [circle getPersons][nRow];
            }
            break;
        case SORTING_RANK:
            circle = [globalData getCircle:(nSection == 0 ? CIRCLE_2O : CIRCLE_RANDOM )];
            person = [circle getPersonsSortedByRank][nRow];
            break;
        default:    // ENGAGEMENT
            person = sortedUsers[nRow];
            break;
    }
    
    // Empty profile, should open invite window
    if ( person.idCircle == CIRCLE_FBOTHERS ) {
        
        [person showInviteDialog];
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


@end
