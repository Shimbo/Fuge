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
        nInboxUnreadCount = 0;
        newFriendsFb = nil;
        newFriends2O = nil;
    }
    
    return self;
}

-(void)createCommentForMeetup:(Meetup*)meetup commentType:(CommentType)type commentText:(NSString*)text
{
    // Creating comment about meetup creation in db
    PFObject* comment = [[PFObject alloc] initWithClassName:@"Comment"];
    NSMutableString* strComment = [[NSMutableString alloc] initWithFormat:@""];
    NSNumber* trueNum = [[NSNumber alloc] initWithInt:1];
    NSNumber* typeNum = [[NSNumber alloc] initWithInt:meetup.meetupType];
    
    switch (type)
    {
        case COMMENT_CREATED:
            [strComment appendString:[[PFUser currentUser] objectForKey:@"fbName"]];
            if (meetup.meetupType == TYPE_MEETUP)
                [strComment appendString:@" created the meetup: "];
            else
                [strComment appendString:@" created the thread: "];
            [strComment appendString:meetup.strSubject];
            [comment setObject:trueNum forKey:@"system"];
            break;
        case COMMENT_SAVED:
            [strComment appendString:[[PFUser currentUser] objectForKey:@"fbName"]];
            if (meetup.meetupType == TYPE_MEETUP)
                [strComment appendString:@" changed meetup details."];
            else
                [strComment appendString:@" changed thread details."];
            [comment setObject:trueNum forKey:@"system"];
            break;
        case COMMENT_JOINED:
            [strComment appendString:[[PFUser currentUser] objectForKey:@"fbName"]];
            [strComment appendString:@" joined the event."];
            [comment setObject:trueNum forKey:@"system"];
            break;
        case COMMENT_PLAIN:
            [strComment appendString:text];
            meetup.numComments++;
            [globalData updateConversation:nil count:meetup.numComments thread:meetup.strId];
            break;
    }
    
    [comment setObject:strCurrentUserId forKey:@"userId"];
    [comment setObject:strCurrentUserName forKey:@"userName"];
    [comment setObject:[PFUser currentUser] forKey:@"userData"];
    [comment setObject:meetup.strSubject forKey:@"meetupSubject"];
    [comment setObject:meetup.strId forKey:@"meetupId"];
    [comment setObject:meetup.meetupData forKey:@"meetupData"];
    [comment setObject:strComment forKey:@"comment"];
    [comment setObject:typeNum forKey:@"type"];
    //comment.ACL = [PFACL ACLWithUser:[PFUser currentUser]];
    //[comment.ACL setPublicReadAccess:true];
    
    [comment saveInBackground];
    
    // Add comment to the list of threads
    [self addComment:comment];
    
    // TODO: Send to everybody around (using public/2ndO filter, send checkbox and geo-query) push about the meetup
    
    // Subscription
    [globalData subscribeToThread:meetup.strId];
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
#pragma mark Friends


- (void)addPerson:(PFUser*)user userCircle:(NSUInteger)circleUser
{
    // Same user
    NSString *strId = [user objectForKey:@"fbId"];
    if ( [strId compare:[ [PFUser currentUser] objectForKey:@"fbId"] ] == NSOrderedSame )
        return;
    
    // Already added users
    if ( [self getPersonById:strId] )
        return;
    
    // Adding new person
    Person *person = [[Person alloc] init:user circle:circleUser];
    
    Circle *circle = [globalData getCircle:circleUser];
    [circle addPerson:person];
}

- (void) loadFbFriends:(id)friends
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
    
    // Excluding FB friends from 2O friends
    NSMutableArray* temp2O = [[PFUser currentUser] objectForKey:@"fbFriends2O"];
    [temp2O removeObjectsInArray:friendIds];   // To exclude FB friends from 2O
    [[PFUser currentUser] setObject:temp2O forKey:@"fbFriends2O"];
    
    // Creating new friends list
    if ( oldFriendsFb )
    {
        newFriendsFb = [[[PFUser currentUser] objectForKey:@"fbFriends"] mutableCopy];
        newFriends2O = [[[PFUser currentUser] objectForKey:@"fbFriends2O"] mutableCopy];
        [newFriendsFb removeObjectsInArray:oldFriendsFb];
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
}

- (void) load2OFriends
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

- (void) loadRandom
{
    PFGeoPoint* ptUser = [[PFUser currentUser] objectForKey:@"location"];
    if ( ! ptUser )
        return;
    
    // Query
    PFQuery *friendAnyQuery = [PFUser query];
    [friendAnyQuery whereKey:@"location" nearGeoPoint:ptUser withinKilometers:RANDOM_PERSON_KILOMETERS];
    [friendAnyQuery whereKey:@"profileDiscoverable" notEqualTo:[[NSNumber alloc] initWithBool:FALSE]];
    NSArray *friendAnyUsers = [friendAnyQuery findObjects];
    
    // Adding users
    for (PFUser *friendAnyUser in friendAnyUsers)
        [self addPerson:friendAnyUser userCircle:CIRCLE_RANDOM];
    
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
#pragma mark Reloaders: meetups

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
        return meetup;
    
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
    return;
    
    //    FBRequest *request = [FBRequest requestForMe];
    //    [request startWithCompletionHandler:^(FBRequestConnection *connection,
    //                                          id result, NSError *error) {
    
    // Facebook events
    //    [self.facebook authorize:[NSArray arrayWithObjects:@"user_events",
    //                              @"friends_events",  nil]];
    
    //NSArray *permissions = [[NSArray alloc] initWithObjects: @"user_events", nil];
    //[FBSession openActiveSessionWithReadPermissions:permissions allowLoginUI:YES completionHandler:nil];
    //NSLog(@"permissions::%@",FBSession.activeSession.permissions);
    
    /*FBRequest *friendRequest = [FBRequest requestForGraphPath:@"me/friends?fields=name,picture,birthday,location"];
     [ friendRequest startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
     NSArray *data = [result objectForKey:@"data"];
     for (FBGraphObject<FBGraphUser> *friend in data) {
     NSLog(@"%@:%@", [friend name],[friend birthday]);
     }}];*/
    
    // pic_small,pic_big,
    
    //name,description,eid,
    //location
    // id,latitude,longitude,located_in
    
    NSString* fql1 = [NSString stringWithFormat:
                      @"SELECT venue from event WHERE eid in (SELECT eid FROM event_member WHERE uid = me())"];
    NSString* fql2 = [NSString stringWithFormat:
                      @"SELECT name FROM page WHERE page_id IN (SELECT venue.id FROM #event_info)"];
    NSString* fqlStr = [NSString stringWithFormat:
                        @"{\"event_info\":\"%@\",\"event_venue\":\"%@\"}",fql1,fql2];
    NSDictionary* params = [NSDictionary dictionaryWithObject:fqlStr forKey:@"queries"];
    
    
    //FBRequest *fql = [FBRequest requestForGraphPath:@"fql.multiquery"];
    FBRequest *fql = [FBRequest requestWithGraphPath:@"fql.query" parameters:params HTTPMethod:@"POST"];
    
    [fql startWithCompletionHandler:^(FBRequestConnection *connection,
                                      id result,
                                      NSError *error) {
        if (result) {
            NSLog(@"result:%@", result);
        }
        if (error) {
            NSLog(@"error:%@", error);
        }
    }];
    
    FBRequest *request = [FBRequest requestForGraphPath:@"me/events"];
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        
        NSArray* events = [result objectForKey:@"data"];
        
        /*        for ( FBGraphObject* event in events )
         {
         NSLog(@"%@", [event objectForKey:@"id"] );
         NSDictionary* venue = [event objectForKey:@"venue"];
         if ( venue )
         NSLog(@"%d", [[venue objectForKey:@"latitude"] integerValue] );
         }*/
        
    }];
    
    //[self.facebook requestWithGraphPath:@"me/events" andDelegate:friendsVC];

}

- (void)loadMeetups
{
    PFGeoPoint* ptUser = [[PFUser currentUser] objectForKey:@"location"];
    if ( ! ptUser )
        return;
    
    PFQuery *meetupAnyQuery = [PFQuery queryWithClassName:@"Meetup"];
    meetupAnyQuery.limit = 100;
    
    // Location filter
    [meetupAnyQuery whereKey:@"location" nearGeoPoint:ptUser withinKilometers:RANDOM_EVENT_KILOMETERS];
    
    // Date-time filter
    NSDate* dateHide = [NSDate date];
    [meetupAnyQuery whereKey:@"meetupDateExp" greaterThan:dateHide];
    
    // Privacy filter
    NSNumber* privacyTypePrivate = [[NSNumber alloc] initWithInt:MEETUP_PRIVATE];
    [meetupAnyQuery whereKey:@"privacy" notEqualTo:privacyTypePrivate];
    
    // Query for public/2O meetups
    NSArray *meetupsData = [meetupAnyQuery findObjects];
    for (PFObject *meetupData in meetupsData)
        [self addMeetupWithData:meetupData];
    
    // Query for events that user was subscribed to (to show also private and remote events/threads)
    NSArray* subscriptions = [[PFUser currentUser] objectForKey:@"subscriptions"];
    if ( subscriptions && subscriptions.count > 0 )
    {
        meetupAnyQuery = [PFQuery queryWithClassName:@"Meetup"];
        meetupAnyQuery.limit = 1000;
        [meetupAnyQuery whereKey:@"meetupDateExp" greaterThan:dateHide];
        [meetupAnyQuery whereKey:@"meetupId" containedIn:subscriptions];
        meetupsData = [meetupAnyQuery findObjects];
        
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
}



#pragma mark -
#pragma mark Invites

- (void)createInvite:(Meetup*)meetup objectTo:(Person*)recipient stringTo:(NSString*)strRecipient
{
    PFObject* invite = [[PFObject alloc] initWithClassName:@"Invite"];
    
    // Id, fromStr, fromId
    [invite setObject:meetup.strId forKey:@"meetupId"];
    [invite setObject:meetup.meetupData forKey:@"meetupData"];
    [invite setObject:[[NSNumber alloc] initWithDouble:[meetup.dateTime timeIntervalSince1970]] forKey:@"meetupTimestamp"];
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
    
    [invite save];
}


#pragma mark -
#pragma mark Global


- (void)reload:(MapViewController*)controller
{
    // Clean old data
    [circles removeAllObjects];
    [meetups removeAllObjects];
    
    // Current user data
    FBRequest *request = [FBRequest requestForMe];
    [request startWithCompletionHandler:^(FBRequestConnection *connection,
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
        FBRequest *request2 = [FBRequest requestForMyFriends];
        [request2 startWithCompletionHandler:^(FBRequestConnection *connection,
                                               id result, NSError *error)
        {
            if (!error)
            {
                // FB friends
                [self loadFbFriends:result];
                
                // 2O friends
                [self load2OFriends];
                
                // Random friends
                [self loadRandom];
                
                // FB friends out of the app
                [self loadFbOthers:result];
                
                // Meetups
                [self loadMeetups];
                
                // FB Meetups
                [self loadFBMeetups];
                
                // Pushes sent for new users, turn it off
                [globalVariables pushToFriendsSent];
                
                // Save user data
                [[PFUser currentUser] saveInBackground]; // // TODO: here was Eventually - ?
                
                // Reload table
                if ( controller )
                    [controller reloadFinished];
                
                // Start background loading for inbox
                [self reloadInbox:nil];
            }
            else
            {
                NSLog(@"Uh oh. An error occurred: %@", error);
            }
        }];
    }];
}

- (void)addComment:(PFObject*)comment
{
    [comments addObject:comment];
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
    [[PFUser currentUser] saveInBackground]; // TODO: here was Eventually
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

- (void) setUserPosition:(PFGeoPoint*)geoPoint
{
    if ( [[PFUser currentUser] isAuthenticated] )
        [[PFUser currentUser] setObject:geoPoint forKey:@"location"];
}

- (void) removeUserFromNew:(NSString*)strUser
{
    [newFriendsFb removeObject:strUser];
    [newFriends2O removeObject:strUser];
}

@end