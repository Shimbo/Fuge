

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

#import "ParseStarterProjectAppDelegate.h"

#import "TestFlightSDK/TestFlight.h"

#define ROW_HEIGHT 60

@implementation RootViewController

@synthesize displayList;
@synthesize initialized;
@synthesize activityIndicator;

- (id)initWithStyle:(UITableViewStyle)style {
	if (self = [super initWithStyle:style]) {
		//self.title = NSLocalizedString(@"Connections", @"Connections");
		self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
		self.tableView.rowHeight = ROW_HEIGHT;
        activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        initialized = false;
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

- (void)addPerson:(NSDictionary*)user userCircle:(NSString*)circleStr circleList:(NSMutableArray*)circles {
    
    // Filters  
    if ( [[PFUser currentUser] objectForKey:@"filter1stCircle"] )
        if ( [[[PFUser currentUser] objectForKey:@"filter1stCircle"] boolValue] == false )
            if ( [circleStr compare:@"First circle"] == NSOrderedSame )
                return;
    if ( [[PFUser currentUser] objectForKey:@"filterEverybody"] )
        if ( [[[PFUser currentUser] objectForKey:@"filterEverybody"] boolValue] == false )
            if ( [circleStr compare:@"Random connections"] == NSOrderedSame )
                return;
    NSString* strProfileGender = [user objectForKey:@"fbGender"];
    NSNumber* numberFilterGender = [[PFUser currentUser] objectForKey:@"filterGender"];
    if ( strProfileGender && numberFilterGender )
        if ( numberFilterGender != 0 )
            if ( ( [strProfileGender compare:@"male"] == NSOrderedSame && numberFilterGender.intValue == 1 ) || ( [strProfileGender compare:@"female"] == NSOrderedSame && numberFilterGender.intValue == 2 ) )
                return;
    NSString* strProfileRole = [user objectForKey:@"profileRole"];
    NSString* strFilterRole = [[PFUser currentUser] objectForKey:@"filterRole"];
    if ( strFilterRole && strProfileRole )
        if ( [strProfileRole compare:strFilterRole] != NSOrderedSame )
            if ( [strFilterRole compare:@"Any"] != NSOrderedSame )
                return;
    // For distance check see one page below
    
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
    for (Circle *circle in circles) {
        for ( int n = 0; n < [circle.persons count]; n++ ) {
            Person* person = circle.persons[n];
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
    
    // Distance calculation
    NSString* strDistance = @"? km";
    PFGeoPoint *geoPointUser = [[PFUser currentUser] objectForKey:@"location"];
    PFGeoPoint *geoPointFriend = [user objectForKey:@"location"];
    CLLocation* locationFriend = nil;
    if ( geoPointUser && geoPointFriend )
    {
        CLLocation* locationUser = [[CLLocation alloc] initWithLatitude:geoPointUser.latitude longitude:geoPointUser.longitude];
        locationFriend = [[CLLocation alloc] initWithLatitude:geoPointFriend.latitude longitude:geoPointFriend.longitude];
        CLLocationDistance distance = [locationUser distanceFromLocation:locationFriend];
        
        // Distance check
        NSNumber* numberFilterDistance = [[PFUser currentUser] objectForKey:@"filterDistance"];
        if ( numberFilterDistance )
            if ( ( numberFilterDistance.intValue == 1 && distance > 100000 ) || ( numberFilterDistance.intValue == 2 && distance > 10000 ) )
                return;
        
        if ( distance < 1000.0f )
            strDistance = [[NSString alloc] initWithFormat:@"%.2f km", distance/1000.0f];
        else if ( distance < 10000.0f )
            strDistance = [[NSString alloc] initWithFormat:@"%.1f km", distance/1000.0f];
        else
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
    
    // Circle
    NSString* strCircle = @"";
    if ( [circleStr compare:@"First circle"] == NSOrderedSame )
        strCircle = @"FB friend";
    if ( [circleStr compare:@"Second circle"] == NSOrderedSame )
        strCircle = @"2ndO friend";
    
    // Adding new person
    Person *person = [[Person alloc] init:@[strName, strId, strAge,
                      [user objectForKey:@"fbGender"],
                      strDistance, [user objectForKey:@"profileRole"],
                      [user objectForKey:@"profileArea"], strCircle]];
    [person setLocation:locationFriend.coordinate];
    
    Circle *circle = [Circle circleNamed:circleStr];
    if ( ! circle )
    {
        circle = [Circle newCircleWithName:circleStr];
        [circles addObject:circle];
    }
    [circle addPerson:person];
}

- (void) actualReload {
    
    Boolean bShouldSendPushToFriends = [globalVariables shouldSendPushToFriends];
    NSMutableDictionary* dicPushesSent = [[NSMutableDictionary alloc] init];
    
    // Clean for sure old data
    [Circle clean];
    
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
                NSMutableArray *circles = [NSMutableArray array];
                
                // findObjects will return a list of PFUsers that are friends
                // with the current user
                [friendQuery findObjectsInBackgroundWithBlock:^(NSArray *friendUsers, NSError* error) {
                    
                    for (NSDictionary *friendUser in friendUsers)
                    {
                        // Collecting second circle data
                        NSMutableArray *friendFriendIds = [friendUser objectForKey:@"fbFriends"];
                        [[PFUser currentUser] addUniqueObjectsFromArray:friendFriendIds forKey:@"fbFriends2O"];
                        
                        // Adding first circle friends
                        [self addPerson:friendUser userCircle:@"First circle" circleList:circles];
                        
                        // Notification for that user if the friend is new
                        if ( bShouldSendPushToFriends )
                        {
                            NSString* strName = [[PFUser currentUser] objectForKey:@"fbName"];
                            NSString* strId = [friendUser objectForKey:@"fbId"];
                            NSString* strPush =[[NSString alloc] initWithFormat:@"Woohoo! Your Facebook friend %@ joined Second Circle! Check if you've got new connections!", strName];
                            NSString* strChannel =[[NSString alloc] initWithFormat:@"fb%@", strId];
                            if ( [strId compare:[[PFUser currentUser] objectForKey:@"fbId"]] != NSOrderedSame )
                                [PFPush sendPushMessageToChannelInBackground:strChannel withMessage:strPush];
                            [dicPushesSent setObject:@"Sent" forKey:strId];
                        }
                    }
                    
                    [[PFUser currentUser] save];
                    
                    // Second circle friends
                    NSMutableArray *friend2OIds = [[PFUser currentUser] objectForKey:@"fbFriends2O"];
                    PFQuery *friend2OQuery = [PFUser query];
                    [friend2OQuery whereKey:@"fbId" containedIn:friend2OIds];
                    [friend2OQuery findObjectsInBackgroundWithBlock:^(NSArray *friend2OUsers, NSError* error){
                        
                        for (NSDictionary *friend2OUser in friend2OUsers)
                        {
                            [self addPerson:friend2OUser userCircle:@"Second circle" circleList:circles];
                            
                            // Notification for that user if the friend is new
                            if ( bShouldSendPushToFriends )
                            {
                                NSString* strName = [[PFUser currentUser] objectForKey:@"fbName"];
                                NSString* strId = [friend2OUser objectForKey:@"fbId"];
                                NSString* strPush =[[NSString alloc] initWithFormat:@"Hurray! Your 2ndO friend %@ joined Second Circle!", strName];
                                NSString* strChannel =[[NSString alloc] initWithFormat:@"fb%@", strId];
                                if ( [strId compare:[[PFUser currentUser] objectForKey:@"fbId"]] != NSOrderedSame )
                                {
                                    if ( ! [dicPushesSent objectForKey:strId] )
                                        [PFPush sendPushMessageToChannelInBackground:strChannel withMessage:strPush];
                                    [dicPushesSent setObject:@"Sent" forKey:strId];
                                }
                            }
                        }
                        
                        // Everybody else
                        PFQuery *friendAnyQuery = [PFUser query];
                        [friendAnyQuery whereKey:@"location" nearGeoPoint:[[PFUser currentUser] objectForKey:@"location"] withinKilometers:RANDOM_PERSON_KILOMETERS];
                        [friendAnyQuery findObjectsInBackgroundWithBlock:^(NSArray *friendAnyUsers, NSError* error){
                            
                            for (NSDictionary *friendAnyUser in friendAnyUsers)
                                [self addPerson:friendAnyUser userCircle:@"Random connections" circleList:circles];
                            
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
                                
                                Circle *circle = [Circle circleNamed:@"Invite friends"];
                                if ( ! circle )
                                {
                                    circle = [Circle newCircleWithName:@"Invite friends"];
                                    [circles addObject:circle];
                                }
                                
                                NSString* strTemp = [[NSString alloc] initWithFormat:@"Expand your network!"];
                                [circle addPersonWithComponents:@[strTemp, strId, @"", @"", @"", @"", @"", @""]];
                                
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
                            displayList = (NSArray *) circles;
                            [[self tableView] reloadData];
                            
                            NSArray *visibleCells = self.tableView.visibleCells;
                            for (PersonCell *cell in visibleCells) {
                                [cell redisplay];
                            }
                            
                            initialized = true;
                            
                            [TestFlight passCheckpoint:@"List loading ended"];
                            
                            
                            [activityIndicator stopAnimating];
                            [activityIndicator removeFromSuperview];
                            self.view.userInteractionEnabled = YES;
                            
                            [self.navigationController popViewControllerAnimated:TRUE];
                            
                            // Push sent for the first time
                            [globalVariables pushToFriendsSent];
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

- (void) reloadData {
    CGPoint ptCenter = CGPointMake(self.navigationController.view.frame.size.width/2, self.navigationController.view.frame.size.height/2);
    activityIndicator.center = ptCenter;
    [self.navigationController.view addSubview:activityIndicator];
    [activityIndicator startAnimating];
    self.view.userInteractionEnabled = NO;

    [self performSelectorOnMainThread:@selector(actualReload) withObject:nil waitUntilDone:NO];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Loading data with indicator
    if ( ! initialized )
    {
        [TestFlight passCheckpoint:@"List loading started"];
        
        [self reloadData];
        //[self performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
    }
    else
        [TestFlight passCheckpoint:@"List restored"];
}

- (void) viewDidLoad {
    
    // UI
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
    
    [super viewDidLoad];
}


- (void)viewWillDisappear:(BOOL)animated {
}


#pragma mark -
#pragma mark Table view datasource and delegate methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView {
	// Number of sections is the number of regions
	return [displayList count];
}


- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
	// Number of rows is the number of time zones in the region for the specified section
	Circle *circle = [displayList objectAtIndex:section];
	NSArray *persons = circle.persons;
	return [persons count];
}


- (NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section {
	// Section title is the region name
	Circle *circle = [displayList objectAtIndex:section];
	return circle.name;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath  {
		
	static NSString *CellIdentifier = @"TimeZoneCell";
		
	PersonCell *personCell = (PersonCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
	if (personCell == nil) {
		personCell = [[PersonCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
		personCell.frame = CGRectMake(0.0, 0.0, 320.0, ROW_HEIGHT);
	}
	
	// Get the time zones for the region for the section
	Circle *circle = [displayList objectAtIndex:indexPath.section];
	NSArray *persons = circle.persons;
	
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
    Circle* circle = [displayList objectAtIndex:nSection];
    Person* person = circle.persons[nRow];
    
    // Showing profile (TODO: check if user was created, then skip this step)
    //[self.navigationController popViewControllerAnimated:false];
    
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
