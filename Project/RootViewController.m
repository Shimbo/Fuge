

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
    if ( sortingMode > 1 )
        sortingMode = 0;
    [matchBtn setTitle:sortingModeTitles[sortingMode]];
    [[self tableView] reloadData];
}


#pragma mark -
#pragma mark View loading


- (void) viewDidLoad {
    [super viewDidLoad];
    sortingMode = 0;
    
    // Navigation bar
    [self.navigationItem setHidesBackButton:true animated:false];
    
    // Table view
    UINib *nib = [UINib nibWithNibName:@"PersonCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"PersonCellIdent"];
    self.tableView.tableFooterView = [[UIView alloc]init];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.rowHeight = ROW_HEIGHT;
    
    // Buttons
    matchBtn = [[UIBarButtonItem alloc] initWithTitle:sortingModeTitles[0] style:UIBarButtonItemStyleBordered target:self action:@selector(matchClicked)];
    UIBarButtonItem *reloadBtn = [[UIBarButtonItem alloc] initWithTitle:@"Reload" style:UIBarButtonItemStyleBordered target:self action:@selector(reloadClicked)];
    [self.navigationItem setRightBarButtonItems:@[reloadBtn, matchBtn]];
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
    else
        return ([globalData getCircle:CIRCLE_2O].getPersons.count ? 1 : 0) + ([globalData getCircle:CIRCLE_RANDOM].getPersons.count ? 1 : 0);
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
	
    Circle *circle;
    if ( sortingMode == SORTING_DISTANCE )
        circle = [globalData getCircleByNumber:section];
    else
        circle = [globalData getCircle:(section == 0 ? CIRCLE_2O : CIRCLE_RANDOM )];
    return [circle getPersons].count;
}

- (NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section {
    Circle *circle;
	if ( sortingMode == SORTING_DISTANCE )
        circle = [globalData getCircleByNumber:section];
    else
        circle = [globalData getCircle:(section == 0 ? CIRCLE_2O : CIRCLE_RANDOM )];
    return [Circle getCircleName:circle.idCircle];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath  {
		
	static NSString *CellIdentifier = @"PersonCellIdent";
    
	PersonCell *personCell = (PersonCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
	// Get the time zones for the region for the section
	Circle* circle;
	Person *person;
    
    if ( sortingMode == SORTING_DISTANCE )
    {
        circle = [globalData getCircleByNumber:indexPath.section];
        person = [circle getPersons][indexPath.row];
    }
    else
    {
        circle = [globalData getCircle:(indexPath.section == 0 ? CIRCLE_2O : CIRCLE_RANDOM )];
        person = [circle getPersonsSortedByRank][indexPath.row];
    }
    
    [personCell.personImage loadImageFromURL:person.imageURL];
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
    if ( sortingMode == SORTING_RANK )
    {
        NSString* strMatches = [NSString stringWithFormat:@"Matches: %d", person.matchesTotal];
        personCell.personInfo.text = strMatches;
        NSUInteger matchesRank = person.matchesRank;
        float fColor = 1.0f - ((float)(matchesRank > MATCHING_COLOR_RANK_MAX ? MATCHING_COLOR_RANK_MAX : matchesRank))/MATCHING_COLOR_RANK_MAX;
        personCell.color = [UIColor
            colorWithRed: (MATCHING_COLOR_COMPONENT_R+(255.0f-MATCHING_COLOR_COMPONENT_R)*fColor)/255.0f
            green:(MATCHING_COLOR_COMPONENT_G+(255.0f-MATCHING_COLOR_COMPONENT_G)*fColor)/255.0f
            blue:(MATCHING_COLOR_COMPONENT_B+(255.0f-MATCHING_COLOR_COMPONENT_B)*fColor)/255.0f alpha:1.0f];
    }
    else
    {
        personCell.color = [UIColor colorWithWhite:1.0f alpha:1.0f];
        personCell.personInfo.text = @"";
    }
    personCell.personStatus.text = [person jobInfo];
    
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
    
    if ( sortingMode == SORTING_DISTANCE )
    {
        circle = [globalData getCircleByNumber:nSection];
        person = [circle getPersons][nRow];
    }
    else
    {
        circle = [globalData getCircle:(nSection == 0 ? CIRCLE_2O : CIRCLE_RANDOM )];
        person = [circle getPersonsSortedByRank][nRow];
    }
    
    // Empty profile, should open invite window
    if ( person.idCircle == CIRCLE_FBOTHERS ) {
        
        [Person showInviteDialog:person.strId];
    }
    else {
        UserProfileController *userProfileController = [[UserProfileController alloc] initWithNibName:@"UserProfile" bundle:nil];
        [userProfileController setPerson:person];
        [self.navigationController pushViewController:userProfileController animated:YES];
    }
    
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}


@end
