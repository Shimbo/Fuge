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
            if (meetup.meetupType == TYPE_MEETUP)
                [strComment appendString:@" created the meetup: "];
            else
                [strComment appendString:@" created the thread: "];
            [strComment appendString:meetup.strSubject];
            [comment setObject:[trueNum stringValue] forKey:@"system"];
            break;
        case COMMENT_SAVED:
            [strComment appendString:[[PFUser currentUser] objectForKey:@"fbName"]];
            if (meetup.meetupType == TYPE_MEETUP)
                [strComment appendString:@" changed meetup details."];
            else
                [strComment appendString:@" changed thread details."];
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
    [comment setObject:strCurrentUserName forKey:@"userName"];
    [comment setObject:[PFUser currentUser] forKey:@"userData"];
    [comment setObject:meetup.strSubject forKey:@"meetupSubject"];
    [comment setObject:meetup.strId forKey:@"meetupId"];
    [comment setObject:meetup.meetupData forKey:@"meetupData"];
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
    
    // Creating new friends list
    newFriendsFb = [[[PFUser currentUser] objectForKey:@"fbFriends"] mutableCopy];
    newFriends2O = [[[PFUser currentUser] objectForKey:@"fbFriends2O"] mutableCopy];
    [newFriendsFb removeObjectsInArray:oldFriendsFb];
    [newFriends2O removeObjectsInArray:oldFriends2O];
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


- (NSMutableDictionary*) getInbox:(InboxViewController*)controller
{
    // Gathering data
    NSMutableArray* inboxData = [[NSMutableArray alloc] init];
    [inboxData addObjectsFromArray:[self getUniqueInvites]];
    [inboxData addObjectsFromArray:[self getUniqueMessages]];
    [inboxData addObjectsFromArray:[self getUniqueThreads]];
    [inboxData addObjectsFromArray:[self getPersonsByIds:newFriendsFb]];
    [inboxData addObjectsFromArray:[self getPersonsByIds:newFriends2O]];
    
    // Creating temporary array for all items
    NSMutableArray* tempArray = [[NSMutableArray alloc] init];
    for ( id object in inboxData )
    {
        InboxViewItem* item = [[InboxViewItem alloc] init];
        if ( [object isKindOfClass:[PFObject class]] )
        {
            PFObject* pObject = object;
            if ( [[pObject className] compare:@"Invite"] == NSOrderedSame )
            {
                // Already accepted or declined invite
                if ( [[pObject objectForKey:@"status"] integerValue] == INVITE_ACCEPTED )
                    item.misc = @"Accepted!";
                else if ( [[pObject objectForKey:@"status"] integerValue] == INVITE_DECLINED )
                    item.misc = @"Declined.";
                else item.misc = nil;
                
                item.type = INBOX_ITEM_INVITE;
                item.fromId = [pObject objectForKey:@"idUserFrom"];
                item.toId = [pObject objectForKey:@"idUserTo"];
                item.message = [pObject objectForKey:@"meetupSubject"];
                item.data = object;
                item.dateTime = pObject.createdAt;
                
                NSUInteger meetupType = [[pObject objectForKey:@"type"] integerValue];
                if ( meetupType == TYPE_MEETUP )
                    item.subject = [[NSString alloc] initWithFormat:@"%@ invited to:", [pObject objectForKey:@"nameUserFrom"]];
                else
                    item.subject = [[NSString alloc] initWithFormat:@"%@ suggested:", [pObject objectForKey:@"nameUserFrom"]];
                
                [tempArray addObject:item];
            }
            if ( [[pObject className] compare:@"Message"] == NSOrderedSame )
            {
                item.type = INBOX_ITEM_MESSAGE;
                item.fromId = [pObject objectForKey:@"idUserFrom"];
                item.toId = [pObject objectForKey:@"idUserTo"];
                
                if ( [item.fromId compare:[[PFUser currentUser] objectForKey:@"fbId"]] == NSOrderedSame )
                    item.subject = [[NSString alloc] initWithFormat:@"To: %@", [pObject objectForKey:@"nameUserTo"]];
                else
                    item.subject = [[NSString alloc] initWithFormat:@"From: %@", [pObject objectForKey:@"nameUserFrom"]];
                
                item.message = [pObject objectForKey:@"text"];
                item.misc = nil;
                item.data = pObject;
                item.dateTime = pObject.createdAt;
                [tempArray addObject:item];
            }
            if ( [[pObject className] compare:@"Comment"] == NSOrderedSame )
            {
                item.type = INBOX_ITEM_COMMENT;
                item.fromId = [pObject objectForKey:@"userId"];
                item.toId = [pObject objectForKey:@"userId"];
                item.subject = [pObject objectForKey:@"meetupSubject"];
                item.message = [pObject objectForKey:@"comment"];
                item.misc = nil;
                item.data = pObject;
                item.dateTime = pObject.createdAt;
                [tempArray addObject:item];
            }
        }
        else if ( [object isKindOfClass:[Person class]] )
        {
            Person* pObject = object;
            
            item.type = INBOX_ITEM_NEWUSER;
            item.fromId = pObject.strId;
            item.toId = pObject.strId;
            item.subject = [[NSString alloc] initWithFormat:@"New %@ joined the app!", pObject.strCircle];
            item.message = pObject.strName;
            item.misc = nil;
            item.data = pObject;
            item.dateTime = nil;
            [tempArray addObject:item];
        }
    }
    
    // Creating arrays
    NSMutableDictionary* inbox = [[NSMutableDictionary alloc] init];
    NSMutableArray* inboxNew = [[NSMutableArray alloc] init];
    NSMutableArray* inboxRecent = [[NSMutableArray alloc] init];
    NSMutableArray* inboxOld = [[NSMutableArray alloc] init];
    
    // Parsing data
    NSDate* dateRecent = [[NSDate alloc] initWithTimeIntervalSinceNow:-24*60*60*7];
    for ( InboxViewItem* item in tempArray )
    {
        // Invites always in new
        if ( item.type == INBOX_ITEM_INVITE || item.type == INBOX_ITEM_NEWUSER )
        {
            [inboxNew addObject:item];
            continue;
        }
        
        // Messages
        NSDictionary* conversation = [[PFUser currentUser] objectForKey:@"datesMessages"];
        if ( conversation )
        {
            NSDate* lastDate = [conversation objectForKey:item.fromId];
            if ( [item.dateTime compare:lastDate] == NSOrderedDescending )
            {
                [inboxNew addObject:item];
                continue;
            }
        }
        
        if ( [item.dateTime compare:dateRecent] == NSOrderedDescending )
            [inboxRecent addObject:item];
        else
            [inboxOld addObject:item];
    }
    
    if ( [inboxNew count] > 0 )
        [inbox setObject:inboxNew forKey:@"New"];
    if ( [inboxRecent count] > 0 )
        [inbox setObject:inboxRecent forKey:@"Recent"];
    if ( [inboxOld count] > 0 )
        [inbox setObject:inboxOld forKey:@"Old"];
    
    
    [[NSNotificationCenter defaultCenter]postNotificationName:kInboxUnreadCountDidUpdate
                                                       object:nil];
    nInboxUnreadCount = [inboxNew count];
    
    return inbox;    
}

- (NSUInteger)getInboxUnreadCount
{
    return nInboxUnreadCount;
}

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

- (void)addMessage:(PFObject*)message
{
    [messages addObject:message];
}

- (NSArray*)getUniqueThreads
{
    NSMutableArray *threadsUnique = [[NSMutableArray alloc] init];
    
    for (PFObject *comment in comments)
    {
        // Looking for already created thread
        Boolean bSuchThreadAlreadyAdded = false;
        for (PFObject *commentOld in threadsUnique)
            if ( [[comment objectForKey:@"meetupId"] compare:[commentOld objectForKey:@"meetupId"]] == NSOrderedSame )
            {
                // Replacing with an older unread:
                // checking date, if it's > than last read, but < than current, replace
                
                Boolean bExchange = false;
                
                Boolean bOwnMessage = ( [[comment objectForKey:@"userId"] compare:strCurrentUserId] == NSOrderedSame );
                Boolean bOldOwnMessage = ( [[commentOld objectForKey:@"userId"] compare:strCurrentUserId] == NSOrderedSame );
                
                NSDate* lastReadDate = [self getConversationDate:[comment objectForKey:@"meetupId"]];
                
                Boolean bOldBeforeThanReadDate = false;
                Boolean bNewLaterThanReadDate = true;
                Boolean bNewIsBeforeOld = false;
                if ( commentOld.createdAt && comment.createdAt )
                {
                    bNewIsBeforeOld = ( [ comment.createdAt compare:commentOld.createdAt ] == NSOrderedAscending );
                    if ( lastReadDate )
                    {
                        bOldBeforeThanReadDate = [commentOld.createdAt compare:lastReadDate] != NSOrderedDescending;
                        bNewLaterThanReadDate = [comment.createdAt compare:lastReadDate] == NSOrderedDescending;
                    }
                }
                
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
                    [threadsUnique removeObject:commentOld];
                else
                    bSuchThreadAlreadyAdded = true;
                break;
            }
        
        // Adding object
        if ( ! bSuchThreadAlreadyAdded )
            [threadsUnique addObject:comment];
    }
    
    return threadsUnique;
}

- (void)loadComments
{
    // Query
    PFQuery *messagesQuery = [PFQuery queryWithClassName:@"Comment"];
    NSArray* subscriptions = [[PFUser currentUser] objectForKey:@"subscriptions"];
    [messagesQuery whereKey:@"meetupId" containedIn:subscriptions];
    
    // TODO: add here later another query limitation by date (like 10 last days) to not push server too hard. It will be like pages, loading every 10 previous days or so.
    
    // Loading
    [messagesQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        // Comments
        comments = [[NSMutableArray alloc] initWithArray:objects];
        
        // Loading stage complete
        nInboxLoadingStage++;
    }];
}

- (void)addComment:(PFObject*)comment
{
    [comments addObject:comment];
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
                [[PFUser currentUser] saveEventually];
                
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

- (void) addRecentInvites:(NSArray*)recentInvites
{
    [[PFUser currentUser] addUniqueObjectsFromArray:recentInvites forKey:@"recentInvites"];
    [[PFUser currentUser] saveEventually];
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
    [[PFUser currentUser] saveEventually];
}

- (NSArray*) getRecentPersons
{
    NSArray* arrayRecentsIds = [[PFUser currentUser] objectForKey:@"recentInvites"];
    return [globalData getPersonsByIds:arrayRecentsIds];
}

- (NSArray*) getRecentVenues
{
    return [[PFUser currentUser] objectForKey:@"recentVenues"];
}

- (Boolean) isUserAdmin
{
    if ([[PFUser currentUser] objectForKey:@"admin"])
        return true;
    return false;
}

@end