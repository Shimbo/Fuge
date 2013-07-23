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
#import "FacebookLoader.h"
#import "EventbriteLoader.h"

@implementation GlobalData

static GlobalData *sharedInstance = nil;
static FacebookLoader* FBloader = nil;
//static EventbriteLoader* EBloader = nil;

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
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"fullName CONTAINS[cd] %@",searchStr];
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
                                          NSDictionary<FBGraphUser> *user, NSError *error) {
        
        if ( error )
        {
            NSLog(@"Uh oh. An error occurred: %@", error);
            [self loadingFailed:LOADING_MAIN status:LOAD_NOFACEBOOK];
        }
        else
        {
            // Store the current user's Facebook ID on the user
            [pCurrentUser setObject:user.id forKey:@"fbId"];
            if ( user.first_name )
                [pCurrentUser setObject:user.first_name forKey:@"fbNameFirst"];
            if ( user.last_name )
                [pCurrentUser setObject:user.last_name forKey:@"fbNameLast"];
            if ( user.birthday )
                [pCurrentUser setObject:user.birthday forKey:@"fbBirthday"];
            if ( [user objectForKey:@"gender"] )
                [pCurrentUser setObject:[user objectForKey:@"gender"]
                                     forKey:@"fbGender"];
            if ( [user objectForKey:@"email"] )
                pCurrentUser.email = [user objectForKey:@"email"];
            [pCurrentUser setObject:[globalVariables currentVersion]
                                     forKey:@"version"];
            if ( ! [pCurrentUser objectForKey:@"profileDiscoverable"] )
                [pCurrentUser setObject:[NSNumber numberWithBool:TRUE] forKey:@"profileDiscoverable"];
            
            // Looking for job data
            NSArray* work = [user objectForKey:@"work"];
            if ( work && work.count > 0 )
            {
                NSDictionary* current = work[0];
                if ( current )
                {
                    NSDictionary* employer = [current objectForKey:@"employer"];
                    NSString* strEmployer = @"";
                    NSString* strPosition = @"";
                    if ( employer && [employer objectForKey:@"name"] )
                        strEmployer = [employer objectForKey:@"name"];
                    NSDictionary* position = [current objectForKey:@"position"];
                    if ( position && [position objectForKey:@"name"] )
                        strPosition = [position objectForKey:@"name"];
                    [pCurrentUser setObject:strEmployer forKey:@"profileEmployer"];
                    [pCurrentUser setObject:strPosition forKey:@"profilePosition"];
                }
            }
            
            // Loading likes
            if ( !FBloader )
                FBloader = [[FacebookLoader alloc] init];
            [FBloader loadLikes:self selector:@selector(fbLikesCallback:)];
            
            [pCurrentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                
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
                    [pushManager initChannelsForTheFirstTime:user.id];
                    
                    // FB friends, 2O friends, fb friends not installed the app
                    [self reloadFriendsInBackground];
                    
                    // Map data: random people, meetups, threads, etc - location based
                    [self reloadMapInfoInBackground:nil toNorthEast:nil];
                    
                    // FB Meetups
                    [self loadFBMeetups];
                    
                    // EB Meetups
                    [self loadEBMeetups];
                    
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


- (Person*)addPerson:(PFUser*)user userCircle:(NSUInteger)circleUser
{
    NSString *strId = [user objectForKey:@"fbId"];
    
    // Same user
    if ( [strId compare:[ [PFUser currentUser] objectForKey:@"fbId"] ] == NSOrderedSame )
        return nil;
    
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
        // Updating location and status
        [person updateLocation:[user objectForKey:@"location"]];
        person.strStatus = [user objectForKey:@"profileStatus"];
        return person;
    }
    
    // Adding new person
    person = [[Person alloc] init:user circle:circleUser];
    Circle *circle = [globalData getCircle:circleUser];
    [circle addPerson:person];
    
    return person;
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
    friendQuery.limit = 1000;
    [friendQuery orderByDescending:@"updatedAt"];
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
            }
            // Notification for that user if the friend is new
            [pushManager sendPushNewUser:PUSH_NEW_FBFRIEND idsTo:[friendUsers valueForKeyPath:@"fbId"]];
            
            // Sorting FB friends
            Circle* circleFB = [self getCircle:CIRCLE_FB];
            if ( circleFB )
                [circleFB sort];
            
            // Excluding FB friends and user himself from 2O friends
            NSMutableArray* temp2O = [[PFUser currentUser] objectForKey:@"fbFriends2O"];
            if ( temp2O )
            {
                [temp2O removeObjectsInArray:friendIds];
                [temp2O removeObject:strCurrentUserId];
            }
            else
                temp2O = [[NSMutableArray alloc] initWithCapacity:30];
            [[PFUser currentUser] setObject:temp2O forKey:@"fbFriends2O"];
            
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
            
            // Admin role creation, DEV CODE, don't uncomment!
            /*PFACL* adminACL = [PFACL ACLWithUser:pCurrentUser];
            [adminACL setReadAccess:TRUE forUserId:@"n6cZJLJJnW"];
            [adminACL setWriteAccess:TRUE forUserId:@"n6cZJLJJnW"];
            PFRole* role = [PFRole roleWithName:@"Admin" acl:adminACL];
            [role.users addObject:pCurrentUser];
            [role.users addObject:[self getPersonById:@"1377492801"].personData];
            [role save];*/
            
            /*PFACL* moderatorACL = [PFACL ACLWithUser:pCurrentUser];
            [moderatorACL setReadAccess:TRUE forUserId:@"n6cZJLJJnW"];
            [moderatorACL setWriteAccess:TRUE forUserId:@"n6cZJLJJnW"];
            PFRole* role = [PFRole roleWithName:@"Moderator" acl:moderatorACL];
            [role.users addObject:pCurrentUser];
            [role.users addObject:[self getPersonById:@"1377492801"].personData];
            [role.users addObject:[self getPersonById:@"1302078057"].personData];
            [role save];*/
        }
    }];
}

- (void) load2OFriendsInBackground:(id)friends
{
    // Second circle friends query
    NSMutableArray *friend2OIds = [[PFUser currentUser] objectForKey:@"fbFriends2O"];
    PFQuery *friend2OQuery = [PFUser query];
    if ( [globalVariables isUserAdmin] )
        friend2OQuery.limit = 1000;
    else
        friend2OQuery.limit = SECOND_PERSON_MAX_COUNT;
    [friend2OQuery orderByDescending:@"updatedAt"];
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
                [self addPerson:friend2OUser userCircle:CIRCLE_2O];
            
            // Notification for that user if the friend is new
            [pushManager sendPushNewUser:PUSH_NEW_2OFRIEND idsTo:[friend2OUsers valueForKeyPath:@"fbId"]];
            
            // Sorting 2O friends
            Circle* circle2O = [self getCircle:CIRCLE_2O];
            if ( circle2O )
                [circle2O sort];
            
            // Pushes sent for all new users, turn it off
            [globalVariables pushToFriendsSent];
            
            // Save user data as it's useful for other users to find 2O friends
            [[PFUser currentUser] saveInBackground]; // CHECK: here was Eventually - ?
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
    if ( [globalVariables isUserAdmin] )
        friendAnyQuery.limit = 1000;
    else
        friendAnyQuery.limit = RANDOM_PERSON_MAX_COUNT;
    [friendAnyQuery orderByDescending:@"updatedAt"];
    
    // We could load based on player location or map rect if he moved the map later
    if ( ! southWest )
    {
        NSUInteger nDistance = [globalVariables isUserAdmin] ? RANDOM_PERSON_KILOMETERS_ADMIN : RANDOM_PERSON_KILOMETERS_NORMAL;
        [friendAnyQuery whereKey:@"location" nearGeoPoint:[globalVariables currentLocation] withinKilometers:nDistance];
    }
    else
    {
        [friendAnyQuery whereKey:@"location" withinGeoBoxFromSouthwest:southWest toNortheast:northEast];
    }
    [friendAnyQuery whereKey:@"profileDiscoverable" notEqualTo:[[NSNumber alloc] initWithBool:FALSE]];
    NSDate* dateToHide = [NSDate dateWithTimeIntervalSinceNow:-(NSTimeInterval)MAX_SECONDS_FROM_PERSON_LOGIN];
    [friendAnyQuery whereKey:@"updatedAt" greaterThan:dateToHide];
    
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
            Circle* circleRandom = [self getCircle:CIRCLE_RANDOM];
            if ( circleRandom )
                [circleRandom sort];
        }
        
        // In any case, increment loading stage
        [self incrementMapLoadingStage];
    }];
}

- (void) loadFbOthers:(id)friends
{
    NSMutableArray *friendIds = [[[PFUser currentUser] objectForKey:@"fbFriends"] mutableCopy];
    
    Circle *fbCircle = [self getCircle:CIRCLE_FBOTHERS];
    
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
                person.strFirstName = [friendObject objectForKey:@"name"];
                person.strId = strId;
                [fbCircle addPerson:person];
            }
        }
    }
    
    // Sorting 2O friends
    if ( fbCircle )
        [fbCircle sort];
}


#pragma mark -
#pragma mark Meetups


// This one is used by new meetup window
- (void)addMeetup:(Meetup*)meetup
{
    if ( ! meetup )
        return;
    
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
    
    // private meetups additional check
    if ( meetup.privacy == MEETUP_PRIVATE )
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

- (void)fbMeetupsCallback:(NSArray*)events
{
    [self incrementMapLoadingStage];

    if ( ! events )
        return;
    
    for ( NSDictionary* event in events )
    {
        Meetup* meetup = [[Meetup alloc] initWithFbEvent:event];
        [self addMeetup:meetup];
    }
}

- (void)fbLikesCallback:(NSArray*)likes
{
    if ( likes )
    {
        [pCurrentUser setObject:likes forKey:@"fbLikes"];
        [pCurrentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if ( error )
                NSLog(@"Error: %@", error);
        }];
    }
}

- (void)loadFBMeetups
{
    if ( bIsAdmin )
    {
        FBloader = [[FacebookLoader alloc] init];
        [FBloader loadMeetups:self selector:@selector(fbMeetupsCallback:)];
    }
    else
        [self incrementMapLoadingStage];
}

- (void)ebMeetupsCallback:(NSArray*)events
{
    [self incrementMapLoadingStage];
    
    if ( ! events )
        return;
    
    for ( NSDictionary* event in events )
    {
        Meetup* meetup = [[Meetup alloc] initWithEbEvent:event];
        [self addMeetup:meetup];
    }
}

- (void)loadEBMeetups
{
    /*if ( bIsAdmin )
    {
        EBloader = [[EventbriteLoader alloc] init];
        [EBloader loadData:self selector:@selector(ebMeetupsCallback:)];
    }
    else*/
        [self incrementMapLoadingStage];
}

- (void)loadMeetupsInBackground:(PFGeoPoint*)southWest toNorthEast:(PFGeoPoint*)northEast
{
    PFQuery *meetupAnyQuery = [PFQuery queryWithClassName:@"Meetup"];
    if ( [globalVariables isUserAdmin] )
        meetupAnyQuery.limit = 1000;
    else
        meetupAnyQuery.limit = 100;
    
    // Location filter
    if ( ! southWest )
    {
        PFGeoPoint* ptUser = [[PFUser currentUser] objectForKey:@"location"];
        if ( ! ptUser )
            ptUser = [locManager getDefaultPosition];
        
        NSUInteger nDistance = [globalVariables isUserAdmin] ? RANDOM_EVENT_KILOMETERS_ADMIN : RANDOM_EVENT_KILOMETERS_NORMAL;
        [meetupAnyQuery whereKey:@"location" nearGeoPoint:ptUser withinKilometers:nDistance];
    }
    else
    {
        [meetupAnyQuery whereKey:@"location" withinGeoBoxFromSouthwest:southWest toNortheast:northEast];
    }
    
    // Expired meetups
    NSDate* dateLate = [NSDate date];
    [meetupAnyQuery whereKey:@"meetupDateExp" greaterThan:dateLate];
    [meetupAnyQuery whereKey:@"canceled" notEqualTo:[NSNumber numberWithBool:TRUE]];
    
    // Meetups too far in the future
    NSDateComponents* deltaCompsMax = [[NSDateComponents alloc] init];
    [deltaCompsMax setDay:MAX_DAYS_TILL_MEETUP];
    NSDate* dateEarly = [[NSCalendar currentCalendar] dateByAddingComponents:deltaCompsMax toDate:[NSDate date] options:0];
    [meetupAnyQuery whereKey:@"meetupDate" lessThan:dateEarly];
    
    // Privacy filter
    NSNumber* privacyTypePrivate = [[NSNumber alloc] initWithInt:MEETUP_PRIVATE];
    [meetupAnyQuery whereKey:@"privacy" notEqualTo:privacyTypePrivate];
    
    // Ascending order by expiration date (to get most earliest meetups)
    [meetupAnyQuery orderByAscending:@"meetupDate"];
    
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
    
    // Query for events that user was subscribed to (to show also private and remote events/threads) - this query calls only for first request, not for the map reloads. Plus all invites!
    NSMutableArray* subscriptions = [pCurrentUser objectForKey:@"subscriptions"];
    if ( ! subscriptions )
        subscriptions = [[NSMutableArray alloc] initWithCapacity:30];
    for ( PFObject* invite in invites )
    {
        NSString* strId = [invite objectForKey:@"meetupId"];
        if ( strId )
            [subscriptions addObject:strId];
    }
    if ( subscriptions.count > 0 )
    {
        meetupAnyQuery = [PFQuery queryWithClassName:@"Meetup"];
        meetupAnyQuery.limit = 1000;
        [meetupAnyQuery orderByAscending:@"meetupDate"];
        [meetupAnyQuery whereKey:@"meetupDateExp" greaterThan:dateLate];
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
//                NSMutableArray* newSubscriptions = [[NSMutableArray alloc] initWithCapacity:meetupsData.count];
                for (PFObject *meetupData in meetupsData)
                {
                    /*Meetup* result =*/ [self addMeetupWithData:meetupData];
/*                    NSString* strMeetupId = [meetupData objectForKey:@"meetupId"];
                    if ( ! result )
                        [self unsubscribeToThread:strMeetupId];
                    else
                        [newSubscriptions addObject:strMeetupId];*/
                }
//                [[PFUser currentUser] setObject:newSubscriptions forKey:@"subscriptions"];
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

- (void)createInvite:(Meetup*)meetup stringTo:(NSString*)strRecipient
{
    Person* recipient = [self getPersonById:strRecipient];
    
    PFObject* invite = [PFObject objectWithClassName:@"Invite"];
    
    // Id, fromStr, fromId
    [invite setObject:meetup.strId forKey:@"meetupId"];
    [invite setObject:meetup.meetupData forKey:@"meetupData"];
    [invite setObject:[meetup.dateTime dateByAddingTimeInterval:meetup.durationSeconds] forKey:@"expirationDate"];
    [invite setObject:[NSNumber numberWithInt:meetup.meetupType] forKey:@"type"];
    [invite setObject:meetup.strSubject forKey:@"meetupSubject"];
    
    [invite setObject:strCurrentUserId forKey:@"idUserFrom"];
    [invite setObject:[globalVariables fullUserName] forKey:@"nameUserFrom"];
    [invite setObject:[PFUser currentUser] forKey:@"objUserFrom"];
    [invite setObject:strRecipient forKey:@"idUserTo"];
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
        {
            UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"No connection" message:@"One of the recent invites was not sent, check your internet connection or try again later." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [errorAlert show];
        }
        else
            [pushManager sendPushInviteForMeetup:meetup.strId user:strRecipient];
    }];
}


#pragma mark -
#pragma mark Misc


- (void) attendMeetup:(Meetup*)meetup
{
    // Check if already attending
    NSMutableArray* attending = [pCurrentUser objectForKey:@"attending"];
    if ( attending )
        for (NSString* str in attending)
            if ( [str compare:meetup.strId] == NSOrderedSame )
                return;
    
    // Update invite
    [globalData updateInvite:meetup.strId attending:INVITE_ACCEPTED];
    
    // Attending list in user itself
    [pCurrentUser addUniqueObject:meetup.strId forKey:@"attending"];
    [pCurrentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if ( error )
            NSLog(@"Error: %@", error);
    }];
    
    // Attendee in db (to store the data and update counters)
    PFObject* attendee = [PFObject objectWithClassName:@"Attendee"];
    [attendee setObject:strCurrentUserId forKey:@"userId"];
    [attendee setObject:[globalVariables fullUserName] forKey:@"userName"];
    [attendee setObject:pCurrentUser forKey:@"userData"];
    [attendee setObject:meetup.strId forKey:@"meetupId"];
    [attendee setObject:meetup.strSubject forKey:@"meetupSubject"];
    [attendee setObject:meetup.meetupData forKey:@"meetupData"];
    [attendee saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if ( error )
            NSLog(@"Error: %@", error);
    }];
    
    // Creating comment about joining in db
    [globalData createCommentForMeetup:meetup commentType:COMMENT_JOINED commentText:nil];
    
    // Push notification to all attendees
    [pushManager sendPushAttendingMeetup:meetup.strId];
    
    // Adding attendee to the local copy of the meetup
    [meetup addAttendee:strCurrentUserId];
}

- (void) unattendMeetup:(Meetup*)meetup
{
    // Remove from attending list and add to left list in user
    [pCurrentUser removeObject:meetup.strId forKey:@"attending"];
    [pCurrentUser addUniqueObject:meetup.strId forKey:@"meetupsLeft"];
    [pCurrentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if ( error )
            NSLog(@"Error: %@", error);
    }];
    
    // Attendee in db (to store the data and update counters)
    PFObject* attendee = [PFObject objectWithClassName:@"Attendee"];
    [attendee setObject:strCurrentUserId forKey:@"userId"];
    [attendee setObject:[globalVariables fullUserName] forKey:@"userName"];
    [attendee setObject:pCurrentUser forKey:@"userData"];
    [attendee setObject:meetup.strId forKey:@"meetupId"];
    [attendee setObject:meetup.strSubject forKey:@"meetupSubject"];
    [attendee setObject:meetup.meetupData forKey:@"meetupData"];
    [attendee setObject:[NSNumber numberWithBool:TRUE] forKey:@"leaving"];
    [attendee saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if ( error )
            NSLog(@"Error: %@", error);
    }];
    
    // Creating comment about leaving in db
    [globalData createCommentForMeetup:meetup commentType:COMMENT_LEFT commentText:nil];
    
    // Push notification to all attendees
    [pushManager sendPushLeftMeetup:meetup.strId];
    
    // Removing attendee to the local copy of meetup
    [meetup removeAttendee:strCurrentUserId];
}

- (void) cancelMeetup:(Meetup*)meetup
{
    // Saving meetup
    [meetup setCanceled];
    [meetup save];
    
    // Creating comment about canceling
    [globalData createCommentForMeetup:meetup commentType:COMMENT_CANCELED commentText:nil];
    
    // Push notification to all attendees
    [pushManager sendPushCanceledMeetup:meetup.strId];

}

- (Boolean) isAttendingMeetup:(NSString*)strMeetup
{
    NSMutableArray* attending = [pCurrentUser objectForKey:@"attending"];
    if ( ! attending )
        return false;
    for (NSString* str in attending)
        if ( [str compare:strMeetup] == NSOrderedSame )
            return true;
    return false;
}

- (Boolean) hasLeftMeetup:(NSString*)strMeetup
{
    NSMutableArray* meetupsLeft = [pCurrentUser objectForKey:@"meetupsLeft"];
    if ( ! meetupsLeft )
        return false;
    for (NSString* str in meetupsLeft)
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
    [[PFUser currentUser] saveInBackground]; // CHECK: here was Eventually
    
    // Pushes
    //NSString* strChannel = [[NSString alloc] initWithFormat:@"mt%@", strThread];
    //[pushManager addChannel:strChannel];
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
    [[PFUser currentUser] saveInBackground]; // CHECK: here was Eventually
    
    // Pushes
    //[pushManager removeChannels:[strThread];
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
    [[PFUser currentUser] saveInBackground]; // CHECK: here was Eventually
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
    [[PFUser currentUser] saveInBackground]; // CHECK: here was Eventually
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

/*- (void) addPersonToSeenList:(NSString*)strId
{
    NSMutableArray* arraySeenList = [pCurrentUser objectForKey:@"seenPersons"];
    if ( ! arraySeenList )
        arraySeenList = [[NSMutableArray alloc] initWithObjects:strId,nil];
    else
        [arraySeenList addObject:strId];
    [pCurrentUser setObject:arraySeenList forKey:@"seenPersons"];
    [pCurrentUser saveInBackground];
    return;
}

- (Boolean) isPersonSeen:(NSString*)strId
{
    NSMutableArray* arraySeenList = [pCurrentUser objectForKey:@"seenPersons"];
    if ( arraySeenList )
        if ( [arraySeenList containsObject:strId] ) // NOT TESTED
            return true;
    return false;
}*/



- (Boolean) setUserPosition:(PFGeoPoint*)geoPoint
{
    if ( geoPoint )
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
