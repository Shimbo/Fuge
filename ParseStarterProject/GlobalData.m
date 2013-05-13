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
#import "MapViewController.h"
#import "FSVenue.h"
#import "Message.h"
#import "LocationManager.h"

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
        _circleByNumber = [NSMutableDictionary dictionaryWithCapacity:5];
        messages = nil;
        comments = nil;
        nInboxLoadingStage = 0;
        nMapLoadingStage = 0;
        nCirclesLoadingStage = 0;
        nInboxUnreadCount = 0;
        newFriendsFb = nil;
        newFriends2O = nil;
        nLoadStatusMain = LOAD_STARTED;
        nLoadStatusMap = LOAD_STARTED;
        nLoadStatusCircles = LOAD_STARTED;
        nLoadStatusInbox = LOAD_STARTED;
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


#pragma mark -
#pragma mark Getters


- (NSArray*) getCircles
{
    return [circles allValues];
}

- (Circle*)getCircle:(CircleType)circle
{
    Circle* result = [circles objectForKey:[Circle getCircleName:circle]];
    if ( result == nil )
    {
        result = [[Circle alloc] init:circle];
        [circles setObject:result forKey:[Circle getCircleName:circle]];
        _circleByNumber[@(result.idCircle-1)] = result;
    }
    
    return result;
}

NSInteger sortByName(id num1, id num2, void *context)
{
    Circle* v1 = num1;
    Circle* v2 = num2;
    if (v1.idCircle < v2.idCircle)
        return NSOrderedAscending;
    else if (v1.idCircle > v2.idCircle)
        return NSOrderedDescending;
    else
        return NSOrderedSame;
}


- (Circle*)getCircleByNumber:(NSUInteger)num
{
    if (!_circleByNumber[@(num)]) {
        NSArray* values = [circles allValues];
        for (Circle *circle in values) {
            _circleByNumber[@(circle.idCircle-1)] = circle;
        }
    }
    return _circleByNumber[@(num)];
    
    //it's bad to sort circles each time.
    /*
    NSArray* sortedValues = [values sortedArrayUsingFunction:sortByName context:nil];
    if (sortedValues.count > num) {
        return sortedValues[num];
    }
    return nil;
     */
}

- (NSArray*) getPersonsByIds:(NSArray*)strFbIds
{
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:strFbIds.count];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"strId IN %@",strFbIds];
    for ( Circle* circle in [circles allValues] )
        [result addObjectsFromArray:[circle.getPersons filteredArrayUsingPredicate:predicate]];
    return result;
}

- (Person*) getPersonById:(NSString*)strFbId
{
    for ( Circle* circle in [circles allValues] )
        for (Person* person in [circle getPersons])
            if ( [person.strId compare:strFbId] == NSOrderedSame )
                return person;
    return nil;
}

-(NSArray*)searchForUserName:(NSString*)searchStr
{
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:100];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"strName CONTAINS[cd] %@",searchStr];
    for ( Circle* circle in [circles allValues] )
        [result addObjectsFromArray:[circle.getPersons filteredArrayUsingPredicate:predicate]];
    return result;
}


- (NSArray*) getMeetups
{
    return meetups;
}

- (Meetup*) getMeetupById:(NSString*)strId
{
    for (Meetup* meetup in meetups)
        if ( [meetup.strId compare:strId] == NSOrderedSame )
            return meetup;
    return nil;
}


#pragma mark -
#pragma mark Global


- (void)loadingFailed:(NSUInteger)nStage status:(NSUInteger)nStatus
{
    switch ( nStage )
    {
        case LOADING_MAIN:
            nLoadStatusMain = nStatus;
            [[NSNotificationCenter defaultCenter]postNotificationName:kLoadingMainFailed
                                                               object:nil];
            break;
        case LOADING_MAP:
            nLoadStatusMap = nStatus;
            [[NSNotificationCenter defaultCenter]postNotificationName:kLoadingMapFailed
                                                               object:nil];
            break;
        case LOADING_CIRCLES:
            nLoadStatusCircles = nStatus;
            [[NSNotificationCenter defaultCenter]postNotificationName:kLoadingCirclesFailed
                                                               object:nil];
            break;
        case LOADING_INBOX:
            nLoadStatusInbox = nStatus;
            [[NSNotificationCenter defaultCenter]postNotificationName:kLoadingInboxFailed
                                                               object:nil];
            break;
    }
}

- (NSUInteger) getLoadingStatus:(NSUInteger)nStage
{
    switch ( nStage )
    {
        case LOADING_MAIN:
            return nLoadStatusMain;
        case LOADING_MAP:
            return nLoadStatusMap;
        case LOADING_CIRCLES:
            return nLoadStatusCircles;
        case LOADING_INBOX:
            return nLoadStatusInbox;
    }
    return LOAD_OK;
}

- (void)loadData
{
    nLoadStatusMain = LOAD_STARTED;
    
    // Clean old data
    [circles removeAllObjects];
    [meetups removeAllObjects];
    
    // Current user data
    FBRequest *request = [FBRequest requestForMe];
    [request startWithCompletionHandler:^(FBRequestConnection *connection,
                                          id result, NSError *error) {
        if ( error )
        {
            NSLog(@"Uh oh. An error occurred: %@", error);
            [self loadingFailed:LOADING_MAIN status:LOAD_NOFACEBOOK];
        }
        else
        {
            // Store the current user's Facebook ID on the user
            [[PFUser currentUser] setObject:[result objectForKey:@"id"]
                                     forKey:@"fbId"];
            [[PFUser currentUser] setObject:[result objectForKey:@"name"]
                                     forKey:@"fbName"];
            [[PFUser currentUser] setObject:[result objectForKey:@"birthday"]
                                     forKey:@"fbBirthday"];
            [[PFUser currentUser] setObject:[result objectForKey:@"gender"]
                                     forKey:@"fbGender"];
            [[PFUser currentUser] setObject:[globalVariables currentVersion]
                                     forKey:@"version"];
            [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                
                if ( error )
                {
                    NSLog(@"Uh oh. An error occurred: %@", error);
                    [self loadingFailed:LOADING_MAIN status:LOAD_NOCONNECTION];
                }
                else
                {
                    // Main load ended, send notification about it
                    nLoadStatusMain = LOAD_OK;
                    [[NSNotificationCenter defaultCenter]postNotificationName:kLoadingMainComplete object:nil];
                    
                    // Push channels initialization
                    [pushManager initChannelsForTheFirstTime:[result objectForKey:@"id"]];
                    
                    // FB friends, 2O friends, fb friends not installed the app
                    [self reloadFriendsInBackground];
                    
                    // Map data: random people, meetups, threads, etc - location based
                    [self reloadMapInfoInBackground:nil toNorthEast:nil];
                    
                    // FB Meetups
                    [self loadFBMeetups];
                    
                    // Inbox
                    [self reloadInboxInBackground];
                }
            }];
        }
    }];
}

// Will not use any load status, on fail just nothing
- (void)reloadFriendsInBackground
{
    nCirclesLoadingStage = 0;
    nLoadStatusCircles = LOAD_STARTED;
    
    FBRequest *request2 = [FBRequest requestForMyFriends];
    [request2 startWithCompletionHandler:^(FBRequestConnection *connection,
                                           id result, NSError *error)
     {
         if ( error )
         {
             NSLog(@"Uh oh. An error occurred: %@", error);
             [self loadingFailed:LOADING_CIRCLES status:LOAD_NOFACEBOOK];
         }
         else
         {
             // FB friends, 2O/FBout inside, 2O will call pushes block and user save
             [self loadFbFriendsInBackground:result];
         }
     }];
}

// Will use secondary load status to show problems with connection
- (void)reloadMapInfoInBackground:(PFGeoPoint*)southWest toNorthEast:(PFGeoPoint*)northEast
{
    nMapLoadingStage = 0;
    nLoadStatusMap = LOAD_STARTED;
    
    // Random friends
    [self loadRandomPeopleInBackground:southWest toNorthEast:northEast];
    
    // Meetups
    [self loadMeetupsInBackground:southWest toNorthEast:northEast];
}


#pragma mark -
#pragma mark Friends


- (void)addPerson:(PFUser*)user userCircle:(NSUInteger)circleUser
{
    // Same user
    NSString *strId = [user objectForKey:@"fbId"];
    if ( [strId compare:[ [PFUser currentUser] objectForKey:@"fbId"] ] == NSOrderedSame )
        return;
    
    // Already added users: only update location
    Person* person = [self getPersonById:strId];
    if ( person )
    {
        // Changing from random to friend
        if ( person.idCircle == CIRCLE_RANDOM )
        {
            [[globalData getCircle:person.idCircle] removePerson:person];
            [[globalData getCircle:circleUser] addPerson:person];
            [person changeCircle:circleUser];
        }
        // Updating location
        [person updateLocation:[user objectForKey:@"location"]];
        return;
    }
    
    // Adding new person
    person = [[Person alloc] init:user circle:circleUser];
    
    Circle *circle = [globalData getCircle:circleUser];
    [circle addPerson:person];
}

// Load friends in background
- (void) loadFbFriendsInBackground:(id)friends
{
    // result will contain an array with your user's friends in the "data" key
    NSArray *friendObjects = [friends objectForKey:@"data"];
    NSMutableArray *friendIds = [NSMutableArray arrayWithCapacity:friendObjects.count];
    
    // Create a list of friends' Facebook IDs
    for (NSDictionary *friendObject in friendObjects)
        [friendIds addObject:[friendObject objectForKey:@"id"]];
    
    // Storing old friends lists (to calculate new friends later in this call)
    NSArray* oldFriendsFb = [[[PFUser currentUser] objectForKey:@"fbFriends"] copy];
    NSArray* oldFriends2O = [[[PFUser currentUser] objectForKey:@"fbFriends2O"] copy];
    
    // Saving user FB friends
    [[PFUser currentUser] addUniqueObjectsFromArray:friendIds forKey:@"fbFriends"];
    
    // FB friends query
    PFQuery *friendQuery = [PFUser query];
    [friendQuery whereKey:@"fbId" containedIn:friendIds];
    [friendQuery whereKey:@"profileDiscoverable" notEqualTo:[[NSNumber alloc] initWithBool:FALSE]];
    [friendQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
    {
        NSArray *friendUsers = objects;
        
        if ( error )
        {
            NSLog(@"error:%@", error);
            [self loadingFailed:LOADING_CIRCLES status:LOAD_NOCONNECTION];
        }
        else
        {
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
            
            // Sorting FB friends
            [[self getCircle:CIRCLE_FB] sort];
            
            // Excluding FB friends from 2O friends
            NSMutableArray* temp2O = [[PFUser currentUser] objectForKey:@"fbFriends2O"];
            if ( temp2O )
                [temp2O removeObjectsInArray:friendIds];   // To exclude FB friends from 2O
            else
            {
                temp2O = [[NSMutableArray alloc] initWithCapacity:30];
                [[PFUser currentUser] setObject:temp2O forKey:@"fbFriends2O"];
            }
            
            // Creating new friends list
            if ( oldFriendsFb )
            {
                newFriendsFb = [[[PFUser currentUser] objectForKey:@"fbFriends"] mutableCopy];
                newFriends2O = [[[PFUser currentUser] objectForKey:@"fbFriends2O"] mutableCopy];
                [newFriendsFb removeObjectsInArray:oldFriendsFb];
                if ( oldFriends2O )
                    [newFriends2O removeObjectsInArray:oldFriends2O];
                
                // Removing people not using the app
                NSMutableArray *filteredItemsFb = [NSMutableArray array];
                NSMutableArray *filteredItems2O = [NSMutableArray array];
                for (NSString *friendUser in newFriendsFb)
                    if ( [self getPersonById:friendUser] )
                        [filteredItemsFb addObject:friendUser];
                for (NSString *friendUser in newFriends2O)
                    if ( [self getPersonById:friendUser] )
                        [filteredItems2O addObject:friendUser];
                newFriendsFb = filteredItemsFb;
                newFriends2O = filteredItems2O;
            }
            
            // 2O friends
            [self load2OFriendsInBackground:friends];
        }
    }];
}

- (void) load2OFriendsInBackground:(id)friends
{
    // Second circle friends query
    NSMutableArray *friend2OIds = [[PFUser currentUser] objectForKey:@"fbFriends2O"];
    PFQuery *friend2OQuery = [PFUser query];
    [friend2OQuery whereKey:@"fbId" containedIn:friend2OIds];
    [friend2OQuery whereKey:@"profileDiscoverable" notEqualTo:[[NSNumber alloc] initWithBool:FALSE]];
    [friend2OQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        if ( error )
        {
            NSLog(@"error:%@", error);
            [self loadingFailed:LOADING_CIRCLES status:LOAD_NOCONNECTION];
        }
        else
        {
            NSArray *friend2OUsers = objects;
            
            // Data collection
            for (PFUser *friend2OUser in friend2OUsers)
            {
                [self addPerson:friend2OUser userCircle:CIRCLE_2O];
                
                // Notification for that user if the friend is new
                [pushManager sendPushNewUser:PUSH_NEW_2OFRIEND idTo:[friend2OUser objectForKey:@"fbId"]];
            }
            
            // Sorting 2O friends
            [[self getCircle:CIRCLE_2O] sort];
            
            // Pushes sent for all new users, turn it off
            [globalVariables pushToFriendsSent];
            
            // Save user data as it's useful for other users to find 2O friends
            [[PFUser currentUser] saveInBackground]; // // TODO: here was Eventually - ?
        }
        
        // FB friends out of the app
        [self loadFbOthers:friends];
        
        [self incrementCirclesLoadingStage];
    }];
}

- (void) loadRandomPeopleInBackground:(PFGeoPoint*)southWest toNorthEast:(PFGeoPoint*)northEast
{
    // Query
    PFQuery *friendAnyQuery = [PFUser query];
    
    // We could load based on player location or map rect if he moved the map later
    if ( ! southWest )
    {
        PFGeoPoint* ptUser = [[PFUser currentUser] objectForKey:@"location"];
        if ( ! ptUser )
            ptUser = [locManager getDefaultPosition];
        
        [friendAnyQuery whereKey:@"location" nearGeoPoint:ptUser withinKilometers:RANDOM_PERSON_KILOMETERS];
    }
    else
    {
        [friendAnyQuery whereKey:@"location" withinGeoBoxFromSouthwest:southWest toNortheast:northEast];
    }
    [friendAnyQuery whereKey:@"profileDiscoverable" notEqualTo:[[NSNumber alloc] initWithBool:FALSE]];
    
    // Actual load
    [friendAnyQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        if ( error )
        {
            NSLog(@"error:%@", error);
            [self loadingFailed:LOADING_MAP status:LOAD_NOCONNECTION];
        }
        else
        {
            NSArray *friendAnyUsers = objects;
            
            // Adding users
            for (PFUser *friendAnyUser in friendAnyUsers)
                [self addPerson:friendAnyUser userCircle:CIRCLE_RANDOM];
            
            // Sorting random people
            [[self getCircle:CIRCLE_RANDOM] sort];
        }
        
        // In any case, increment loading stage
        [self incrementMapLoadingStage];
    }];
}

- (void) loadFbOthers:(id)friends
{
    NSMutableArray *friendIds = [[[PFUser currentUser] objectForKey:@"fbFriends"] mutableCopy];
    
    Circle *fbCircle = [globalData getCircle:CIRCLE_FBOTHERS];
    
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:30];
    
    // Filtering out added friends
    for (Circle *circle in [circles allValues]){
        [array addObjectsFromArray:[[circle getPersons]valueForKeyPath:@"strId"]];
    }
    [friendIds removeObjectsInArray:array];
    
    // Extracting FB data
    NSArray *friendObjects = [friends objectForKey:@"data"];
    
    // Creating persons for fb friends that don't use app yet
    for (NSString *strId in friendIds)
    {
        for (NSDictionary *friendObject in friendObjects)
        {
            // Comparing fb id with stored id (yeah, I'm too lazy to refactor this, TODO as it's n*n)
            NSString* strIdFb = [friendObject objectForKey:@"id"];
            if ( [strId compare:strIdFb] == NSOrderedSame )
            {
                Person* person = [[Person alloc] initEmpty:CIRCLE_FBOTHERS];
                person.strName = [friendObject objectForKey:@"name"];
                person.strId = strId;
                person.strRole = @"Invite!";
                [fbCircle addPerson:person];
            }
        }
    }
}


#pragma mark -
#pragma mark Meetups


// This one is used by new meetup window
- (void)addMeetup:(Meetup*)meetup
{
    // Test if such meetup was already added
    if ( [self getMeetupById:meetup.strId ] )
        return;
    
    [meetups addObject:meetup];
}

// This one is used by loader
- (Meetup*)addMeetupWithData:(PFObject*)meetupData
{
    // Test if such meetup was already added
    Meetup* meetup = [self getMeetupById:[meetupData objectForKey:@"meetupId" ] ];
    if ( meetup )
    {
        [meetup unpack:meetupData];
        return meetup;
    }
    
    // Expiration check
    NSDate* dateTimeExp = [meetupData objectForKey:@"meetupDateExp"];
    if ( [dateTimeExp compare:[NSDate date]] == NSOrderedAscending )
        return nil;
    
    meetup = [[Meetup alloc] init];
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

// Under construction!
- (void)loadFBMeetups
{
    NSString *query =
    @"{"
    @"'event_info':'SELECT eid, venue, name, start_time, end_time, creator, host, attending_count from event WHERE eid in (SELECT eid FROM event_member WHERE uid = me())',"
    @"'event_venue':'SELECT name, location, page_id FROM page WHERE page_id IN (SELECT venue.id FROM #event_info)',"
    @"}";
    NSDictionary *queryParam = [NSDictionary dictionaryWithObjectsAndKeys:
                                query, @"q", nil];
    
    [FBRequestConnection startWithGraphPath:@"/fql" parameters:queryParam
                        HTTPMethod:@"GET" completionHandler:^(FBRequestConnection *connection,
                        id result, NSError *error) {
        if (error) {
            NSLog(@"Error: %@", [error localizedDescription]);
        } else {
            //NSLog(@"Result: %@", result);
            
            NSArray* data = [result objectForKey:@"data"];
            NSArray* events = [((NSDictionary*) data[0]) objectForKey:@"fql_result_set"];
            NSArray* venues = [((NSDictionary*) data[1]) objectForKey:@"fql_result_set"];
            
            for ( NSDictionary* event in events )
            {
                for ( NSDictionary* venue in venues )
                {
                    NSDictionary* eventVenue = [event objectForKey:@"venue"];
                    if ( ! eventVenue )
                        break;
                    NSString* eventVenueId = [eventVenue objectForKey:@"id"];
                    if ( ! eventVenueId )
                        break;
                    NSDictionary* venueLocation = [venue objectForKey:@"location"];
                    if ( ! venueLocation )
                        break;
                    NSString* venueId = [venue objectForKey:@"page_id"];
                    if ( ! venueId )
                        break;
                    if ( [eventVenueId compare:venueId] == NSOrderedSame )
                    {
                        Meetup* meetup = [[Meetup alloc] initWithFbEvent:event venue:venue];
                        [self addMeetup:meetup];
                    }
                }
            }
        }
    }];
}

- (void)loadMeetupsInBackground:(PFGeoPoint*)southWest toNorthEast:(PFGeoPoint*)northEast
{
    PFQuery *meetupAnyQuery = [PFQuery queryWithClassName:@"Meetup"];
    meetupAnyQuery.limit = 1000;
    
    // Location filter
    if ( ! southWest )
    {
        PFGeoPoint* ptUser = [[PFUser currentUser] objectForKey:@"location"];
        if ( ! ptUser )
            ptUser = [locManager getDefaultPosition];

        [meetupAnyQuery whereKey:@"location" nearGeoPoint:ptUser withinKilometers:RANDOM_EVENT_KILOMETERS];
    }
    else
    {
        [meetupAnyQuery whereKey:@"location" withinGeoBoxFromSouthwest:southWest toNortheast:northEast];
    }
    
    // Date-time filter
    NSDate* dateHide = [NSDate date];
    [meetupAnyQuery whereKey:@"meetupDateExp" greaterThan:dateHide];
    
    // Privacy filter
    NSNumber* privacyTypePrivate = [[NSNumber alloc] initWithInt:MEETUP_PRIVATE];
    [meetupAnyQuery whereKey:@"privacy" notEqualTo:privacyTypePrivate];
    
    // Ascending order by creation date
    [meetupAnyQuery orderByAscending:@"createdAt"];
    
    // Query for public/2O meetups
    [meetupAnyQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if ( error )
        {
            NSLog(@"error:%@", error);
            [self loadingFailed:LOADING_MAP status:LOAD_NOCONNECTION];
        }
        else
        {
            NSArray *meetupsData = objects;
            for (PFObject *meetupData in meetupsData)
                [self addMeetupWithData:meetupData];
        }
        
        // In any case, increment loading stage
        [self incrementMapLoadingStage];
    }];
    
    // Query for events that user was subscribed to (to show also private and remote events/threads) - this query calls only for first request, not for the map reloads
    NSArray* subscriptions = [[PFUser currentUser] objectForKey:@"subscriptions"];
    if ( ! southWest && subscriptions && subscriptions.count > 0 )
    {
        meetupAnyQuery = [PFQuery queryWithClassName:@"Meetup"];
        meetupAnyQuery.limit = 1000;
        [meetupAnyQuery whereKey:@"meetupDateExp" greaterThan:dateHide];
        [meetupAnyQuery whereKey:@"meetupId" containedIn:subscriptions];

        // Query for public/2O meetups
        [meetupAnyQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
        {
            if ( error )
            {
                NSLog(@"error:%@", error);
                [self loadingFailed:LOADING_MAP status:LOAD_NOCONNECTION];
            }
            else
            {
                NSArray *meetupsData = objects;
                
                // Later we're updating subscription removing deleted and expired objects
                NSMutableArray* newSubscriptions = [[NSMutableArray alloc] initWithCapacity:meetupsData.count];
                for (PFObject *meetupData in meetupsData)
                {
                    Meetup* result = [self addMeetupWithData:meetupData];
                    NSString* strMeetupId = [meetupData objectForKey:@"meetupId"];
                    if ( ! result )
                        [self unsubscribeToThread:strMeetupId];
                    else
                        [newSubscriptions addObject:strMeetupId];
                }
                [[PFUser currentUser] setObject:newSubscriptions forKey:@"subscriptions"];
            }
            
            // In any case, increment loading stage
            [self incrementMapLoadingStage];
        }];
    }
    else
        [self incrementMapLoadingStage];
}



#pragma mark -
#pragma mark Invites

- (void)createInvite:(Meetup*)meetup objectTo:(Person*)recipient stringTo:(NSString*)strRecipient
{
    PFObject* invite = [PFObject objectWithClassName:@"Invite"];
    
    // Id, fromStr, fromId
    [invite setObject:meetup.strId forKey:@"meetupId"];
    [invite setObject:meetup.meetupData forKey:@"meetupData"];
    [invite setObject:[meetup.dateTime dateByAddingTimeInterval:meetup.durationSeconds] forKey:@"expirationDate"];
    [invite setObject:[NSNumber numberWithInt:meetup.meetupType] forKey:@"type"];
    [invite setObject:meetup.strSubject forKey:@"meetupSubject"];
    
    [invite setObject:strCurrentUserId forKey:@"idUserFrom"];
    [invite setObject:strCurrentUserName forKey:@"nameUserFrom"];
    [invite setObject:[PFUser currentUser] forKey:@"objUserFrom"];
    NSString* strTo = strRecipient;
    if ( recipient )
        strTo = recipient.strId;
    [invite setObject:strTo forKey:@"idUserTo"];
    NSNumber *inviteStatus = [[NSNumber alloc] initWithInt:INVITE_NEW];
    [invite setObject:inviteStatus forKey:@"status"];
    
    // Protection if there is object already
    invite.ACL = [PFACL ACLWithUser:[PFUser currentUser]];
    if ( recipient.personData )
    {
        [invite.ACL setReadAccess:true forUser:recipient.personData];
        [invite.ACL setWriteAccess:true forUser:recipient.personData];
    }
    else
    {
        [invite.ACL setPublicReadAccess:true];
        [invite.ACL setPublicWriteAccess:true];
    }
    
    [invite saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if ( error )
            NSLog(@"Uh oh. An error occurred: %@", error);
        [pushManager sendPushInviteForMeetup:meetup.strId user:strTo];
    }];
}


#pragma mark -
#pragma mark Comments


- (void)addComment:(PFObject*)comment
{
    [comments addObject:comment];
}

-(void)createCommentForMeetup:(Meetup*)meetup commentType:(CommentType)type commentText:(NSString*)text
{
    // Creating comment about meetup creation in db
    PFObject* comment = [PFObject objectWithClassName:@"Comment"];
    NSMutableString* strComment = [[NSMutableString alloc] initWithFormat:@""];
    Boolean bSystem = false;
    NSNumber* trueNum = [[NSNumber alloc] initWithInt:1];
    NSNumber* typeNum = [[NSNumber alloc] initWithInt:meetup.meetupType];
    
    switch (type)
    {
        case COMMENT_CREATED:
            [strComment appendString:[pCurrentUser objectForKey:@"fbName"]];
            if (meetup.meetupType == TYPE_MEETUP)
                [strComment appendString:@" created the meetup: "];
            else
                [strComment appendString:@" created the thread: "];
            [strComment appendString:meetup.strSubject];
            bSystem = true;
            break;
        case COMMENT_SAVED:
            [strComment appendString:[pCurrentUser objectForKey:@"fbName"]];
            if (meetup.meetupType == TYPE_MEETUP)
                [strComment appendString:@" changed meetup details."];
            else
                [strComment appendString:@" changed thread details."];
            bSystem = true;
            break;
        case COMMENT_JOINED:
            [strComment appendString:[pCurrentUser objectForKey:@"fbName"]];
            [strComment appendString:@" joined the event."];
            bSystem = true;
            break;
        case COMMENT_PLAIN:
            [strComment appendString:text];
            meetup.numComments++;
            [globalData updateConversation:nil count:meetup.numComments thread:meetup.strId];
            break;
    }
    
    if ( bSystem )
        [comment setObject:trueNum forKey:@"system"];
    [comment setObject:strCurrentUserId forKey:@"userId"];
    [comment setObject:strCurrentUserName forKey:@"userName"];
    [comment setObject:pCurrentUser forKey:@"userData"];
    [comment setObject:meetup.strSubject forKey:@"meetupSubject"];
    [comment setObject:meetup.strId forKey:@"meetupId"];
    if ( meetup.meetupData )
        [comment setObject:meetup.meetupData forKey:@"meetupData"];
    [comment setObject:strComment forKey:@"comment"];
    [comment setObject:typeNum forKey:@"type"];
    //comment.ACL = [PFACL ACLWithUser:[PFUser currentUser]];
    //[comment.ACL setPublicReadAccess:true];
    
    [comment saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        //PFObject* temp = meetup.meetupData;
        if ( error )
            NSLog(@"error:%@", error);
    }];
    
    // Add comment to the list of threads
    [self addComment:comment];
    
    // Subscription
    [globalData subscribeToThread:meetup.strId];
    
    // Send push if not system
    if ( ! bSystem )
        [pushManager sendPushCommentedMeetup:meetup.strId];
}


#pragma mark -
#pragma mark Misc


- (void) attendMeetup:(NSString*)strMeetup
{
    NSMutableArray* attending = [[PFUser currentUser] objectForKey:@"attending"];
    if ( ! attending )
        attending = [[NSMutableArray alloc] init];
    
    // Check if already attending
    for (NSString* str in attending)
        if ( [str compare:strMeetup] == NSOrderedSame )
            return;
    
    // Attend
    [attending addObject:strMeetup];
    [[PFUser currentUser] setObject:attending forKey:@"attending"];
    [[PFUser currentUser] saveInBackground];
    
    // Push notification to all attendees
    [pushManager sendPushAttendingMeetup:strMeetup];
}

- (void) unattendMeetup:(NSString*)strMeetup
{
    NSMutableArray* attending = [[PFUser currentUser] objectForKey:@"attending"];
    if ( ! attending )
        attending = [[NSMutableArray alloc] init];
    for (NSString* str in attending)
    {
        if ( [str compare:strMeetup] == NSOrderedSame )
        {
            [attending removeObject:str];
            break;
        }
    }
    [[PFUser currentUser] setObject:attending forKey:@"attending"];
    [[PFUser currentUser] saveInBackground]; // TODO: here was Eventually
}

- (Boolean) isAttendingMeetup:(NSString*)strMeetup
{
    NSMutableArray* attending = [[PFUser currentUser] objectForKey:@"attending"];
    if ( ! attending )
        return false;
    for (NSString* str in attending)
        if ( [str compare:strMeetup] == NSOrderedSame )
            return true;
    return false;
}

- (void) subscribeToThread:(NSString*)strThread
{
    NSMutableArray* subscriptions = [[PFUser currentUser] objectForKey:@"subscriptions"];
    if ( ! subscriptions )
        subscriptions = [[NSMutableArray alloc] init];
    
    // Check if already subscribed
    for (NSString* str in subscriptions)
        if ( [str compare:strThread] == NSOrderedSame )
            return;
    
    // Subscribe
    [subscriptions addObject:strThread];
    [[PFUser currentUser] setObject:subscriptions forKey:@"subscriptions"];
    [[PFUser currentUser] saveInBackground]; // TODO: here was Eventually
    
    // Pushes
    NSString* strChannel = [[NSString alloc] initWithFormat:@"mt%@", strThread];
    [pushManager addChannel:strChannel];
}

- (void) unsubscribeToThread:(NSString*)strThread
{
    NSMutableArray* subscriptions = [[PFUser currentUser] objectForKey:@"subscriptions"];
    if ( ! subscriptions )
        subscriptions = [[NSMutableArray alloc] init];
    for (NSString* str in subscriptions)
    {
        if ( [str compare:strThread] == NSOrderedSame )
        {
            [subscriptions removeObject:str];
            break;
        }
    }
    [[PFUser currentUser] setObject:subscriptions forKey:@"subscriptions"];
    [[PFUser currentUser] saveInBackground]; // TODO: here was Eventually
    
    // Pushes
    [pushManager removeChannel:strThread];
}

- (Boolean) isSubscribedToThread:(NSString *)strThread
{
    NSMutableArray* subscriptions = [[PFUser currentUser] objectForKey:@"subscriptions"];
    if ( ! subscriptions )
        return false;
    for (NSString* str in subscriptions)
        if ( [str compare:strThread] == NSOrderedSame )
            return true;
    return false;
}

- (void) addRecentInvites:(NSArray*)recentInvites
{
    [[PFUser currentUser] addUniqueObjectsFromArray:recentInvites forKey:@"recentInvites"];
    [[PFUser currentUser] saveInBackground]; // TODO: here was Eventually
}

- (void) addRecentVenue:(FSVenue*)recentVenue
{
    NSMutableArray* venues = [[PFUser currentUser] objectForKey:@"recentVenues"];
    if ( ! venues )
        venues = [[NSMutableArray alloc] init];
    
    // Check if already added
    for ( NSDictionary* venue in venues )
        if ([recentVenue.venueId compare:[venue objectForKey:@"id"]] == NSOrderedSame)
            return;
    
    if ( venues.count >= MAX_RECENT_VENUES_COUNT )
        [venues removeObjectAtIndex:0];
    
    [venues addObject:recentVenue.fsVenue];
    
    [[PFUser currentUser] setObject:venues forKey:@"recentVenues"];
    [[PFUser currentUser] saveInBackground]; // TODO: here was Eventually
}

- (NSArray*) getRecentPersons
{
    NSArray* arrayRecentsIds = [[PFUser currentUser] objectForKey:@"recentInvites"];
    return [globalData getPersonsByIds:arrayRecentsIds];
}

- (NSArray*) getRecentVenues
{
    NSArray *venuesDic = [[PFUser currentUser] objectForKey:@"recentVenues"];
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:venuesDic.count];
    for (NSDictionary *dic  in venuesDic) {
        FSVenue *venue = [[FSVenue alloc]initWithDictionary:dic];
        [result addObject:venue];
    }
    return result;
}

- (Boolean) isUserAdmin
{
    if ([[PFUser currentUser] objectForKey:@"admin"])
        return true;
    return false;
}

- (Boolean) setUserPosition:(PFGeoPoint*)geoPoint
{
    if ( [pCurrentUser isAuthenticated] && geoPoint )
    {
        // Setting own coords
        [pCurrentUser setObject:geoPoint forKey:@"location"];
        
        // Recalculating distances
        for ( Circle* circle in [circles allValues] )
            for ( Person* person in [circle getPersons] )
                 [person calculateDistance];
        
        return true;
    }
    return false;
}

- (void) removeUserFromNew:(NSString*)strUser
{
    [newFriendsFb removeObject:strUser];
    [newFriends2O removeObject:strUser];
}

- (void) incrementMapLoadingStage
{
    nMapLoadingStage++;
    
    if ( nMapLoadingStage == MAP_LOADED )
    {
        nLoadStatusMap = LOAD_OK;
        [[NSNotificationCenter defaultCenter]postNotificationName:kLoadingMapComplete
                                                           object:nil];
    }
}

- (void) incrementCirclesLoadingStage
{
    nCirclesLoadingStage++;
    
    if ( nCirclesLoadingStage == CIRCLES_LOADED )
    {
        nLoadStatusCircles = LOAD_OK;
        [[NSNotificationCenter defaultCenter]postNotificationName:kLoadingCirclesComplete
                                                           object:nil];
    }
}


@end