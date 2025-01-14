//
//  InboxData.m
//  SecondCircle
//
//  Created by Mikhail Larionov on 3/31/13.
//
//

#import "GlobalData.h"
#import "GlobalVariables.h"
#import "InboxViewController.h"
#import "ULEventManager.h"

@implementation GlobalData (Inbox)

#pragma mark -
#pragma mark Main

- (void)reloadInboxInBackground:(NSUInteger)inboxSection
{
    nInboxLoadingStage = 0;
    nLoadStatusInbox = LOAD_STARTED;
    
    // Invites
    if ( inboxSection == INBOX_ALL || inboxSection == INBOX_INVITES )
        [self loadInvites];
    else
        [self incrementInboxLoadingStage];
    
    // Unread PMs
    if ( inboxSection == INBOX_ALL || inboxSection == INBOX_MESSAGES )
        [self loadMessages];
    else
        [self incrementInboxLoadingStage];
    
    // Unread comments
    if ( inboxSection == INBOX_ALL || inboxSection == INBOX_COMMENTS )
        [self loadComments];
    else
        [self incrementInboxLoadingStage];
}

NSInteger sort2(id item1, id item2, void *context)
{
    InboxViewItem* i1 = item1;
    InboxViewItem* i2 = item2;
    NSDate *date1 = i1.dateTime;
    NSDate *date2 = i2.dateTime;
    if ([date2 compare:date1] == NSOrderedDescending)
        return NSOrderedDescending;
    return NSOrderedAscending;
}

- (NSMutableDictionary*) getInbox
{
    // Still loading
    if ( ! [self getLoadingStatus:LOADING_INBOX] == LOAD_OK )
        return nil;
    
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
            if ( [pObject.parseClassName compare:@"Invite"] == NSOrderedSame )
            {
                // Already accepted or declined invite
                NSDate* expirationDate = [pObject objectForKey:@"expirationDate"];
                if ( [[pObject objectForKey:@"status"] integerValue] == INVITE_ACCEPTED )
                    item.misc = @"Accepted!";
                else if ( [[pObject objectForKey:@"status"] integerValue] == INVITE_DECLINED )
                    item.misc = @"Declined.";
                else if ( [expirationDate compare:[NSDate date]] == NSOrderedAscending )
                    item.misc = @"Expired.";
                else item.misc = nil;
                
                item.type = INBOX_ITEM_INVITE;
                item.fromId = [pObject objectForKey:@"idUserFrom"];
                item.toId = [pObject objectForKey:@"idUserTo"];
                item.subject = [pObject objectForKey:@"meetupSubject"];
                item.data = pObject;
                item.dateTime = pObject.createdAt;
                item.meetup = [eventManager eventById:[pObject objectForKey:@"meetupId"]];
                
                NSUInteger meetupType = [[pObject objectForKey:@"type"] integerValue];
                if ( meetupType == TYPE_MEETUP )
                    item.message = [[NSString alloc] initWithFormat:@"%@ invited you to the meetup", [pObject objectForKey:@"nameUserFrom"]];
                else
                    item.message = [[NSString alloc] initWithFormat:@"%@ suggested you the thread", [pObject objectForKey:@"nameUserFrom"]];
                
                [tempArray addObject:item];
            }
        } else if ( [object isKindOfClass:[Person class]] ) {
            
            Person* pObject = object;
            
            item.type = INBOX_ITEM_NEWUSER;
            item.fromId = pObject.strId;
            item.toId = pObject.strId;
            item.subject = [[NSString alloc] initWithFormat:@"New %@ joined the app!", pObject.strCircle];
            item.message = [pObject fullName];
            item.misc = nil;
            item.data = pObject;
            item.dateTime = nil;
            [tempArray addObject:item];
            
        } else if ( [object isKindOfClass:[Comment class]] ) {
            
            Comment* pObject = object;
            
            item.type = INBOX_ITEM_COMMENT;
            item.fromId = pObject.strUserFrom;
            item.toId = pObject.strMeetupId;
            item.subject = pObject.strMeetupSubject;
            item.message = pObject.strComment;
            item.misc = nil;
            item.data = pObject;
            item.dateTime = pObject.dateCreated;
            item.meetup = [eventManager eventById:pObject.strMeetupId];
            [tempArray addObject:item];
            
        } else if ( [object isKindOfClass:[Message class]] ) {
            
            Message* pObject = object;
            
            item.type = INBOX_ITEM_MESSAGE;
            item.fromId = pObject.strUserFrom;
            item.toId = pObject.strUserTo;
            
            if ( [item.fromId compare:strCurrentUserId] == NSOrderedSame )
                item.subject = [[NSString alloc] initWithFormat:@"To: %@", pObject.strNameUserTo];
            else
                item.subject = [[NSString alloc] initWithFormat:@"From: %@", pObject.strNameUserFrom];
            
            item.message = pObject.strText;
            item.misc = nil;
            item.data = pObject;
            item.dateTime = pObject.dateCreated;
            [tempArray addObject:item];
        }
        
        if ( ! item.data )
            NSLog(@"Item without data! %@", item.subject);
    }
    
    // Sorting
    NSArray *sortedArray = [tempArray sortedArrayUsingFunction:sort2 context:NULL];
    
    // Creating arrays
    NSMutableDictionary* inbox = [[NSMutableDictionary alloc] init];
    NSMutableArray* inboxNew = [[NSMutableArray alloc] init];
    NSMutableArray* inboxRecent = [[NSMutableArray alloc] init];
    NSMutableArray* inboxOld = [[NSMutableArray alloc] init];
    
    // Parsing data
    NSDate* dateRecent = [[NSDate alloc] initWithTimeIntervalSinceNow:-24*60*60*7];
    Person* current = currentPerson;
    for ( InboxViewItem* item in sortedArray )
    {
        // Invites and new users always in new
        if ( item.type == INBOX_ITEM_INVITE || item.type == INBOX_ITEM_NEWUSER )
        {
            if ( item.misc )
            {
                if ( [item.dateTime compare:dateRecent] == NSOrderedDescending )
                    [inboxRecent addObject:item];
                else
                    [inboxOld addObject:item];
            }
            else
                [inboxNew addObject:item];
            continue;
        }
        
        // Messages and comments below
        Boolean bNew = false;
        
        NSDate* lastDate;
        if ( item.type == INBOX_ITEM_COMMENT || ( [item.fromId compare:strCurrentUserId] == NSOrderedSame ) )
            lastDate = [current getConversationDate:item.toId meetup:(item.type == INBOX_ITEM_COMMENT)];
        else
            lastDate = [current getConversationDate:item.fromId meetup:(item.type == INBOX_ITEM_COMMENT)];
        
        if ( ! lastDate )
            bNew = true;
        if ( lastDate && ([item.dateTime compare:lastDate] == NSOrderedDescending ) && ( [item.fromId compare:strCurrentUserId] != NSOrderedSame ) )
            bNew = true;
        
        if ( bNew )
            [inboxNew addObject:item];
        else if ( [item.dateTime compare:dateRecent] == NSOrderedDescending )
            [inboxRecent addObject:item];
        else
            [inboxOld addObject:item];
    }
    
    if ( [inboxNew count] > 0 )
        [inbox setObject:inboxNew forKey:@"New"];
    nInboxUnreadCount = [inboxNew count];
    if ( [inboxRecent count] > 0 )
        [inbox setObject:inboxRecent forKey:@"Recent"];
    if ( [inboxOld count] > 0 )
        [inbox setObject:inboxOld forKey:@"Old"];
    
    [self postInboxUnreadCountDidUpdate];
    
    return inbox;
}

- (void) incrementInboxLoadingStage
{
    nInboxLoadingStage++;
    
    if ( nInboxLoadingStage == INBOX_LOADED )
    {
        nLoadStatusInbox = LOAD_OK;
        
        [[NSNotificationCenter defaultCenter]postNotificationName:kLoadingInboxComplete
                                                           object:nil];
        // TODO: this call is an overkill, but don't know how to update new unread count other way, now we're calculating it with all other stuff upon load
        [self getInbox];
    }
}


#pragma mark -
#pragma mark Loaders (to be moved from here)


- (NSArray*)getUniqueInvites
{
    return invites;
}

- (void)loadInvites
{
    // Query
    PFQuery *invitesQuery = [PFQuery queryWithClassName:@"Invite"];
    [invitesQuery whereKey:@"idUserTo" equalTo:strCurrentUserId];
    
    // 0 means it's unaccepted invite
    NSNumber *inviteStatus = [[NSNumber alloc] initWithInt:INVITE_NEW];
    [invitesQuery whereKey:@"status" equalTo:inviteStatus];
    
    // Loading
    [invitesQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        if ( error )
        {
            NSLog(@"Uh oh. An error occurred: %@", error);
            [self loadingFailed:LOADING_INBOX status:LOAD_NOCONNECTION];
        }
        else
        {
            // Creating list of unique invites (only 1 per meetup)
            NSMutableArray* uniqueInvites = [NSMutableArray arrayWithCapacity:30];
            for ( PFObject* inviteNew in objects )
            {
                // Already subscribed
                if ( [globalData isSubscribedToThread:[inviteNew objectForKey:@"meetupId"]]
                    || [globalData isAttendingMeetup:[inviteNew objectForKey:@"meetupId"]] )
                {
                    // Saving as duplicate
                    NSNumber *inviteStatus = [[NSNumber alloc] initWithInt:INVITE_DUPLICATE];
                    [inviteNew setObject:inviteStatus forKey:@"status"];
                    [inviteNew saveInBackground];
                    continue;
                }
                
                // Expired
                NSDate* expirationDate = [inviteNew objectForKey:@"expirationDate"];
                Boolean bExpired = [expirationDate compare:[NSDate date]] == NSOrderedAscending;
                if ( bExpired )
                {
                    NSNumber *inviteStatus = [[NSNumber alloc] initWithInt:INVITE_EXPIRED];
                    [inviteNew setObject:inviteStatus forKey:@"status"];
                    [inviteNew saveInBackground];
                }
                
                Boolean bFound = false;
                for ( PFObject* inviteOld in uniqueInvites )
                {
                    // Duplicate
                    if ( [[inviteNew objectForKey:@"meetupId"] compare:[inviteOld objectForKey:@"meetupId"]] == NSOrderedSame )
                    {
                        bFound = true;
                        
                        // Saving as duplicate
                        NSNumber *inviteStatus = [[NSNumber alloc] initWithInt:INVITE_DUPLICATE];
                        [inviteNew setObject:inviteStatus forKey:@"status"];
                        [inviteNew saveInBackground];
                        
                        break;
                    }
                }
                if ( ! bFound )
                    [uniqueInvites addObject:inviteNew];
            }
            
            invites = uniqueInvites;
            
            // Loading stage complete
            [self incrementInboxLoadingStage];
        }
    }];
}


#pragma mark -
#pragma mark Misc

//-(void)

-(void)postInboxUnreadCountDidUpdate
{
    [[NSNotificationCenter defaultCenter]postNotificationName:kInboxUnreadCountDidUpdate
                                                       object:nil];
}

- (NSUInteger)getInboxUnreadCount
{
    return nInboxUnreadCount;
}

- (void) updateConversation:(NSDate*)date count:(NSNumber*)msgCount thread:(NSString*)strThread meetup:(Boolean)bMeetup
{
    // Don't keep empty conversations, we have read list for it now
    //if ( msgCount )
    //    if ( [msgCount integerValue] == 0 )
    //        return;
    
    NSMutableDictionary* conversations;
    
    NSString* strKeyDates = bMeetup ? @"threadDates" : @"messageDates";
    NSString* strKeyCounts = bMeetup ? @"threadCounts" : @"messageCounts";
    
    // Date
    if ( date )
    {
        conversations = [pCurrentUser objectForKey:strKeyDates];
        if ( ! conversations )
            conversations = [[NSMutableDictionary alloc] init];
        [conversations setValue:date forKey:strThread];
        [[PFUser currentUser] setObject:conversations forKey:strKeyDates];
    }
    
    // Count
    if ( msgCount )
    {
        conversations = [[PFUser currentUser] objectForKey:strKeyCounts];
        if ( ! conversations )
            conversations = [[NSMutableDictionary alloc] init];
        [conversations setValue:msgCount forKey:strThread];
        [[PFUser currentUser] setObject:conversations forKey:strKeyCounts];
    }
    
    // Save
    [pCurrentUser saveInBackground]; // CHECK: here was Eventually
}

- (NSUInteger) unreadConversationCount:(FUGEvent*)event
{
    if ( event.importedEvent )
        return 0;
    NSUInteger nOldCount = [currentPerson getConversationCount:event.strId meetup:true];
    if ( event.commentsCount < nOldCount )
        return 0;
    return event.commentsCount - nOldCount;
}

-(PFObject*)getInviteForMeetup:(NSString*)strId
{
    for (PFObject* invite in invites)
        if ( [strId compare:[invite objectForKey:@"meetupId"]] == NSOrderedSame )
            return invite;
    return nil;
}

- (void) updateInvite:(NSString*)strId attending:(NSUInteger)status
{
    PFObject* invite = [self getInviteForMeetup:strId];
    if ( ! invite )
        return;
    
    NSNumber *inviteStatus = [[NSNumber alloc] initWithInt:status];
    [invite setObject:inviteStatus forKey:@"status"];
    [invite saveInBackground];
    
    // Update inbox badge
    if ( nInboxUnreadCount > 0 )    // just for sure
        nInboxUnreadCount--;
    [self postInboxUnreadCountDidUpdate];
    
    // Remove accepted invite so we won't create two entities in inbox: invite and join comment
    if ( status == INVITE_ACCEPTED )
        [invites removeObject:invite];
}

- (void) setEventRead:(NSString*)eventId withExpirationDate:(NSDate*)expirationDate
{
    if ( ! eventId || ! expirationDate )
        return;
    
    if ( [self isEventRead:eventId] )
        return;
    
    readEventsDictionaryCachedPointer = nil;
    
    NSMutableDictionary* readEventsDictionary = [pCurrentUser objectForKey:@"readEventsList"];
    if ( ! readEventsDictionary )
        readEventsDictionary = [[NSMutableDictionary alloc] init];
    
    // Remove all expired records
    BOOL bFound;
    do {
        bFound = FALSE;
        for ( NSString* event in readEventsDictionary.allKeys )
        {
            NSDate* recordedDate = [readEventsDictionary objectForKey:event];
            if ( [recordedDate compare:[NSDate date]] == NSOrderedAscending )
            {
                [readEventsDictionary removeObjectForKey:event];
                bFound = TRUE;
                break;
            }
        }
    } while ( bFound );
    
    // Save this one
    [readEventsDictionary setValue:expirationDate forKey:eventId];
    [pCurrentUser setObject:readEventsDictionary forKey:@"readEventsList"];
    [pCurrentUser saveEventually];
}

- (BOOL) isEventRead:(NSString*)eventId
{
    if ( ! eventId )
        return FALSE;
    if ( ! readEventsDictionaryCachedPointer )
        readEventsDictionaryCachedPointer = [pCurrentUser objectForKey:@"readEventsList"];
    if ( ! readEventsDictionaryCachedPointer )
        return FALSE;
    
    BOOL bRead = [readEventsDictionaryCachedPointer valueForKey:eventId] ? TRUE : FALSE;
    return bRead;
}

- (void) setPersonOpportunityHidden:(NSString*)personId tillDate:(NSDate*)date
{
    if ( ! personId || ! date )
        return;
    
    NSMutableDictionary* hiddenOpportunities = [pCurrentUser objectForKey:@"hiddenOpportunities"];
    if ( ! hiddenOpportunities )
        hiddenOpportunities = [[NSMutableDictionary alloc] init];
    
    [hiddenOpportunities setObject:date forKey:personId];
    
    [pCurrentUser setObject:hiddenOpportunities forKey:@"hiddenOpportunities"];
    [pCurrentUser saveEventually];
}

- (NSDate*) getPersonOpportunityHideDate:(NSString*)personId
{
    NSMutableDictionary* hiddenOpportunities = [pCurrentUser objectForKey:@"hiddenOpportunities"];
    if ( ! hiddenOpportunities )
        return nil;
    return [hiddenOpportunities objectForKey:personId];
}

@end