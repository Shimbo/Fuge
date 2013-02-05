

#import <Parse/Parse.h>

#import "CoreLocation/CLLocationManager.h"
#import <CoreLocation/CoreLocation.h>
#import "UIKit/UIActivityIndicatorView.h"

#import "RootViewController.h"
#import "ProfileViewController.h"
#import "MapViewController.h"
#import "FilterViewController.h"
#import "UserProfileController.h"
#import "NewEventViewController.h"
#import "PersonCell.h"
#import "Person.h"
#import "Circle.h"
#import "GlobalVariables.h"
#import "GlobalData.h"

#import "ParseStarterProjectAppDelegate.h"

#import "TestFlightSDK/TestFlight.h"

#define ROW_HEIGHT 60

@implementation RootViewController

//@synthesize displayList;
@synthesize initialized;
@synthesize activityIndicator;

- (id)initWithStyle:(UITableViewStyle)style {
	if (self = [super initWithStyle:style]) {
		//self.title = NSLocalizedString(@"Connections", @"Connections");
        self.initialized = NO;

	}
	return self;
}

- (void)viewWillAppear:(BOOL)animated {
}

- (void)profileClicked{
    ProfileViewController *profileViewController = [[ProfileViewController alloc] initWithNibName:@"ProfileView" bundle:nil];
    [self.navigationController pushViewController:profileViewController animated:YES];
    //[self.navigationController setNavigationBarHidden:true animated:true];
}

- (void)filterClicked{
    FilterViewController *filterViewController = [[FilterViewController alloc] initWithNibName:@"FilterView" bundle:nil];
    [self.navigationController pushViewController:filterViewController animated:YES];
    //[self.navigationController setNavigationBarHidden:true animated:true];
}

- (void)mapClicked{
    MapViewController *mapViewController = [[MapViewController alloc] initWithNibName:@"MapView" bundle:nil];
    [self.navigationController pushViewController:mapViewController animated:YES];
}

- (void)newMeetupClicked{
    NewEventViewController *newEventViewController = [[NewEventViewController alloc] initWithNibName:@"NewEventView" bundle:nil];
    [self.navigationController setNavigationBarHidden:true animated:true];
    [self.navigationController pushViewController:newEventViewController animated:YES];
}

- (void) reloadFinished
{
    self.initialized = YES;
    self.tableView.alpha = 0;
    [[self tableView] reloadData];
    [UIView animateWithDuration:0.3 animations:^{
        self.tableView.alpha = 1;
    }];
    
    [TestFlight passCheckpoint:@"List loading ended"];
    
    [activityIndicator stopAnimating];
    self.navigationController.view.userInteractionEnabled = YES;
    [self.navigationController popViewControllerAnimated:TRUE];
}

- (void) actualReload
{
    [globalData reload:self];
}

- (void) reloadData {
    [activityIndicator startAnimating];
    self.navigationController.view.userInteractionEnabled = NO;
    [self performSelectorOnMainThread:@selector(actualReload) withObject:nil waitUntilDone:NO];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    activityIndicator.center = self.view.center;
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.rowHeight = ROW_HEIGHT;
    activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityIndicator.hidesWhenStopped = YES;
    NSLog(@"%f",self.view.frame.size.height);
    
    activityIndicator.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleTopMargin;
    [self.view addSubview:activityIndicator];
    
    [self.navigationItem setHidesBackButton:true animated:false];
    
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:
                                              [[UIBarButtonItem alloc] initWithTitle:@"Profile" style:UIBarButtonItemStyleBordered target:self /*.viewDeckController*/ action:@selector(profileClicked)],
                                              [[UIBarButtonItem alloc] initWithTitle:@"Filter" style:UIBarButtonItemStyleBordered target:self action:@selector(filterClicked)],
                                              [[UIBarButtonItem alloc] initWithTitle:@"Map" style:UIBarButtonItemStyleBordered target:self action:@selector(mapClicked)],
                                              nil];
    
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:
                                               [[UIBarButtonItem alloc] initWithTitle:@"New meet-up" style:UIBarButtonItemStyleBordered target:self /*.viewDeckController*/ action:@selector(newMeetupClicked)],
                                               nil];
    
/*    buttonProfile = [[UIBarButtonItem alloc] initWithTitle:@"Profile" style:UIBarButtonItemStylePlain target:self action:@selector(profileClicked)];
    buttonFilter = [[UIBarButtonItem alloc] initWithTitle:@"Filter" style:UIBarButtonItemStyleBordered target:self action:@selector(filterClicked)];*/
    
//    [self.navigationItem setLeftBarButtonItem:buttonProfile];
//    [self.navigationItem setRightBarButtonItem:buttonFilter];
    
    self.tableView.tableFooterView = [[UIView alloc]init];

    if (!self.initialized) {
        [TestFlight passCheckpoint:@"List loading started"];
        [self reloadData];
    }else{
        [TestFlight passCheckpoint:@"List restored"];
    }

    
}


- (void)viewWillDisappear:(BOOL)animated {
}


#pragma mark -
#pragma mark Table view datasource and delegate methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView {
	// Number of sections is the number of regions
    NSInteger nCount = [[globalData getCircles] count];
	return nCount;
}


- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
	// Number of rows is the number of time zones in the region for the specified section
	Circle *circle = [globalData getCircle:section+1];
	NSArray *persons = [circle getPersons];
	return [persons count];
}


- (NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section {
	// Section title is the region name
    Circle *circle = [globalData getCircle:section+1];
	return [Circle getCircleName:circle.idCircle];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath  {
		
	static NSString *CellIdentifier = @"TimeZoneCell";
		
	PersonCell *personCell = (PersonCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
	if (personCell == nil) {
		personCell = [[PersonCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
//		personCell.frame = CGRectMake(0.0, 0.0, 320.0, ROW_HEIGHT);
	}
	
	// Get the time zones for the region for the section
	Circle* circle = [globalData getCircle:indexPath.section+1];
	NSArray *persons = [circle getPersons];
	
	// Get the time zone wrapper for the row
	[personCell setPerson:persons[indexPath.row]];
	return personCell;
}



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger nRow = indexPath.row;
    NSInteger nSection = indexPath.section;
    Circle *circle = [globalData getCircle:nSection+1];
    Person* person = [circle getPersons][nRow];
    
    // Empty profile, should open invite window
    if ( [person.strRole compare:@""] == NSOrderedSame ) {
        NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       @"Check out this awesome app.",  @"message",
                                       nil];
        
        [[PFFacebookUtils facebook] dialog:@"apprequests" andParams:params andDelegate:nil];
    }
    else {
        UserProfileController *userProfileController = [[UserProfileController alloc] initWithNibName:@"UserProfile" bundle:nil];
        [self.navigationController pushViewController:userProfileController animated:YES];
        [userProfileController setPerson:person];
    }
    
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}


@end
