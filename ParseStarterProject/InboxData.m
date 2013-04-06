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

@implementation GlobalData (Inbox)

#pragma mark -
#pragma mark Main

- (void)reloadInbox:(InboxViewController*)controller
{
    nInboxLoadingStage = 0;
    
    // Invites
    [self loadInvites:controller];
    
    // Unread PMs
    [self loadMessages:controller];
    
    // Unread comments
    [self loadComments:controller];
}

- (NSMutableDictionary*) getInbox:(InboxViewController*)controller
{
    // Still loading
    if ( ! [self isInboxLoaded] )
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
            else if ( [pObject.parseClassName compare:@"Comment"] == NSOrderedSame )
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
        else if ( [object isKindOfClass:[Message class]] )
        {
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
            if ( item.misc )
                [inboxRecent addObject:item];
            else
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
    nInboxUnreadCount = [inboxNew count];
    if ( [inboxRecent count] > 0 )
        [inbox setObject:inboxRecent forKey:@"Recent"];
    if ( [inboxOld count] > 0 )
        [inbox setObject:inboxOld forKey:@"Old"];
    
    [self updateInboxUnreadCount];
    
    return inbox;
}

- (Boolean)isInboxLoaded
{
    return ( nInboxLoadingStage == INBOX_LOADED );
}

- (void) incrementLoadingStage:(InboxViewController*)controller
{
    nInboxLoadingStage++;
    
    if ( [self isInboxLoaded] )
    {
        if ( controller )
            [controller reloadData];
        
        // TODO: this call is an overkill, but don't know how to update new count other way, now we're calculating it with all other stuff upon load
        [self getInbox:controller];
    }
}


#pragma mark -
#pragma mark Loaders (to be moved from here)


- (NSArray*)getUniqueInvites
{
    return invites;
}

- (void)loadInvites:(InboxViewController*)controller
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
    [invitesQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        // Creating list of unique invites (only 1 per meetup)
        NSMutableArray* uniqueInvites = [NSMutableArray arrayWithCapacity:30];
        for ( PFObject* inviteNew in objects )
        {
            Boolean bFound = false;
            for ( PFObject* inviteOld in uniqueInvites )
            {
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
        [self incrementLoadingStage:controller];
    }];
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

- (void)loadComments:(InboxViewController*)controller
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
        [self incrementLoadingStage:controller];
    }];
}

#pragma mark -
#pragma mark Misc

-(void)updateInboxUnreadCount
{
    [[NSNotificationCenter defaultCenter]postNotificationName:kInboxUnreadCountDidUpdate
                                                       object:nil];
}

- (NSUInteger)getInboxUnreadCount
{
    return 1;
    return nInboxUnreadCount;
}

- (void) updateConversation:(NSDate*)date count:(NSUInteger)msgCount thread:(NSString*)strThread
{
    NSMutableDictionary* conversations;
    
    // Date
    if ( date )
    {
        conversations = [[PFUser currentUser] objectForKey:@"messageDates"];
        if ( ! conversations )
            conversations = [[NSMutableDictionary alloc] init];
        [conversations setValue:date forKey:strThread];
        [[PFUser currentUser] setObject:conversations forKey:@"messageDates"];
    }
    
    // Count
    conversations = [[PFUser currentUser] objectForKey:@"messageCounts"];
    if ( ! conversations )
        conversations = [[NSMutableDictionary alloc] init];
    [conversations setValue:[[NSNumber alloc] initWithInt:msgCount] forKey:strThread];
    [[PFUser currentUser] setObject:conversations forKey:@"messageCounts"];
    
    // Save
    [[PFUser currentUser] saveEventually];
}

- (NSDate*) getConversationDate:(NSString*)strThread
{
    NSMutableDictionary* conversations = [[PFUser currentUser] objectForKey:@"messageDates"];
    if ( ! conversations )
        return nil;
    return [conversations valueForKey:strThread];
}

- (NSUInteger) getConversationCount:(NSString*)strThread
{
    NSMutableDictionary* conversations = [[PFUser currentUser] objectForKey:@"messageCounts"];
    if ( ! conversations )
        return 0;
    NSNumber* num = [conversations valueForKey:strThread];
    if ( ! num )
        return 0;
    return [num intValue];
}



@end