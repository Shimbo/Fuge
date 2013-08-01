

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

- (void) reloadClicked
{
    // UI
    [self.activityIndicator startAnimating];
    self.navigationController.view.userInteractionEnabled = FALSE;
    
    // Loading
    [globalData reloadFriendsInBackground];
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
    [[self tableView] reloadData];
}


#pragma mark -
#pragma mark View loading

- (void) recalcEngagement
{
    arrayEngagementUsers = [NSMutableArray arrayWithCapacity:100];
    for ( Circle* circle in [globalData getCircles] )
        if ( circle.idCircle != CIRCLE_FBOTHERS)
            [arrayEngagementUsers addObjectsFromArray:circle.getPersons];
	[arrayEngagementUsers sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        if ( [((Person*)obj1) getConversationCountStats:TRUE onlyMessages:FALSE] > [((Person*)obj2) getConversationCountStats:TRUE onlyMessages:FALSE] )
            return NSOrderedAscending;
        else
            return NSOrderedDescending;
    }];
}

- (void) viewDidLoad {
    [super viewDidLoad];

#ifdef TARGET_FUGE
    sortingMode = SORTING_RANK;
#elif defined TARGET_S2C
    sortingMode = SORTING_DISTANCE;
#endif
    
    // Navigation bar
    [self.navigationItem setHidesBackButton:true animated:false];
    
    // Table view
    UINib *nib = [UINib nibWithNibName:@"PersonCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"PersonCellIdent"];
    self.tableView.tableFooterView = [[UIView alloc]init];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.rowHeight = ROW_HEIGHT;
    
    // Buttons
#ifdef TARGET_FUGE
    matchBtn = [[UIBarButtonItem alloc] initWithTitle:sortingModeTitles[sortingMode+1] style:UIBarButtonItemStyleBordered target:self action:@selector(matchClicked)];
    UIBarButtonItem *reloadBtn = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"BUTTONS_RELOAD",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(reloadClicked)];
    [self.navigationItem setRightBarButtonItems:@[reloadBtn, matchBtn]];
#elif defined TARGET_S2C
    UIBarButtonItem *reloadBtn = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"BUTTONS_RELOAD",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(reloadClicked)];
    [self.navigationItem setRightBarButtonItems:@[reloadBtn]];
#endif
    
    // Engagement admin info
    [self recalcEngagement];
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
    // Admin stuff
    [self recalcEngagement];
    
    // Data refresh
    [self.activityIndicator stopAnimating];
    self.navigationController.view.userInteractionEnabled = TRUE;
    [[self tableView] reloadData];
}

- (void) loadingFailed
{
    [self.activityIndicator stopAnimating];
    self.navigationController.view.userInteractionEnabled = TRUE;
}


#pragma mark -
#pragma mark Table view datasource and delegate methods


- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView {
    
    if ( sortingMode == SORTING_DISTANCE )
        return [[globalData getCircles] count];
    else if ( sortingMode == SORTING_RANK )
        return /*([globalData getCircle:CIRCLE_2O].getPersons.count ? 1 : 0) + ([globalData getCircle:CIRCLE_RANDOM].getPersons.count ? 1 : 0);*/2;
    else // SORTING_ENGAGEMENT
        return 1;
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
	
    Circle *circle;
    switch (sortingMode)
    {
        case SORTING_DISTANCE:
            circle = [globalData getCircleByNumber:section];
            return [circle getPersons].count;
        case SORTING_RANK:
            circle = [globalData getCircle:(section == 0 ? CIRCLE_2O : CIRCLE_RANDOM )];
            return [circle getPersons].count;
        default:    // ENGAGEMENT
            return arrayEngagementUsers.count;
    }
}

- (NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section {
    Circle *circle;
	switch ( sortingMode )
    {
        case SORTING_DISTANCE:
            circle = [globalData getCircleByNumber:section];
            return [Circle getCircleName:circle.idCircle];
        case SORTING_RANK:
            circle = [globalData getCircle:(section == 0 ? CIRCLE_2O : CIRCLE_RANDOM )];
            return [Circle getCircleName:circle.idCircle];
        default:    // ENGAGEMENT
            return @"Sorting by engagement";
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath  {
		
	static NSString *CellIdentifier = @"PersonCellIdent";
    
	PersonCell *personCell = (PersonCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
    Circle *circle;
	Person *person;
    
    switch ( sortingMode )
    {
        case SORTING_DISTANCE:
            circle = [globalData getCircleByNumber:indexPath.section];
            person = [circle getPersons][indexPath.row];
            break;
        case SORTING_RANK:
            circle = [globalData getCircle:(indexPath.section == 0 ? CIRCLE_2O : CIRCLE_RANDOM )];
            person = [circle getPersonsSortedByRank][indexPath.row];
            break;
        default:    // ENGAGEMENT
            person = arrayEngagementUsers[indexPath.row];
            break;
    }
    
    [personCell.personImage loadImageFromURL:person.smallAvatarUrl];
    personCell.personName.text = [person fullName];
    if ( person.idCircle == CIRCLE_FBOTHERS )
        personCell.personDistance.text = @"Invite!";
    else
    {
        NSString* distanceString = [person distanceString];
        if ( distanceString.length > 0 )
            personCell.personDistance.text = distanceString;
        else
            personCell.personDistance.text = @"Unknown";
    }
    
    personCell.color = [UIColor whiteColor];
    personCell.personInfo.text = @"";
    
#ifdef TARGET_S2C
    personCell.personStatus.text = person.strStatus;
    personCell.personRole.text = [person jobInfo];
#elif defined TARGET_FUGE
    // Matches
    if ( person.idCircle != CIRCLE_FBOTHERS )
    {
        NSString* strMatches = [NSString stringWithFormat:@"%d matches", person.matchesTotal];
        if ( bIsAdmin )
            strMatches = [strMatches stringByAppendingString:[NSString stringWithFormat:@"+%d", person.matchesAdminBonus]];
        personCell.personInfo.text = strMatches;
        if ( sortingMode == SORTING_RANK )
        {
            NSUInteger matchesRank = person.matchesRank;
            float fColor = 1.0f - ((float)(matchesRank > MATCHING_COLOR_RANK_MAX ? MATCHING_COLOR_RANK_MAX : matchesRank))/MATCHING_COLOR_RANK_MAX / MATCHING_COLOR_BRIGHTNESS;
            personCell.color = [UIColor
                        colorWithRed: (MATCHING_COLOR_COMPONENT_R+(255.0f-MATCHING_COLOR_COMPONENT_R)*fColor)/255.0f
                        green:(MATCHING_COLOR_COMPONENT_G+(255.0f-MATCHING_COLOR_COMPONENT_G)*fColor)/255.0f
                        blue:(MATCHING_COLOR_COMPONENT_B+(255.0f-MATCHING_COLOR_COMPONENT_B)*fColor)/255.0f alpha:1.0f];
        }
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
    cell.backgroundColor = ((PersonCell*)cell).color;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger nRow = indexPath.row;
    NSInteger nSection = indexPath.section;
    Circle *circle;
    Person* person;
    
    switch ( sortingMode )
    {
        case SORTING_DISTANCE:
            circle = [globalData getCircleByNumber:nSection];
            person = [circle getPersons][nRow];
            break;
        case SORTING_RANK:
            circle = [globalData getCircle:(nSection == 0 ? CIRCLE_2O : CIRCLE_RANDOM )];
            person = [circle getPersonsSortedByRank][nRow];
            break;
        default:    // ENGAGEMENT
            person = arrayEngagementUsers[nRow];
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
