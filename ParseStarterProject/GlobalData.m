//
//  GlobalData.m
//  SecondCircle
//
//  Created by Mikhail Larionov on 1/5/13.
//
//

#import "GlobalData.h"
#import "GlobalVariables.h"
#import "PushManager.h"

@implementation GlobalData

static GlobalData *sharedInstance = nil;

// Get the shared instance and create it if necessary.
+ (GlobalData *)sharedInstance {
    if (sharedInstance == nil) {
        sharedInstance = [[super allocWithZone:NULL] init];
    }
    
    return sharedInstance;
}

// Initialization
- (id)init
{
    self = [super init];
    
    if (self) {
        circles = [[NSMutableDictionary alloc] init];
        meetups = [[NSMutableArray alloc] init];
    }
    
    return self;
}


// We don't want to allocate a new instance, so return the current one.
+ (id)allocWithZone:(NSZone*)zone {
    return [self sharedInstance];
}

// Equally, we don't want to generate multiple copies of the singleton.
- (id)copyWithZone:(NSZone *)zone {
    return self;
}



- (NSArray*) getCircles
{
    return [circles allValues];
}

- (Circle*)getCircle:(NSUInteger)circle
{
    Circle* result = [circles objectForKey:[Circle getCircleName:circle]];
    if ( result == nil )
    {
        result = [[Circle alloc] init:circle];
        [circles setObject:result forKey:[Circle getCircleName:circle]];
    }
    return result;
}

- (NSArray*) getMeetups
{
    return meetups;
}









- (void)addPerson:(PFUser*)user userCircle:(NSUInteger)circleUser
{
    // Same user
    NSString *strId = [user objectForKey:@"fbId"];
    if ( [strId compare:[ [PFUser currentUser] objectForKey:@"fbId"] ] == NSOrderedSame )
        return;
    
    // Already added users
    for (Circle *circle in [circles allValues])
    {
        NSMutableArray* per = [circle getPersons];
        for ( int n = 0; n < [per count]; n++ )
        {
            Person* person = per[n];
            if ( [strId compare:person.strId] == NSOrderedSame )
                return;
        }
    }
    
    // Creating user: name
    NSString* strName = [user objectForKey:@"fbName"];
    
    // Distance calculation
    NSString* strDistance = @"? km";
    PFGeoPoint *geoPointUser = [[PFUser currentUser] objectForKey:@"location"];
    PFGeoPoint *geoPointFriend = [user objectForKey:@"location"];
    CLLocation* locationFriend = nil;
    CLLocationDistance distance = 40000000.0f;
    if ( geoPointUser && geoPointFriend )
    {
        CLLocation* locationUser = [[CLLocation alloc] initWithLatitude:geoPointUser.latitude longitude:geoPointUser.longitude];
        locationFriend = [[CLLocation alloc] initWithLatitude:geoPointFriend.latitude longitude:geoPointFriend.longitude];
        distance = [locationUser distanceFromLocation:locationFriend];
        
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
    NSString* strCircle = [Circle getPersonType:circleUser];
    
    // Adding new person
    Person *person = [[Person alloc] init:@[strName, strId, strAge,
                      [user objectForKey:@"fbGender"],
                      strDistance, [user objectForKey:@"profileRole"],
                      [user objectForKey:@"profileArea"], strCircle]];
    [person setLocation:locationFriend.coordinate];
    
    Circle *circle = [globalData getCircle:circleUser];
    [circle addPerson:person];
}

- (void) reloadFbFriends:(id)friends
{
    // result will contain an array with your user's friends in the "data" key
    NSArray *friendObjects = [friends objectForKey:@"data"];
    NSMutableArray *friendIds = [NSMutableArray arrayWithCapacity:friendObjects.count];
    
    // Create a list of friends' Facebook IDs
    for (NSDictionary *friendObject in friendObjects)
        [friendIds addObject:[friendObject objectForKey:@"id"]];
            
    // Saving user FB friends
    [[PFUser currentUser] addUniqueObjectsFromArray:friendIds forKey:@"fbFriends"];
    
    // FB friends query
    PFQuery *friendQuery = [PFUser query];
    [friendQuery whereKey:@"fbId" containedIn:friendIds];
    [friendQuery whereKey:@"profileDiscoverable" notEqualTo:[[NSNumber alloc] initWithBool:FALSE]];
    NSArray *friendUsers = [friendQuery findObjects];
    
    // Data collection
    for (PFUser *friendUser in friendUsers)
    {
        // Collecting second circle data
        NSMutableArray *friendFriendIds = [friendUser objectForKey:@"fbFriends"];
        [[PFUser currentUser] addUniqueObjectsFromArray:friendFriendIds forKey:@"fbFriends2O"];
        
        // Adding first circle friends
        [self addPerson:friendUser userCircle:CIRCLE_FB];
        
        // Notification for that user if the friend is new
        [pushManager sendPushNewUser:PUSH_NEW_FBFRIEND idTo:[friendUser objectForKey:@"fbId"]];
    }
}

- (void) reload2OFriends
{
    // Second circle friends query
    NSMutableArray *friend2OIds = [[PFUser currentUser] objectForKey:@"fbFriends2O"];
    PFQuery *friend2OQuery = [PFUser query];
    [friend2OQuery whereKey:@"fbId" containedIn:friend2OIds];
    [friend2OQuery whereKey:@"profileDiscoverable" notEqualTo:[[NSNumber alloc] initWithBool:FALSE]];
    NSArray *friend2OUsers = [friend2OQuery findObjects];
    
    // Data collection
    for (PFUser *friend2OUser in friend2OUsers)
    {
        [self addPerson:friend2OUser userCircle:CIRCLE_2O];
        
        // Notification for that user if the friend is new
        [pushManager sendPushNewUser:PUSH_NEW_2OFRIEND idTo:[friend2OUser objectForKey:@"fbId"]];
    }
}

- (void) reloadRandom
{
    // Query
    PFQuery *friendAnyQuery = [PFUser query];
    [friendAnyQuery whereKey:@"location" nearGeoPoint:[[PFUser currentUser] objectForKey:@"location"] withinKilometers:RANDOM_PERSON_KILOMETERS];
    [friendAnyQuery whereKey:@"profileDiscoverable" notEqualTo:[[NSNumber alloc] initWithBool:FALSE]];
    NSArray *friendAnyUsers = [friendAnyQuery findObjects];
    
    // Adding users
    for (PFUser *friendAnyUser in friendAnyUsers)
        [self addPerson:friendAnyUser userCircle:CIRCLE_RANDOM];
    
}

- (void)addMeetup:(Meetup*)meetup
{
    // TODO: test if such meetup was already added
    
    [meetups addObject:meetup];
}

- (Meetup*)addMeetupWithData:(PFObject*)meetupData
{
    // TODO: test if such meetup was already added
    
    Meetup* meetup = [[Meetup alloc] init];
    [meetup unpack:meetupData];
    
    // 2ndO meetups check
    if ( meetup.privacy == 1 )
    {
        Boolean bSkip = true;
        NSArray* friends = [[PFUser currentUser] objectForKey:@"fbFriends2O"];
        if ( [friends containsObject:meetup.strOwnerId ] )
            bSkip = false;
        friends = [[PFUser currentUser] objectForKey:@"fbFriends"];
        if ( [friends containsObject:meetup.strOwnerId ] )
            bSkip = false;
        if ( [meetup.strOwnerId compare:[[PFUser currentUser] objectForKey:@"fbId"] ] == NSOrderedSame )
            bSkip = false;
        if ( bSkip )
            return nil;
    }
    
    [meetups addObject:meetup];
    
    return meetup;
}


- (void)reloadMeetups
{
    PFQuery *meetupAnyQuery = [PFQuery queryWithClassName:@"Meetup"];
    
    // Location filter
    [meetupAnyQuery whereKey:@"location" nearGeoPoint:[[PFUser currentUser] objectForKey:@"location"] withinKilometers:RANDOM_EVENT_KILOMETERS];
    
    // Date-time filter
    NSNumber* timestampNow = [[NSNumber alloc] initWithDouble:[[NSDate date] timeIntervalSince1970]];
    [meetupAnyQuery whereKey:@"meetupTimestamp" greaterThan:timestampNow];
    
    // Privacy filter
    NSNumber* privacyType = [[NSNumber alloc] initWithInt:MEETUP_PRIVATE];
    [meetupAnyQuery whereKey:@"privacy" notEqualTo:privacyType];
    
    // Query for public/2O meetups
    NSArray *meetupsData = [meetupAnyQuery findObjects];
    for (PFObject *meetupData in meetupsData)
        [self addMeetupWithData:meetupData];
    
    // Query for meetups with invitations (both private and distant 2O or public)
    meetupAnyQuery = [PFQuery queryWithClassName:@"Meetup"];
    [meetupAnyQuery whereKey:@"meetupTimestamp" greaterThan:timestampNow];
    // TODO: add invitation check
    meetupsData = [meetupAnyQuery findObjects];
    //for (PFObject *meetupData in meetupsData)
    //    [self addMeetup:meetupData];
}


- (void)reload:(RootViewController*)controller
{
    // Clean for sure old data
    [self clean];
    
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
                                               id result, NSError *error)
        {
            if (!error)
            {
                // FB friends
                [self reloadFbFriends:result];
                
                // 2O friends
                [self reload2OFriends];
                
                // Random friends
                [self reloadRandom];
                
                // Meetups
                [self reloadMeetups];
                
                // Pushes sent for new users, turn it off
                [globalVariables pushToFriendsSent];
                
                // Save user data
                [[PFUser currentUser] save];
                
                // Reload table
                [controller reloadFinished];
            }
            else
            {
                NSLog(@"Uh oh. An error occurred: %@", error);
            }
        }];
    }];
}

- (void)clean
{
    [sharedInstance->circles removeAllObjects];
}


@end