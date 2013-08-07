//
//  MessageData.m
//  SecondCircle
//
//  Created by Mikhail Larionov on 3/31/13.
//
//

#import "GlobalData.h"
#import "GlobalVariables.h"
#import "Message.h"
#import "TestFlight.h"

@implementation GlobalData (Messages)

- (void)addMessage:(Message*)message
{
    [messages addObject:message];
}

- (void)addMessageWithData:(PFObject*)messageData
{
    Message* message = [[Message alloc] init];
    [message unpack:messageData];
    [messages addObject:message];
}

- (NSArray*)getUniqueMessages
{
    NSMutableArray *messagesUnique = [[NSMutableArray alloc] init];
    
    NSMutableDictionary* unreadCounts = [[NSMutableDictionary alloc] initWithCapacity:30];
    Person* current = currentPerson;
    for (Message *message in messages)
    {
        // Looking for already created thread
        Boolean bSuchUserAlreadyAdded = false;
        for (Message *messageOld in messagesUnique)
            if ( ( ( [message.strUserFrom compare:messageOld.strUserFrom] == NSOrderedSame ) &&
                ( [message.strUserTo compare:messageOld.strUserTo] == NSOrderedSame ) ) ||
                ( ( [message.strUserFrom compare:messageOld.strUserTo ] == NSOrderedSame) &&
                ( [message.strUserTo compare:messageOld.strUserFrom ] == NSOrderedSame) ) )
            {
                // Replacing with an older unread:
                // checking date, if it's > than last read, but < than current, replace
                
                Boolean bExchange = false;
                
                Boolean bOwnMessage = ( [message.strUserFrom compare:strCurrentUserId] == NSOrderedSame );
                Boolean bOldOwnMessage = ( [messageOld.strUserFrom compare:strCurrentUserId] == NSOrderedSame );
                
                NSDate* lastReadDate;
                if ( bOwnMessage )
                    lastReadDate = [current getConversationDate:message.strUserTo meetup:FALSE];
                else
                    lastReadDate = [current getConversationDate:message.strUserFrom meetup:FALSE];
                
                Boolean bOldBeforeThanReadDate = false;
                Boolean bNewLaterThanReadDate = true;
                Boolean bNewIsBeforeOld = false;
                if ( messageOld.dateCreated && message.dateCreated )
                {
                    bNewIsBeforeOld = ( [ message.dateCreated compare:messageOld.dateCreated ] == NSOrderedAscending );
                    if ( lastReadDate )
                    {
                        bOldBeforeThanReadDate = [messageOld.dateCreated compare:lastReadDate] != NSOrderedDescending;
                        bNewLaterThanReadDate = [message.dateCreated compare:lastReadDate] == NSOrderedDescending;
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
                
                // Exchanging
                if ( bExchange)
                    [messagesUnique removeObject:messageOld];
                else
                    bSuchUserAlreadyAdded = true;
                
                // Updating new messages count
                if ( bNewLaterThanReadDate && ! bOwnMessage )
                {
                    NSNumber* count = [unreadCounts objectForKey:message.strUserFrom];
                    if ( ! count )
                        count = [NSNumber numberWithInt:1];
                    else
                        count = [NSNumber numberWithInt:[count integerValue]+1];
                    [unreadCounts setObject:count forKey:message.strUserFrom];
                }
                
                break;
            }
        
        // Adding object
        if ( ! bSuchUserAlreadyAdded )
            [messagesUnique addObject:message];
    }
    
    // Unread counts
    for ( NSString* user in [unreadCounts allKeys] )
    {
        NSNumber* count = [unreadCounts objectForKey:user];
        Person* person = [globalData getPersonById:user];
        person.numUnreadMessages = [count integerValue];
    }
    
    return messagesUnique;
}

- (void)loadMessages
{
    // Query
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"idUserTo = %@ OR idUserFrom = %@", strCurrentUserId, strCurrentUserId];
    PFQuery *messagesQuery = [PFQuery queryWithClassName:@"Message" predicate:predicate];
    [messagesQuery orderByDescending:@"createdAt"];
    messagesQuery.limit = 500;
    
    // Loading
    [messagesQuery findObjectsInBackgroundWithBlock:^(NSArray *result, NSError *error) {
        
        if ( error )
        {
            NSLog(@"Uh oh. An error occurred: %@", error);
            [self loadingFailed:LOADING_INBOX status:LOAD_NOCONNECTION];
        }
        else
        {
            messages = [NSMutableArray arrayWithCapacity:30];
            
            // Welcome message
            if ( ! [globalVariables isFeedbackBot:strCurrentUserId] )
            {
                Message* welcomeMessage = [[Message alloc] initWithWelcomeMessage];
                [self addMessage:welcomeMessage];
            }
            
            // Loading it with data
            for ( PFObject* messageData in result )
                [self addMessageWithData:messageData];
            
            // Loading stage complete
            [self incrementInboxLoadingStage];
        }
    }];
    
    // TODO: add check for paging and paging itself if result count == limit
}

- (void)loadMessageThread:(Person*)person target:(id)target selector:(SEL)callback
{
    if ( ! person || ! person.strId )
    {
        // TODO: temporary logs
        if ( ! person )
            TFLog( @"Null person!" );
        else
            TFLog( @"Null person id!" );
        return;
    }
    
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"idUserTo = %@ AND idUserFrom = %@ OR idUserTo = %@ AND idUserFrom = %@", strCurrentUserId, person.strId, person.strId, strCurrentUserId];
    PFQuery *messageQuery = [PFQuery queryWithClassName:@"Message" predicate:predicate];
    messageQuery.limit = 1000;
    [messageQuery orderByAscending:@"createdAt"];
    
    [messageQuery findObjectsInBackgroundWithBlock:^(NSArray *result, NSError* error) {
        
        // Loading it with data
        NSMutableArray* messageThread = [NSMutableArray arrayWithCapacity:30];
        for ( PFObject* messageData in result )
        {
            Message* message = [[Message alloc] init];
            [message unpack:messageData];
            [messageThread addObject:message];
        }
        [target performSelector:callback withObject:messageThread withObject:error];
        
        // Last read message date/count
        NSNumber* count = result ? [NSNumber numberWithInteger:messageThread.count] : [NSNumber numberWithInteger:0];
        NSDate* date = count.integerValue > 0 ? ((Message*)[messageThread lastObject]).dateCreated : nil;
        if ( ! date && [globalVariables isFeedbackBot:person.strId] )
        {
            date = [NSDate date];   // Feedback bot hack to make his default message read
            count = nil;            // But not to count him as opened profile, etc
        }
        [globalData updateConversation:date count:count thread:person.strId meetup:FALSE];
        if ( count > 0 )
            [globalData postInboxUnreadCountDidUpdate];
    }];
}

-(void)createMessage:(NSString*)strText person:(Person*)personTo target:(id)target selector:(SEL)callback
{
    // Adding message with callback on save
    Message* message = [[Message alloc] init];
    message.strUserFrom = strCurrentUserId;
    message.strUserTo = personTo.strId;
    message.strText = strText;
    message.objUserFrom = [PFUser currentUser];
    message.objUserTo = personTo.personData;
    message.strNameUserFrom = [globalVariables fullUserName];
    message.strNameUserTo = [personTo fullName];
    [message save:target selector:callback];
}

@end