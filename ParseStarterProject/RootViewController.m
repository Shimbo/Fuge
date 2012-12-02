

#import <Parse/Parse.h>

#import "CoreLocation/CLLocationManager.h"
#import <CoreLocation/CoreLocation.h>

#import "RootViewController.h"
#import "ProfileViewController.h"
#import "UserProfileController.h"
#import "PersonCell.h"
#import "Person.h"
#import "Region.h"

#import "ParseStarterProjectAppDelegate.h"

#define ROW_HEIGHT 60

@implementation RootViewController

@synthesize displayList;
@synthesize buttonFilter;
@synthesize buttonProfile;
@synthesize initialized;

- (id)initWithStyle:(UITableViewStyle)style {
	if (self = [super initWithStyle:style]) {
		self.title = NSLocalizedString(@"Connections", @"Connections");
		self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
		self.tableView.rowHeight = ROW_HEIGHT;
        initialized = false;
	}
	return self;
}

- (void)viewWillAppear:(BOOL)animated {
}

- (void)profileClicked{
    ProfileViewController *profileViewController = [[ProfileViewController alloc] initWithNibName:@"ProfileView" bundle:nil];
    [self.navigationController pushViewController:profileViewController animated:YES];
    [self.navigationController setNavigationBarHidden:true animated:true];
}

- (void)filterClicked{
    
}

- (void)addPerson:(NSDictionary*)user userCircle:(NSString*)circle regionsList:(NSMutableArray*)regions {
    
    // Discovery disabled
    if ( [user objectForKey:@"profileDiscoverable"] )
        if ( [[user objectForKey:@"profileDiscoverable"] boolValue] == FALSE)
            return;
    
    // Same user
    NSString *strId = [user objectForKey:@"fbId"];
    if ( [strId compare:[ [PFUser currentUser] objectForKey:@"fbId"] ] == NSOrderedSame )
        return;
    
    // Already added users
    Boolean bFound = false;
    for (Region *region in regions) {
        for ( int n = 0; n < [region.persons count]; n++ ) {
            Person* person = region.persons[n];
            if ( [strId compare:person.strId] == NSOrderedSame )
            {
                bFound = true;
                break;
            }
        }
        if ( bFound )
            break;
    }
    if ( bFound )
        return;
    
    // Creation of user
    NSString* strName = [user objectForKey:@"fbName"];
    
    Region *region = [Region regionNamed:circle];
    if ( ! region )
    {
        region = [Region newRegionWithName:circle];
        [regions addObject:region];
    }
    
    // Distance calculation
    NSString* strDistance = @"? km";
    if ( [[PFUser currentUser] objectForKey:@"loclat"] && [user objectForKey:@"loclat"] )
    {
        CLLocation* locationUser = [[CLLocation alloc] initWithLatitude:[[[PFUser currentUser] objectForKey:@"loclat"] doubleValue] longitude:[[[PFUser currentUser] objectForKey:@"loclon"] doubleValue]];
        CLLocation* locationFriend = [[CLLocation alloc] initWithLatitude:[[user objectForKey:@"loclat"] doubleValue] longitude:[[user objectForKey:@"loclon"] doubleValue]];
        CLLocationDistance distance = [locationUser distanceFromLocation:locationFriend];
        strDistance = [[NSString alloc] initWithFormat:@"%.0f km", distance/1000.0f];
    }
    
    // Age calculations
    NSDateFormatter* myFormatter = [[NSDateFormatter alloc] init];
    [myFormatter setDateFormat:@"MM/dd/yyyy"];
    NSDate* birthday = [myFormatter dateFromString:[user objectForKey:@"fbBirthday"]];
    NSDate* now = [NSDate date];
    NSDateComponents* ageComponents = [[NSCalendar currentCalendar]
                                       components:NSYearCalendarUnit
                                       fromDate:birthday
                                       toDate:now
                                       options:0];
    NSInteger age = [ageComponents year];
    NSString *strAge = [NSString stringWithFormat:@"%d y/o", age];
    
    // Adding new person
    Person *person = [[Person alloc] init:@[strName, strId, strAge,
                      [user objectForKey:@"fbGender"],
                      strDistance, [user objectForKey:@"profileRole"],
                      [user objectForKey:@"profileArea"]]];
    [region addPerson:person];
}

- (void) reloadData {
    
    // Clean for sure old data
    [Region clean];
    
    // Current user data
    PF_FBRequest *request = [PF_FBRequest requestForMe];
    [request startWithCompletionHandler:^(PF_FBRequestConnection *connection,
                                          id result, NSError *error) {
        if (!error) {
            // Store the current user's Facebook ID on the user
            [[PFUser currentUser] setObject:[result objectForKey:@"id"]
                                     forKey:@"fbId"];
            [[PFUser currentUser] setObject:[result objectForKey:@"name"]
                                     forKey:@"fbName"];
            [[PFUser currentUser] setObject:[result objectForKey:@"birthday"]
                                     forKey:@"fbBirthday"];
            [[PFUser currentUser] setObject:[result objectForKey:@"gender"]
                                     forKey:@"fbGender"];
            [[PFUser currentUser] save];
        }
        else {
            NSLog(@"Uh oh. An error occurred: %@", error);
        }
    
    // FB friendlist
    PF_FBRequest *request2 = [PF_FBRequest requestForMyFriends];
    [request2 startWithCompletionHandler:^(PF_FBRequestConnection *connection,
                                           id result, NSError *error) {
        if (!error) {
            // result will contain an array with your user's friends in the "data" key
            NSArray *friendObjects = [result objectForKey:@"data"];
            NSMutableArray *friendIds = [NSMutableArray arrayWithCapacity:friendObjects.count];
            
            // Create a list of friends' Facebook IDs
            for (NSDictionary *friendObject in friendObjects) {
                [friendIds addObject:[friendObject objectForKey:@"id"]];
            }
            
            // Saving user friends
            [[PFUser currentUser] addUniqueObjectsFromArray:friendIds
                                                     forKey:@"fbFriends"];
            
            // Construct a PFUser query that will find friends whose facebook ids
            // are contained in the current user's friend list.
            PFQuery *friendQuery = [PFUser query];
            [friendQuery whereKey:@"fbId" containedIn:friendIds];
            
            // List initialization
            NSMutableArray *regions = [NSMutableArray array];
            
            // findObjects will return a list of PFUsers that are friends
            // with the current user
            [friendQuery findObjectsInBackgroundWithBlock:^(NSArray *friendUsers, NSError* error) {
            
                for (NSDictionary *friendUser in friendUsers)
                {
                    // Collecting second circle data
                    NSMutableArray *friendFriendIds = [friendUser objectForKey:@"fbFriends"];
                    [[PFUser currentUser] addUniqueObjectsFromArray:friendFriendIds forKey:@"fbFriends2O"];
                    
                    // Adding first circle friends
                    [self addPerson:friendUser userCircle:@"First circle" regionsList:regions];
                }
                
                [[PFUser currentUser] save];
                                
                // Second circle friends
                NSMutableArray *friend2OIds = [[PFUser currentUser] objectForKey:@"fbFriends2O"];
                PFQuery *friend2OQuery = [PFUser query];
                [friend2OQuery whereKey:@"fbId" containedIn:friend2OIds];
                [friend2OQuery findObjectsInBackgroundWithBlock:^(NSArray *friend2OUsers, NSError* error){

                    for (NSDictionary *friend2OUser in friend2OUsers)
                        [self addPerson:friend2OUser userCircle:@"Second circle" regionsList:regions];
                    
                    // Everybody else
                    PFQuery *friendAnyQuery = [PFUser query];
                    [friendAnyQuery findObjectsInBackgroundWithBlock:^(NSArray *friendAnyUsers, NSError* error){
                        
                    for (NSDictionary *friendAnyUser in friendAnyUsers)
                        [self addPerson:friendAnyUser userCircle:@"Random connections" regionsList:regions];
                    
                    // Invite friends
                    NSInteger count = 0;
                    for (NSString *strId in friendIds)
                    {
                        Boolean bFound = false;
                        for (NSDictionary *friendUser in friendUsers)
                        {
                            NSString *strId2 = [friendUser objectForKey:@"fbId"];
                            if ( [strId compare:strId2 ] == NSOrderedSame )
                                bFound = true;
                        }
                        if ( bFound )
                            continue;
                        
                        Region *region = [Region regionNamed:@"Invite friends"];
                        if ( ! region )
                        {
                            region = [Region newRegionWithName:@"Invite friends"];
                            [regions addObject:region];
                        }
                        
                        NSString* strTemp = [[NSString alloc] initWithFormat:@"Expand your network!"];
                        [region addPersonWithComponents:@[strTemp, strId, @"", @"", @"", @"", @""]];
                        
                        count++;
                        if ( count >= 1 )
                            break;
                    }
                    
                    
                    // Sorting stuff
                    //                     NSDate *date = [NSDate date];
                    // Now sort the time zones by name
                    //                     for (Region *region in regions) {
                    //                         [region sortZones];
                    //                         [region setDate:date];
                    //                     }
                    // Sort the regions
                    //                     NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
                    //                     NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
                    //                     [regions sortUsingDescriptors:sortDescriptors];
                    
                    
                    // Setup
                    displayList = (NSArray *) regions;
                    [[self tableView] reloadData];
                    
                    NSArray *visibleCells = self.tableView.visibleCells;
                    for (PersonCell *cell in visibleCells) {
                        [cell redisplay];
                    }
                    
                    initialized = true;
                        
                    }];
                }];
             }];
        }
        else {
            NSLog(@"Uh oh. An error occurred: %@", error);
        }
    }];
    }];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Loading data
    if ( ! initialized )
        [self reloadData];
}

- (void) viewDidLoad {
    
    // UI
    [self.navigationItem setHidesBackButton:true animated:false];
    
    buttonProfile = [[UIBarButtonItem alloc] initWithTitle:@"Profile" style:UIBarButtonItemStylePlain target:self action:@selector(profileClicked)];
    buttonFilter = [[UIBarButtonItem alloc] initWithTitle:@"Filter" style:UIBarButtonItemStyleBordered target:self action:@selector(filterClicked)];
    
    [self.navigationItem setLeftBarButtonItem:buttonProfile];
    
    // TODO: to be done later
    //[self.navigationItem setRightBarButtonItem:buttonFilter];
    
    [super viewDidLoad];
}


- (void)viewWillDisappear:(BOOL)animated {
//	self.minuteTimer = nil;
//	self.regionsTimer = nil;
}


#pragma mark -
#pragma mark Table view datasource and delegate methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView {
	// Number of sections is the number of regions
	return [displayList count];
}


- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
	// Number of rows is the number of time zones in the region for the specified section
	Region *region = [displayList objectAtIndex:section];
	NSArray *persons = region.persons;
	return [persons count];
}


- (NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section {
	// Section title is the region name
	Region *region = [displayList objectAtIndex:section];
	return region.name;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath  {
		
	static NSString *CellIdentifier = @"TimeZoneCell";
		
	PersonCell *personCell = (PersonCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
	if (personCell == nil) {
		personCell = [[PersonCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
		personCell.frame = CGRectMake(0.0, 0.0, 320.0, ROW_HEIGHT);
	}
	
	// Get the time zones for the region for the section
	Region *region = [displayList objectAtIndex:indexPath.section];
	NSArray *persons = region.persons;
	
	// Get the time zone wrapper for the row
	[personCell setPerson:[persons objectAtIndex:indexPath.row]];
	return personCell;
}



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	/*
	 To conform to the Human Interface Guidelines, selections should not be persistent --
	 deselect the row after it has been selected.
	 */
    NSInteger nRow = indexPath.row;
    NSInteger nSection = indexPath.section;
    Region* circle = [displayList objectAtIndex:nSection];
    Person* person = circle.persons[nRow];
    
    // Showing profile (TODO: check if user was created, then skip this step)
    //[self.navigationController popViewControllerAnimated:false];
    UserProfileController *userProfileController = [[UserProfileController alloc] initWithNibName:@"UserProfile" bundle:nil];
    [self.navigationController pushViewController:userProfileController animated:YES];
    [userProfileController setPerson:person];
    
    //NSString *url = [NSString stringWithFormat:@"http://facebook.com/%@", pZ.strId]; ;
    //[[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
    
    
    
/*    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity: 7];
    
    // set the frictionless requests parameter to "1"
    [params setObject: @"1" forKey:@"frictionless"];
    [params setObject: @"Test Invite" forKey:@"title"];
    [params setObject:appID forKey:@"app_id"];
 
    [params setObject: @"Test" forKey: @"message"];
 
    if([friendsToInvite count] != 0) {
        NSString * stringOfFriends = [friendsToInvite componentsJoinedByString:@","];
        [params setObject:stringOfFriends forKey:@"to"];
        NSLog(@"%@", params);
    }
 
    // show the request dialog
    [facebook dialog:@"apprequests" andParams:params andDelegate: nil];*/
    
    
    
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}


@end
