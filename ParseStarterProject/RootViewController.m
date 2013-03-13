

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

#import "ParseStarterProjectAppDelegate.h"
#import "AsyncImageView.h"

#import "TestFlightSDK/TestFlight.h"

#define ROW_HEIGHT 60

@implementation RootViewController

@synthesize initialized;
@synthesize activityIndicator;

#pragma mark -
#pragma mark Buttons


- (void)filterClicked{
    FilterViewController *filterViewController = [[FilterViewController alloc] initWithNibName:@"FilterView" bundle:nil];
    [self.navigationController pushViewController:filterViewController animated:YES];
}


- (void)newMeetupClicked{
    NewMeetupViewController *newMeetupViewController = [[NewMeetupViewController alloc] initWithNibName:@"NewMeetupView" bundle:nil];
    UINavigationController *navigation = [[UINavigationController alloc]initWithRootViewController:newMeetupViewController];
    [self.navigationController presentViewController:navigation
                                            animated:YES completion:nil];
}


#pragma mark -
#pragma mark Data reload




#pragma mark -
#pragma mark View loadi


- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    activityIndicator.center = self.view.center;
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
    // Activity indicator
    activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityIndicator.hidesWhenStopped = YES;
    NSLog(@"%f",self.view.frame.size.height);
    activityIndicator.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleTopMargin;
    [self.view addSubview:activityIndicator];
    
    // Navigation bar
    [self.navigationItem setHidesBackButton:true animated:false];
    /*self.navigationItem.rightBarButtonItems = @[
                [[UIBarButtonItem alloc] initWithTitle:@"New meet-up" style:UIBarButtonItemStyleBordered target:self action:@selector(newMeetupClicked)],
                [[UIBarButtonItem alloc] initWithTitle:@"Filter" style:UIBarButtonItemStyleBordered target:self action:@selector(filterClicked)]];*/
    
    // Table view
    UINib *nib = [UINib nibWithNibName:@"PersonCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"PersonCellIdent"];
    self.tableView.tableFooterView = [[UIView alloc]init];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.rowHeight = ROW_HEIGHT;
    
    // Data reloading

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
	Circle *circle = [globalData getCircleByNumber:section];
	NSArray *persons = [circle getPersons];
	return [persons count];
}

- (NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section {
	// Section title is the region name
    Circle *circle = [globalData getCircleByNumber:section];
	return [Circle getCircleName:circle.idCircle];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath  {
		
	static NSString *CellIdentifier = @"PersonCellIdent";
    
	PersonCell *personCell = (PersonCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
	// Get the time zones for the region for the section
	Circle* circle = [globalData getCircleByNumber:indexPath.section];
	Person *person = [circle getPersons][indexPath.row];
    [personCell.personImage loadImageFromURL:person.imageURL];
    personCell.personName.text = person.strName;
    personCell.personDistance.text = person.strDistance;
    personCell.personRole.text = person.strRole;
    personCell.personArea.text = person.strArea;

	return personCell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger nRow = indexPath.row;
    NSInteger nSection = indexPath.section;
    Circle *circle = [globalData getCircleByNumber:nSection];
    Person* person = [circle getPersons][nRow];
    
    // Empty profile, should open invite window
    if ( person.idCircle == CIRCLE_FBOTHERS ) {
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
