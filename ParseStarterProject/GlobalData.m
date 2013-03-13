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
#import "InboxViewController.h"
#import "FSVenue.h"

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
        messages = [[NSMutableArray alloc] init];
        nInboxLoadingStage = 0;
    }
    
    return self;
}

-(void)createCommentForMeetup:(Meetup*)meetup commentType:(NSUInteger)type commentText:(NSString*)text
{
    // Creating comment about meetup creation in db
    PFObject* comment = [[PFObject alloc] initWithClassName:@"Comment"];
    NSMutableString* strComment = [[NSMutableString alloc] initWithFormat:@""];
    NSNumber* trueNum = [[NSNumber alloc] initWithBool:true];
    
    switch (type)
    {
        case COMMENT_CREATED:
            [strComment appendString:[[PFUser currentUser] objectForKey:@"fbName"]];
            [strComment appendString:@" created the meetup: "];
            [strComment appendString:meetup.strSubject];
            [comment setObject:[trueNum stringValue] forKey:@"system"];
            break;
        case COMMENT_SAVED:
            [strComment appendString:[[PFUser currentUser] objectForKey:@"fbName"]];
            [strComment appendString:@" changed meetup details."];
            [comment setObject:[trueNum stringValue] forKey:@"system"];
            break;
        case COMMENT_JOINED:
            [strComment appendString:[[PFUser currentUser] objectForKey:@"fbName"]];
            [strComment appendString:@" joined the event."];
            [comment setObject:[trueNum stringValue] forKey:@"system"];
            break;
        case COMMENT_PLAIN:
            [strComment appendString:text];
            break;
    }
    
    [comment setObject:strCurrentUserId forKey:@"userId"];
    [comment setObject:meetup.strOwnerId forKey:@"userId"];
    [comment setObject:strCurrentUserName forKey:@"userName"];
    [comment setObject:meetup.strId forKey:@"meetupId"];
    [comment setObject:strComment forKey:@"comment"];
    //comment.ACL = [PFACL ACLWithUser:[PFUser currentUser]];
    //[comment.ACL setPublicReadAccess:true];
    
    [comment saveInBackground];
    
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
    NSArray* values = [circles allValues];
    NSArray* sortedValues = [values sortedArrayUsingFunction:sortByName context:nil];
    
    int n = 0;
    for (Circle *circle in sortedValues)
    {
        if ( n == num )
            return circle;
        n++;
    }
    return nil;
}

- (NSArray*) getPersonsByIds:(NSArray*)strFbIds
{
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:20];
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

- (NSArray*) getInbox
{
    NSMutableArray* inboxData = [[NSMutableArray alloc] init];
    [inboxData addObjectsFromArray:[self getUniqueInvites]];
    [inboxData addObjectsFromArray:[self getUniqueMessages]];
    return inboxData;
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
    // Query
    PFQuery *friendAnyQuery = [PFUser query];
    [friendAnyQuery whereKey:@"location" nearGeoPoint:[[PFUser currentUser] objectForKey:@"location"] withinKilometers:RANDOM_PERSON_KILOMETERS];
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
    // TODO: test if such meetup was already added
    
    [meetups addObject:meetup];
}

// This one is used by loader
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

- (void)loadMeetups
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
    // TODO: remove, load meetups with invitation upon invitation enter
    // Really? Shouldn't we show em on the map? I believe we should.
    //meetupAnyQuery = [PFQuery queryWithClassName:@"Meetup"];
    //[meetupAnyQuery whereKey:@"meetupTimestamp" greaterThan:timestampNow];
    // TODO: add invitation check
    //meetupsData = [meetupAnyQuery findObjects];
    //for (PFObject *meetupData in meetupsData)
    //    [self addMeetup:meetupData];
    
    // TODO: query for meetups that were joined or subscribed to
    // Subscriptions should be saved in user itself as only user access this info. Join/comment subscibes. Unsubscribe/subscribe button in thread (where join/exit for meetups)
    
    // Invite of two types: to join and to subscribe (invitation to thread, see/cancel). Meeting invitaton. Petro Petronico invited you: /n ... Acceptance will be seen in meetup messages (inbox too)
    
    // Read times for meetups as for PMs
    
    // Resume: Subscription in user, invitation as separate database, two types: to see thread and to join meeting. Accepting/canceling invitation closes it and joins meeting/opens thread. Probably, meeting should be opened as well, don't join from inbox.
}


#pragma mark -
#pragma mark Inbox

- (NSArray*)getUniqueInvites
{
    return invites;
}

- (void)loadInvites
{
    // Query
    PFQuery *invitesQuery = [PFQuery queryWithClassName:@"Invite"];
    [invitesQuery whereKey:@"idUserTo" equalTo:strCurrentUserId];
    
    // Date-time filter
    NSNumber* timestampNow = [[NSNumber alloc] initWithDouble:[[NSDate date] timeIntervalSince1970]];
    [invitesQuery whereKey:@"meetupTimestamp" greaterThan:timestampNow];
    
    // 0 means it's unaccepted invite
    NSNumber *inviteStatus = [[NSNumber alloc] initWithInt:INVITE_NEW];
    [invitesQuery whereKey:@"status" equalTo:inviteStatus];
    
    // Loading
    [invitesQuery findObjectsInBackgroundWithBlock:^(NSArray *objects1, NSError *error) {
        
        /*PFQuery *messagesQuery = [PFQuery queryWithClassName:@"Message"];
        [messagesQuery whereKey:@"idUserFrom" equalTo:[[PFUser currentUser] objectForKey:@"fbId"]];
        
        [messagesQuery findObjectsInBackgroundWithBlock:^(NSArray *objects2, NSError *error) {*/
            
            // Merging results
            NSMutableSet *set = [NSMutableSet setWithArray:objects1];
            //[set addObjectsFromArray:objects2];
            
            // Actuall messages
            invites = [[NSMutableArray alloc] initWithArray:[set allObjects]];
            
            // Recalc what to show in inbox
            //[self updateUniqueMessages];
            
            // Loading stage complete
            nInboxLoadingStage++;
        //}];
    }];
    
    nInboxLoadingStage++;
}

- (NSArray*)getUniqueMessages
{
    NSMutableArray *messagesUnique = [[NSMutableArray alloc] init];
    
    for (PFObject *message in messages)
    {
        // Looking for already created thread
        Boolean bSuchUserAlreadyAdded = false;
        for (PFObject *messageOld in messagesUnique)
            if ( ( [[message objectForKey:@"idUserFrom"] compare:[messageOld objectForKey:@"idUserFrom"]] == NSOrderedSame ) ||
                ( [[message objectForKey:@"idUserTo"] compare:[messageOld objectForKey:@"idUserFrom"]] == NSOrderedSame ) ||
                ( [[message objectForKey:@"idUserFrom"] compare:[messageOld objectForKey:@"idUserTo"]] == NSOrderedSame) )
            {
                // Replacing with an older unread:
                // checking date, if it's > than last read, but < than current, replace
                
                Boolean bExchange = false;
                
                Boolean bOwnMessage = ( [[message objectForKey:@"idUserFrom"] compare:[[PFUser currentUser] objectForKey:@"fbId"]] == NSOrderedSame );
                Boolean bOldOwnMessage = ( [[messageOld objectForKey:@"idUserFrom"] compare:[[PFUser currentUser] objectForKey:@"fbId"]] == NSOrderedSame );
                
                NSDate* lastReadDate;
                if ( bOwnMessage )
                    lastReadDate = [self getConversationDate:[message objectForKey:@"idUserTo"]];
                else
                    lastReadDate = [self getConversationDate:[message objectForKey:@"idUserFrom"]];
                
                Boolean bOldBeforeThanReadDate = false;
                Boolean bNewLaterThanReadDate = true;
                Boolean bNewIsBeforeOld = false;
                if ( messageOld.createdAt && message.createdAt )
                {
                    bNewIsBeforeOld = ( [ message.createdAt compare:messageOld.createdAt ] == NSOrderedAscending );
                    if ( lastReadDate )
                    {
                        bOldBeforeThanReadDate = [messageOld.createdAt compare:lastReadDate] != NSOrderedDescending;
                        bNewLaterThanReadDate = [message.createdAt compare:lastReadDate] == NSOrderedDescending;
                    }
                }
                
                //NSLog([message objectForKey:@"text"]);
                //NSLog([messageOld objectForKey:@"text"]);
                
                // New message is not older, but old message is already read
                if ( ! bNewIsBeforeOld && bOldBeforeThanReadDate )
                    bExchange = true;
                
                // New message is older but still unread
                if ( bNewIsBeforeOld && bNewLaterThanReadDate && ! bOwnMessage )
                    bExchange = true;
                
                // User own messages is later than old unread
                if ( ! bNewIsBeforeOld && bOwnMessage )
                    bExchange = true;
                
                // New message is after own users message
                if ( ! bNewIsBeforeOld && bOldOwnMessage )
                    bExchange = true;
                
                if ( bExchange)
                    [messagesUnique removeObject:messageOld];
                else
                    bSuchUserAlreadyAdded = true;
                break;
            }
        
        // Adding object
        if ( ! bSuchUserAlreadyAdded )
            [messagesUnique addObject:message];
    }
    
    return messagesUnique;
}

- (void)loadMessages
{
    // Query
    PFQuery *messagesQuery = [PFQuery queryWithClassName:@"Message"];
    [messagesQuery whereKey:@"idUserTo" equalTo:[[PFUser currentUser] objectForKey:@"fbId"]];
    
    // TODO: add here later another query limitation by date (like 10 last days) to not push server too hard. It will be like pages, loading every 10 previous days or so.
    
    // Loading
    [messagesQuery findObjectsInBackgroundWithBlock:^(NSArray *objects1, NSError *error) {
        
        PFQuery *messagesQuery = [PFQuery queryWithClassName:@"Message"];
        [messagesQuery whereKey:@"idUserFrom" equalTo:[[PFUser currentUser] objectForKey:@"fbId"]];
        
        [messagesQuery findObjectsInBackgroundWithBlock:^(NSArray *objects2, NSError *error) {
            
            // Merging results
            NSMutableSet *set = [NSMutableSet setWithArray:objects1];
            [set addObjectsFromArray:objects2];
            
            // Actuall messages
            messages = [[NSMutableArray alloc] initWithArray:[set allObjects]];
            
            // Recalc what to show in inbox
            //[self updateUniqueMessages];
            
            // Loading stage complete
            nInboxLoadingStage++;
        }];
    }];
}

- (void)loadComments
{
    // Query
    /*PFQuery *messagesQuery = [PFQuery queryWithClassName:@"Comment"];
    [messagesQuery whereKey:@"idUserTo" equalTo:[[PFUser currentUser] objectForKey:@"fbId"]];
    
    // TODO: add here later another query limitation by date (like 10 last days) to not push server too hard. It will be like pages, loading every 10 previous days or so.
    
    // Loading
    [messagesQuery findObjectsInBackgroundWithBlock:^(NSArray *objects1, NSError *error) {
        
        PFQuery *messagesQuery = [PFQuery queryWithClassName:@"Message"];
        [messagesQuery whereKey:@"idUserFrom" equalTo:[[PFUser currentUser] objectForKey:@"fbId"]];
        
        [messagesQuery findObjectsInBackgroundWithBlock:^(NSArray *objects2, NSError *error) {
            
            // Merging results
            NSMutableSet *set = [NSMutableSet setWithArray:objects1];
            [set addObjectsFromArray:objects2];
            
            // Actuall messages
            messages = [[NSMutableArray alloc] initWithArray:[set allObjects]];
            
            // Recalc what to show in inbox
            //[self updateUniqueMessages];
            
            // Loading stage complete
            nInboxLoadingStage++;
        }];
    }];*/
}

- (void)addMessage:(PFObject*)message
{
    [messages addObject:message];
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
                [self loadFbFriends:result];
                
                // 2O friends
                [self load2OFriends];
                
                // Random friends
                [self loadRandom];
                
                // FB friends out of the app
                [self loadFbOthers:result];
                
                // Meetups
                [self loadMeetups];
                
                // Pushes sent for new users, turn it off
                [globalVariables pushToFriendsSent];
                
                // Save user data
                [[PFUser currentUser] save];
                
                // Reload table
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

- (void)reloadInbox:(InboxViewController*)controller
{
    nInboxLoadingStage = 0;
    
    // Invites
    [self loadInvites];
    
    // Unread PMs
    [self loadMessages];
    
    // Unread comments
    [self loadComments];
    
    // During initial load controller could be nil as we're loading from main view
    //if ( controller )
    //    [controller reloadFinished];
}

- (Boolean)isInboxLoaded
{
    return ( nInboxLoadingStage == INBOX_LOADED );
}


#pragma mark -
#pragma mark Inbox misc


- (void) updateConversationDate:(NSDate*)date thread:(NSString*)strThread
{
    NSMutableDictionary* conversations = [[PFUser currentUser] objectForKey:@"datesMessages"];
    if ( ! conversations )
        conversations = [[NSMutableDictionary alloc] init];
    [conversations setValue:date forKey:strThread];
    [[PFUser currentUser] setObject:conversations forKey:@"datesMessages"];
    [[PFUser currentUser] saveEventually];
}

- (NSDate*) getConversationDate:(NSString*)strThread
{
    NSMutableDictionary* conversations = [[PFUser currentUser] objectForKey:@"datesMessages"];
    if ( ! conversations )
        return nil;
    return [conversations valueForKey:strThread];
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
    [[PFUser currentUser] saveEventually];
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
    [[PFUser currentUser] saveEventually];
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

@end