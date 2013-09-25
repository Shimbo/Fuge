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

#import "ULEventManager.h"
#import "FUGEvent.h"

@implementation GlobalData

static GlobalData *sharedInstance = nil;
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
        firstDataLoad = true;
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
#ifdef TARGET_S2C
        if ( circle != CIRCLE_FBOTHERS )
#endif
        {
            [circles setObject:result forKey:[Circle getCircleName:circle]];
            _circleByNumber[@(result.idCircle-1)] = result;
        }
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
    if ( [strFbIds containsObject:strCurrentUserId] )
        [result addObject:currentPerson];
    return result;
}

- (Person*) getPersonById:(NSString*)strFbId
{
    if ( [strFbId compare:strCurrentUserId] == NSOrderedSame )
        return currentPerson;
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
    
#ifdef TARGET_FUGE
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
            // Facebook personal data and likes
            [fbLoader loadUserData:user];
            [fbLoader loadLikes:self selector:@selector(fbLikesCallback:)];
#elif defined TARGET_S2C
            
#endif
            
            // General data
            [pCurrentUser setObject:[globalVariables currentVersion]
                                     forKey:@"version"];
            if ( ! [pCurrentUser objectForKey:@"profileDiscoverable"] )
                [pCurrentUser setObject:[NSNumber numberWithBool:TRUE] forKey:@"profileDiscoverable"];
            
            // Saving user and following the next steps
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
                    [pushManager initChannels];

#ifdef TARGET_S2C
                    // FB friends, 2O friends, fb friends not installed the app
                    [self reloadFriendsInBackground];
#elif defined TARGET_FUGE
                    // Map data: random people, meetups, threads, etc - location based
                    [self reloadMapInfoInBackground:nil toNorthEast:nil];
#endif
                    
                    
#ifdef TARGET_FUGE
                    // FB Meetups
                    //[self loadFBMeetups];
                    
                    // EB Meetups
                    //[self loadEBMeetups];
#endif
                    
                    // Admin reload of groups and events recreation
                    //if ( bIsAdmin )
                    //    [self reloadGroupsAndCreateEventsInBackground];
                }
            }];
#ifdef TARGET_FUGE
        }
    }];
#endif
}

- (void) loadFriendsInBackgroundFailed
{
    [self loadingFailed:LOADING_CIRCLES status:LOAD_NOFACEBOOK];
}

// Will not use any load status, on fail just nothing
- (void)reloadFriendsInBackground//:(Boolean)loadRandom
{
    nCirclesLoadingStage = 0;
    nLoadStatusCircles = LOAD_STARTED;
    
    // Random people
    //if ( loadRandom )
        [self loadRandomPeopleInBackground];
    //else
    //    [self incrementCirclesLoadingStage];
}

// Will use secondary load status to show problems with connection
- (void)reloadMapInfoInBackground:(PFGeoPoint*)southWest toNorthEast:(PFGeoPoint*)northEast
{
    nMapLoadingStage = 0;
    nLoadStatusMap = LOAD_STARTED;
    
    // Meetups
    [self loadMeetupsInBackground:southWest toNorthEast:northEast];
}


#pragma mark -
#pragma mark People


- (Person*)addPerson:(PFUser*)user userCircle:(NSUInteger)circleUser
{
    NSString *strId = [user objectForKey:@"fbId"];
    
    // Same user
    if ( [strId compare:[ [PFUser currentUser] objectForKey:@"fbId"] ] == NSOrderedSame )
        return nil;
    
    // Already added users: update
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
        [person update:user];
        return person;
    }
    
    // Adding new person
    person = [[Person alloc] init:user circle:circleUser];
    Circle *circle = [globalData getCircle:circleUser];
    [circle addPerson:person];
    
    return person;
}

// Load friends in background
- (void) loadFbFriendsInBackground:(NSArray*)friends
{
    // Storing old friends lists (to calculate new friends later in this call)
    NSArray* oldFriendsFb = [[pCurrentUser objectForKey:@"fbFriends"] copy];
    oldFriends2O = [[pCurrentUser objectForKey:@"fbFriends2O"] copy];
    
    // Saving user FB friends
    NSMutableArray* friendIds;
    if ( friends )
    {
        friendIds = [NSMutableArray arrayWithCapacity:friends.count];
        for (NSDictionary *friendObject in friends)
        {
            NSString* strIdFb = [friendObject objectForKey:@"id"];
            [friendIds addObject:strIdFb];
        }
        [pCurrentUser addUniqueObjectsFromArray:friendIds forKey:@"fbFriends"];
    }
    else
        friendIds = [pCurrentUser objectForKey:@"fbFriends"];
    if ( ! friendIds || friendIds.count == 0 )
    {
        //[self incrementCirclesLoadingStage];
        return;
    }
    
    // FB friends query
    PFQuery *friendQuery = [PFUser query];
    friendQuery.limit = 30;
    [friendQuery orderByDescending:@"updatedAt"];
    [friendQuery whereKey:@"fbId" containedIn:friendIds];
    [friendQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
    {
        NSArray *friendUsers = objects;
        
        if ( error )
        {
            NSLog(@"Parse query for friends load error: %@", error);
            [self loadingFailed:LOADING_CIRCLES status:LOAD_NOCONNECTION];
        }
        else
        {
            newFriends2O = [NSMutableArray arrayWithCapacity:5];    // 5000
            
            // Data collection
            for (PFUser *friendUser in friendUsers)
            {
                // Collecting second circle data
                /*NSMutableArray *friendFriendIds = [friendUser objectForKey:@"fbFriends"];
                
                //[pCurrentUser addUniqueObjectsFromArray:friendFriendIds forKey:@"fbFriends2O"];
                for ( NSString* friendId in friendFriendIds )
                    if ( ! [newFriends2O containsObject:friendId] )
                        [newFriends2O addObject:friendId];*/
                
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
            //NSMutableArray* temp2O = [[PFUser currentUser] objectForKey:@"fbFriends2O"];
            //if ( temp2O )
            //{
                //[temp2O removeObjectsInArray:friendIds];
                //[temp2O removeObject:strCurrentUserId];
            [newFriends2O removeObjectsInArray:friendIds];
            [newFriends2O removeObject:strCurrentUserId];
            //}
            //else
            //    temp2O = [[NSMutableArray alloc] initWithCapacity:30];
            //[[PFUser currentUser] setObject:temp2O forKey:@"fbFriends2O"];
            
            // Creating new friends list
            if ( oldFriendsFb )
            {
                newFriendsFb = [[pCurrentUser objectForKey:@"fbFriends"] mutableCopy];
                //newFriends2O = [[[PFUser currentUser] objectForKey:@"fbFriends2O"] mutableCopy];
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
            [pCurrentUser saveInBackground]; // CHECK: here was Eventually - ?
            
            // FB friends out of the app
            [self loadFbOthers:friends];
            
            // Notification
            [[NSNotificationCenter defaultCenter]postNotificationName:kLoadingFriendsComplete
                                                               object:nil];
            
            // Admin role creation, DEV CODE, don't uncomment!

#ifdef TARGET_FUGE
            
            // Adding people without recreating the role, TO TEST!
            /*PFRole* role = [PFRole roleWithName:@"Moderator"];
             [role fetch];
             [role.users addObject:[self getPersonById:@"1377492801"].personData];
             [role save];*/
            
            /*PFACL* adminACL = [PFACL ACLWithUser:pCurrentUser];
            [adminACL setReadAccess:TRUE forUserId:FEEDBACK_BOT_OBJECT];
            [adminACL setWriteAccess:TRUE forUserId:FEEDBACK_BOT_OBJECT];
            PFRole* role = [PFRole roleWithName:@"Admin" acl:adminACL];
            [role.users addObject:pCurrentUser];
            [role.users addObject:[self getPersonById:@"1377492801"].personData];
            [role save];*/
            
            /*PFACL* moderatorACL = [PFACL ACLWithUser:pCurrentUser];
            [moderatorACL setReadAccess:TRUE forUserId:FEEDBACK_BOT_OBJECT];
            [moderatorACL setWriteAccess:TRUE forUserId:FEEDBACK_BOT_OBJECT];
            PFRole* role = [PFRole roleWithName:@"Moderator" acl:moderatorACL];
            [role.users addObject:pCurrentUser];
            [role.users addObject:[self getPersonById:@"1377492801"].personData];
            [role.users addObject:[self getPersonById:@"1302078057"].personData];
            [role save];*/
            
#elif defined TARGET_S2C
            
            /*PFACL* adminACL = [PFACL ACLWithUser:pCurrentUser];
            [adminACL setReadAccess:TRUE forUserId:FEEDBACK_BOT_OBJECT];
            [adminACL setWriteAccess:TRUE forUserId:FEEDBACK_BOT_OBJECT];
            PFRole* role = [PFRole roleWithName:@"Admin" acl:adminACL];
            [role.users addObject:pCurrentUser];
            if ( [self getPersonById:@"gehOLBFC2C"] )
                [role.users addObject:[self getPersonById:@"gehOLBFC2C"].personData];
            [role save];
            
            PFACL* moderatorACL = [PFACL ACLWithUser:pCurrentUser];
            [moderatorACL setReadAccess:TRUE forUserId:FEEDBACK_BOT_OBJECT];
            [moderatorACL setWriteAccess:TRUE forUserId:FEEDBACK_BOT_OBJECT];
            role = [PFRole roleWithName:@"Moderator" acl:moderatorACL];
            [role.users addObject:pCurrentUser];
            if ( [self getPersonById:@"gehOLBFC2C"] )
                [role.users addObject:[self getPersonById:@"gehOLBFC2C"].personData];
            [role.users addObject:[self getPersonById:@"GL6l5UrcmK"].personData];
            [role save];*/
#endif
        }
    }];
}

/*    // Second circle friends query
    //NSMutableArray *friend2OIds = [[PFUser currentUser] objectForKey:@"fbFriends2O"];
    PFQuery *friend2OQuery = [PFUser query];
    if ( [globalVariables isUserAdmin] )
        friend2OQuery.limit = 1000;
    else
        friend2OQuery.limit = SECOND_PERSON_MAX_COUNT;
    [friend2OQuery orderByDescending:@"updatedAt"];
    [friend2OQuery whereKey:@"fbId" containedIn:friend2OIds];
    if ( ! [globalVariables isUserAdmin] )
        [friend2OQuery whereKey:@"profileDiscoverable" notEqualTo:[[NSNumber alloc] initWithBool:FALSE]];
    NSDate* dateToHide = [NSDate dateWithTimeIntervalSinceNow:-(NSTimeInterval)MAX_SECONDS_FROM_PERSON_LOGIN];
    [friend2OQuery whereKey:@"updatedAt" greaterThan:dateToHide];
    [friend2OQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        if ( error )
        {
            NSLog(@"Parse query for 2O friends error: %@", error);
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
}*/

static NSUInteger resultsTotal = 0;

- (NSArray*) getAllPersonIds
{
    NSMutableArray* result = [NSMutableArray arrayWithCapacity:100];
    for ( Circle* circle in [circles allValues] )
        for (Person* person in [circle getPersons])
            [result addObject:person.strId];
    [result addObject:strCurrentUserId];
    return result;
}

- (void) loadRandomPeopleInBackground
{
    // Query
    PFQuery *friendAnyQuery = [PFUser query];
    //if ( [globalVariables isUserAdmin] )
    //    friendAnyQuery.limit = 1000;
    //else
    friendAnyQuery.limit = RANDOM_PERSON_MAX_COUNT;
    
    
    // We could load based on player location or map rect if he moved the map later
//    if ( ! southWest )
//    {
        //NSUInteger nDistance = RANDOM_PERSON_KILOMETERS;
        [friendAnyQuery whereKey:@"location" nearGeoPoint:[globalVariables currentLocation] withinKilometers:PERSON_HERE_DISTANCE/1000];
        //[friendAnyQuery whereKey:@"location" nearGeoPoint:[globalVariables currentLocation]];
//    }
//    else
//    {
//        [friendAnyQuery whereKey:@"location" withinGeoBoxFromSouthwest:southWest toNortheast:northEast];
//    }
    if ( ! [globalVariables isUserAdmin] )
        [friendAnyQuery whereKey:@"profileDiscoverable" notEqualTo:[[NSNumber alloc] initWithBool:FALSE]];
    //NSDate* dateToHide = [NSDate dateWithTimeIntervalSinceNow:-(NSTimeInterval)MAX_SECONDS_FROM_PERSON_LOGIN];
    //[friendAnyQuery whereKey:@"updatedAt" greaterThan:dateToHide];
    NSDate* dateToHide = [NSDate dateWithTimeIntervalSinceNow:-(NSTimeInterval)21600];
    [friendAnyQuery whereKey:@"updatedAt" greaterThan:dateToHide];
    [friendAnyQuery orderByDescending:@"updatedAt"];
    
    //NSMutableArray *loadedIds = [pCurrentUser objectForKey:@"fbFriends2O"];
    //if ( loadedIds && [pCurrentUser objectForKey:@"fbFriends2O"] )
    //    [loadedIds addObjectsFromArray:[pCurrentUser objectForKey:@"fbFriends2O"]];
    //if ( loadedIds )
    //    [friendAnyQuery whereKey:@"fbId" notContainedIn:loadedIds];
    
    // Actual load
    [friendAnyQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        if ( error )
        {
            NSLog(@"Parse query for random people error: %@", error);
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
            
            resultsTotal = objects.count;
            if ( resultsTotal < RANDOM_PERSON_MAX_COUNT )
            {
                PFQuery *friendAnyQuery2 = [PFUser query];
                friendAnyQuery2.limit = RANDOM_PERSON_MAX_COUNT - resultsTotal;
                if ( ! [globalVariables isUserAdmin] )
                    [friendAnyQuery2 whereKey:@"profileDiscoverable" notEqualTo:[[NSNumber alloc] initWithBool:FALSE]];
                NSDate* dateToHide = [NSDate dateWithTimeIntervalSinceNow:-(NSTimeInterval)86400];
                [friendAnyQuery2 whereKey:@"updatedAt" greaterThan:dateToHide];
                [friendAnyQuery2 whereKey:@"location" nearGeoPoint:[globalVariables currentLocation] withinKilometers:PERSON_NEARBY_DISTANCE/1000];
                NSArray* personIds = [self getAllPersonIds];
                if ( personIds.count > 0 )
                    [friendAnyQuery2 whereKey:@"fbId" notContainedIn:personIds];
                [friendAnyQuery2 orderByDescending:@"updatedAt"];
                [friendAnyQuery2 findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                    
                    if ( ! error )
                    {
                        NSArray *friendAnyUsers = objects;
                        
                        // Adding users
                        for (PFUser *friendAnyUser in friendAnyUsers)
                            [self addPerson:friendAnyUser userCircle:CIRCLE_RANDOM];
                        
                        // Sorting random people
                        Circle* circleRandom = [self getCircle:CIRCLE_RANDOM];
                        if ( circleRandom )
                            [circleRandom sort];
                        
                        resultsTotal += objects.count;
                        
                        // Refresh list
                        if ( resultsTotal > 10 )
                            [[NSNotificationCenter defaultCenter]postNotificationName:kLoadingEncountersComplete
                                                                           object:nil];
                        
                        // Load direct connections
#ifdef TARGET_FUGE
                        [fbLoader loadFriends:self selectorSuccess:@selector(loadFbFriendsInBackground:) selectorFailure:@selector(loadFriendsInBackgroundFailed)];
#elif defined TARGET_S2C
                        [self loadFbFriendsInBackground:nil];
#endif
                        
                        // Third load
                        if ( resultsTotal < RANDOM_PERSON_MAX_COUNT )
                        {
                            PFQuery *friendAnyQuery3 = [PFUser query];
                            friendAnyQuery3.limit = RANDOM_PERSON_MAX_COUNT - resultsTotal;
                            if ( ! [globalVariables isUserAdmin] )
                                [friendAnyQuery3 whereKey:@"profileDiscoverable" notEqualTo:[[NSNumber alloc] initWithBool:FALSE]];
                            NSDate* dateToHide = [NSDate dateWithTimeIntervalSinceNow:-(NSTimeInterval)MAX_SECONDS_FROM_PERSON_LOGIN];
                            [friendAnyQuery3 whereKey:@"updatedAt" greaterThan:dateToHide];
                            [friendAnyQuery3 whereKey:@"location" nearGeoPoint:[globalVariables currentLocation] withinKilometers:PERSON_RECENT_DISTANCE];
                            NSArray* personIds = [self getAllPersonIds];
                            if ( personIds.count > 0 )
                                [friendAnyQuery3 whereKey:@"fbId" notContainedIn:personIds];
                            [friendAnyQuery3 orderByDescending:@"updatedAt"];
                            [friendAnyQuery3 findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                                
                                if ( ! error )
                                {
                                    NSArray *friendAnyUsers = objects;
                                    
                                    // Adding users
                                    for (PFUser *friendAnyUser in friendAnyUsers)
                                        [self addPerson:friendAnyUser userCircle:CIRCLE_RANDOM];
                                    
                                    // Sorting random people
                                    Circle* circleRandom = [self getCircle:CIRCLE_RANDOM];
                                    if ( circleRandom )
                                        [circleRandom sort];
                                    
                                    // Show data
                                    [self incrementCirclesLoadingStage];
                                }
                                else
                                    [self loadingFailed:LOADING_MAP status:LOAD_NOCONNECTION];
                            }];
                        }
                        else
                            [self incrementCirclesLoadingStage];
                    }
                    else
                        [self loadingFailed:LOADING_MAP status:LOAD_NOCONNECTION];
                }];
            }
            else
                [self incrementCirclesLoadingStage];
        }
    }];
    
    // Additional admin-only query for people without location
    /*if ( [globalVariables isUserAdmin] )
    {
        friendAnyQuery = [PFUser query];
        friendAnyQuery.limit = 100;
        [friendAnyQuery orderByDescending:@"updatedAt"];
        [friendAnyQuery whereKeyDoesNotExist:@"location"];
        [friendAnyQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            
            if ( error )
                NSLog(@"Parse query for admin-only random people error: %@", error);
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
        }];
    }*/
}

- (void) loadFbOthers:(NSArray*)friends
{
    if ( ! friends )
        return;
    
    NSMutableArray *friendIds = [[pCurrentUser objectForKey:@"fbFriends"] mutableCopy];
    
    Circle *fbCircle = [self getCircle:CIRCLE_FBOTHERS];
    
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:30];
    
    // Filtering out added friends
    for (Circle *circle in [circles allValues]){
        [array addObjectsFromArray:[[circle getPersons]valueForKeyPath:@"strId"]];
    }
    [friendIds removeObjectsInArray:array];
    
    // Creating persons for fb friends that don't use app yet
    for (NSString *strId in friendIds)
    {
        for (NSDictionary *friendObject in friends)
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

- (void) loadPersonsBySearchString:(NSString*)searchString target:(id)target selector:(SEL)callback
{
    // Query
    PFQuery *personQuery = [PFUser query];
    personQuery.limit = 20;
    [personQuery orderByDescending:@"updatedAt"];
    [personQuery whereKey:@"searchName" containsString:searchString];
    [personQuery whereKey:@"profileDiscoverable" notEqualTo:[NSNumber numberWithBool:FALSE]];
    
    // Actual load
    [personQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        if ( error )
        {
            NSLog(@"Parse query for random people error: %@", error);
            [target performSelector:callback];
        }
        else
        {
            NSArray *personData = objects;
            
            // Adding users
            for (PFUser *person in personData)
                [self addPerson:person userCircle:CIRCLE_RANDOM];
            
            // Sorting random people
            Circle* circleRandom = [self getCircle:CIRCLE_RANDOM];
            if ( circleRandom )
                [circleRandom sort];
            
            [target performSelector:callback];
        }
    }];
}

- (void) loadPersonsByIdsList:(NSArray*)idsList target:(id)target selector:(SEL)callback
{
    // Query
    PFQuery *personQuery = [PFUser query];
    personQuery.limit = 100;
    [personQuery whereKey:@"fbId" containedIn:idsList];
    
    // Actual load
    [personQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        if ( error )
        {
            NSLog(@"Parse query for random people error: %@", error);
            [target performSelector:callback];
        }
        else
        {
            NSArray *personData = objects;
            
            // Adding users
            for (PFUser *person in personData)
                [self addPerson:person userCircle:CIRCLE_RANDOM];
            
            // Sorting random people
            Circle* circleRandom = [self getCircle:CIRCLE_RANDOM];
            if ( circleRandom )
                [circleRandom sort];
            
            [target performSelector:callback];
        }
    }];
}



#pragma mark -
#pragma mark Admin load of meetups

/*static NSArray* groupsData;
static NSInteger groupCounter;
static NSInteger meetupsAdded;

static NSUInteger category;
static NSString* strGroupName;
static NSString* strGroupId;

- (void)processNextGroup
{
    // Load ended
    if ( groupCounter >= groupsData.count )
    {
        if ( meetupsAdded > 0 )
        {
            UIAlertView *alertDone = [[UIAlertView alloc] initWithTitle:@"Done" message:[NSString stringWithFormat:@"Groups updated, total new meetups loaded: %d.", meetupsAdded] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alertDone show];
            [[NSNotificationCenter defaultCenter] postNotificationName:kNewMeetupChanged object:nil userInfo:nil];
        }
        return;
    }
    
    PFObject *groupData = groupsData[groupCounter];
    groupCounter++;
    
    // Skip recently updated groups
    //if ( [groupData.updatedAt compare:[NSDate dateWithTimeIntervalSinceNow:-86400]] == NSOrderedDescending )
    //{
    //    [self processNextGroup];
    //    return;
    //}
    //else
    {
        [groupData incrementKey:@"fetchCounter"];
        [groupData saveInBackground];
    }
    
    // Params to pass to loader
    NSUInteger groupType = [[groupData objectForKey:@"sourceType"] integerValue];
    NSString* strSource = [groupData objectForKey:@"sourceId"];
    
    // Params to pass to resulted meetup
    category = [[groupData objectForKey:@"category"] integerValue];
    strGroupName = [groupData objectForKey:@"groupName"];
    strGroupId = [groupData objectForKey:@"groupId"];
    
    switch (groupType)
    {
        case IMPORTED_FACEBOOK: [self loadFBMeetups:strSource]; break;
        case IMPORTED_EVENTBRITE: [self loadEBMeetups:strSource]; break;
        case IMPORTED_MEETUP: [self loadMTMeetups:strSource]; break;
    }
}

- (void)updateMeetupWithGroupDataAndSave:(Meetup*)meetup
{
    meetup.iconNumber = category;
    meetup.strOwnerName = strGroupName;
    meetup.strGroupId = strGroupId;
    
    [self addMeetup:meetup];
}

- (void)reloadGroupsAndCreateEventsInBackground
{
    groupCounter = 0;
    meetupsAdded = 0;
    
    PFQuery *groupQuery = [PFQuery queryWithClassName:@"Group"];
    groupQuery.limit = 1000;
    [groupQuery orderByDescending:@"updateDate"];
    
    // Query for public/2O meetups
    [groupQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if ( error )
        {
            NSLog(@"Parse query for groups failed: %@", error);
        }
        else
        {
            if ( objects.count == 1000 )
            {
                UIAlertView *alertDone = [[UIAlertView alloc] initWithTitle:@"Sure" message:@"You've reached max of 1000 groups, please, update the code accordingly" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alertDone show];
            }
            
            groupsData = objects;
            [self processNextGroup];
        }
    }];
}

- (void)fbMeetupsCallback:(NSArray*)events
{
    if ( ! events )
        return;
    
    for ( NSDictionary* event in events )
    {
        Meetup* meetup = [[Meetup alloc] initWithFbEvent:event];
        if ( meetup )
        {
            meetupsAdded++;
            [self addMeetup:meetup];
        }
    }
    
    [self processNextGroup];
}

- (void)loadFBMeetups:(NSString*)strSource
{
    //[fbLoader loadMeetups:self selector:@selector(fbMeetupsCallback:)];
    [self processNextGroup];
}

- (void)ebMeetupsCallback:(NSArray*)events
{
    for ( NSDictionary* event in events )
    {
        Meetup* meetup = [[Meetup alloc] initWithEbEvent:event];
        if ( meetup )
        {
            meetupsAdded++;
            [self updateMeetupWithGroupDataAndSave:meetup];
        }
    }
    
    [self processNextGroup];
}

- (void)loadEBMeetups:(NSString*)strSource
{
    if ( ! EBloader )
        EBloader = [[EventbriteLoader alloc] init];
    [EBloader loadData:strSource target:self selector:@selector(ebMeetupsCallback:)];
}

- (void)loadMTMeetups:(NSString*)strSource
{
    //[fbLoader loadMeetups:self selector:@selector(fbMeetupsCallback:)];
    [self processNextGroup];
}*/


#pragma mark -
#pragma mark Meetups


// This one is used by loader
- (FUGEvent*)addMeetupWithData:(PFObject*)meetupData
{
    // Test if such meetup was already added
    FUGEvent* meetup = (FUGEvent*)[eventManager eventById:[meetupData objectForKey:@"meetupId" ] ];
    if ( meetup )
    {
        [meetup initWithParseEvent:meetupData];
        return meetup;
    }
    
    // Expiration check
    /*NSDate* dateTimeExp = [meetupData objectForKey:@"meetupDateExp"];
    if ( [dateTimeExp compare:[NSDate date]] == NSOrderedAscending )
        return nil;*/
    
    meetup = [[FUGEvent alloc] initWithParseEvent:meetupData];
    
    // private meetups additional check
    if ( meetup.privacy == MEETUP_PRIVATE )
    {
        Boolean bSkip = true;
        NSArray* friends = [pCurrentUser objectForKey:@"fbFriends2O"];
        if ( friends && [friends containsObject:meetup.strOwnerId ] )
            bSkip = false;
        friends = [pCurrentUser objectForKey:@"fbFriends"];
        if ( friends && [friends containsObject:meetup.strOwnerId ] )
            bSkip = false;
        if ( [meetup.strOwnerId compare:[pCurrentUser objectForKey:@"fbId"] ] == NSOrderedSame )
            bSkip = false;
        if ( bSkip )
            return nil;
    }
    
    [eventManager addEvent:meetup];
    
    return meetup;
}

- (void)loadMeetupsInBackground:(PFGeoPoint*)southWest toNorthEast:(PFGeoPoint*)northEast
{
    PFQuery *meetupAnyQuery = [PFQuery queryWithClassName:@"Meetup"];
    meetupAnyQuery.limit = 100;
    
    // Location filter
    if ( ! southWest )
    {
        PFGeoPoint* ptUser = [globalVariables currentLocation];
        
        NSUInteger nDistance = RANDOM_EVENT_KILOMETERS;
        [meetupAnyQuery whereKey:@"location" nearGeoPoint:ptUser withinKilometers:nDistance];
    }
    else
    {
        [meetupAnyQuery whereKey:@"location" withinGeoBoxFromSouthwest:southWest toNortheast:northEast];
    }
    
    // Expired meetups
    [meetupAnyQuery whereKey:@"meetupDateExp" greaterThan:[NSDate date]];
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
            NSLog(@"Parse query for public meetups error: %@", error);
            [self loadingFailed:LOADING_MAP status:LOAD_NOCONNECTION];
        }
        else
        {
            NSArray *meetupsData = objects;
            for (PFObject *meetupData in meetupsData)
                [self addMeetupWithData:meetupData];
            
            // In any case, increment loading stage
            [self incrementMapLoadingStage];
        }
    }];
    
    // Query for events that user was subscribed to (to show also private and remote events/threads) - this query calls only for first request, not for the map reloads. Plus all invites!
    NSMutableArray* subscriptions = [pCurrentUser objectForKey:@"subscriptions"];
    if ( ! subscriptions )
        subscriptions = [[NSMutableArray alloc] initWithCapacity:30];
    
    // Temporary hack to load both attending and subscribed events
    NSMutableArray* attending = [pCurrentUser objectForKey:@"attending"];
    if ( attending )
    {
        for (NSString* eventId in attending)
            if ( ! [subscriptions containsObject:eventId] )
                [subscriptions addObject:eventId];
    }
    
    for ( PFObject* invite in invites )
    {
        NSString* strId = [invite objectForKey:@"meetupId"];
        if ( strId )
            [subscriptions addObject:strId];
    }
    if ( subscriptions.count > 0 )
    {
        meetupAnyQuery = [PFQuery queryWithClassName:@"Meetup"];
        meetupAnyQuery.limit = 100;
        [meetupAnyQuery orderByAscending:@"meetupDate"];
        //[meetupAnyQuery whereKey:@"meetupDateExp" greaterThan:dateLate];
        [meetupAnyQuery whereKey:@"meetupId" containedIn:subscriptions];
        
        // Query for public/2O meetups
        [meetupAnyQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
        {
            if ( error )
            {
                NSLog(@"Parse query for subscribed meetups error: %@", error);
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
                
                // In any case, increment loading stage
                [self incrementMapLoadingStage];
            }
        }];
    }
    else
        [self incrementMapLoadingStage];
}



#pragma mark -
#pragma mark Invites

- (void)createInvite:(FUGEvent*)meetup stringTo:(NSString*)strRecipient target:(id)target selector:(SEL)callback
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
            NSLog(@"Invite save error: %@", error);
            UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"No connection" message:@"One of the recent invites was not sent, check your internet connection or try again later." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [errorAlert show];
        }
        else
        {
            [pushManager sendPushInviteForMeetup:meetup.strId user:strRecipient];
            if ( target )
                [target performSelector:callback];
        }
    }];
}


#pragma mark -
#pragma mark Misc


- (void) attendMeetup:(FUGEvent*)meetup addComment:(Boolean)addComment target:(id)target selector:(SEL)callback
{
    // Check if already attending
    NSMutableArray* attending = [pCurrentUser objectForKey:@"attending"];
    if ( attending )
        for (NSString* str in attending)
            if ( [str compare:meetup.strId] == NSOrderedSame )
                return;
    
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
        {
            NSLog(@"Parse save for attendee error: %@", error);
            UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"No connection" message:@"Meetup wasn't joined, check your internet connection or try again later." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [errorAlert show];

        }
        else
        {
            // Attending list in user itself
            [pCurrentUser addUniqueObject:meetup.strId forKey:@"attending"];
            [pCurrentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if ( error )
                {
                    NSLog(@"Parse save for current user (attending meetup) error: %@", error);
                    UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"No connection" message:@"Meetup wasn't joined, check your internet connection or try again later." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [errorAlert show];

                }
                else
                {
                    // Creating comment about joining in db
                    if ( addComment && meetup.privacy == MEETUP_PRIVATE )
                    {
                        [globalData createCommentForMeetup:meetup commentType:COMMENT_JOINED commentText:nil target:nil selector:nil];
                        
                        // Push notification to all attendees
                        [pushManager sendPushAttendingMeetup:meetup.strId];
                    }
                    
                    // Update invite
                    [globalData updateInvite:meetup.strId attending:INVITE_ACCEPTED];
                    
                    // Selector
                    if ( target )
                        [target performSelector:callback withObject:nil];
                    
                    // Notify map and others about pin change
                    NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:meetup, @"meetup", nil];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNewMeetupChanged object:nil userInfo:userInfo];
                }
            }];
        }
    }];
    
    // Adding attendee to the local copy of the meetup
    [meetup addAttendee:strCurrentUserId];
}

- (void) unattendMeetup:(FUGEvent*)meetup target:(id)target selector:(SEL)callback
{
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
        {
            NSLog(@"Parse save for (leaving) attendee error: %@", error);
            UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"No connection" message:@"Meetup wasn't left, check your internet connection or try again later." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [errorAlert show];
        }
        else
        {
            // Remove from attending list and add to left list in user
            [pCurrentUser removeObject:meetup.strId forKey:@"attending"];
            [pCurrentUser addUniqueObject:meetup.strId forKey:@"meetupsLeft"];
            [pCurrentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if ( error )
                {
                    NSLog(@"Parse save for current user (unattend meetup) error: %@", error);
                    UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"No connection" message:@"Meetup wasn't left, check your internet connection or try again later." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [errorAlert show];
                }
                else
                {
                    // Creating comment about leaving in db
                    if ( meetup.privacy == MEETUP_PRIVATE )
                    {
                        [globalData createCommentForMeetup:meetup commentType:COMMENT_LEFT commentText:nil target:nil selector:nil];
                        
                        // Push notification to all attendees
                        [pushManager sendPushLeftMeetup:meetup.strId];
                    }
                    
                    // Selector
                    if ( target )
                        [target performSelector:callback withObject:nil];
                    
                    // Notify map and others about pin change
                    NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:meetup, @"meetup", nil];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNewMeetupChanged object:nil userInfo:userInfo];
                }
            }];
        }
    }];
    
    // Removing attendee to the local copy of meetup
    [meetup removeAttendee:strCurrentUserId];
}

- (void) eventCanceled:(FUGEvent*)meetup
{
    if ( ! meetup )
        return;
    
    // Creating comment about canceling
    [globalData createCommentForMeetup:meetup commentType:COMMENT_CANCELED commentText:nil target:nil selector:nil];
    
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

- (void) setRecentInvites:(NSArray*)recentInvites
{
    [[PFUser currentUser] setObject:recentInvites forKey:@"recentInvites"];
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
        
#ifdef TARGET_FUGE
        if ( firstDataLoad )
        {
            // FB friends, 2O friends, fb friends not installed the app
            [self reloadFriendsInBackground];
            
            // Inbox
            [self reloadInboxInBackground:INBOX_ALL];
            
            firstDataLoad = false;
        }
#endif
    }
}

- (void) incrementCirclesLoadingStage
{
    nCirclesLoadingStage++;
    
    if ( nCirclesLoadingStage == CIRCLES_LOADED )
    {
        nLoadStatusCircles = LOAD_OK;
        [[NSNotificationCenter defaultCenter]postNotificationName:kLoadingEncountersComplete
                                                           object:nil];
#ifdef TARGET_S2C
        if ( firstDataLoad )
        {
            // Map data: random people, meetups, threads, etc - location based
            [self reloadMapInfoInBackground:nil toNorthEast:nil];
            
            // Inbox
            [self reloadInboxInBackground:INBOX_ALL];

            firstDataLoad = false;
        }
#endif
    }
}

- (void)fbLikesCallback:(NSArray*)likes
{
    if ( likes )
    {
        [pCurrentUser setObject:likes forKey:@"fbLikes"];
        [pCurrentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if ( error )
                NSLog(@"Parse save for likes failed, error: %@", error);
        }];
    }
}


@end
