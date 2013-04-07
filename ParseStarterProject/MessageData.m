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
    
    for (Message *message in messages)
    {
        // Looking for already created thread
        Boolean bSuchUserAlreadyAdded = false;
        for (Message *messageOld in messagesUnique)
            if ( ( [message.strUserFrom compare:messageOld.strUserFrom] == NSOrderedSame ) ||
                ( [message.strUserTo compare:messageOld.strUserTo] == NSOrderedSame ) ||
                ( [message.strUserFrom compare:messageOld.strUserTo ] == NSOrderedSame) )
            {
                // Replacing with an older unread:
                // checking date, if it's > than last read, but < than current, replace
                
                Boolean bExchange = false;
                
                Boolean bOwnMessage = ( [message.strUserFrom compare:strCurrentUserId] == NSOrderedSame );
                Boolean bOldOwnMessage = ( [messageOld.strUserFrom compare:strCurrentUserId] == NSOrderedSame );
                
                NSDate* lastReadDate;
                if ( bOwnMessage )
                    lastReadDate = [self getConversationDate:message.strUserTo];
                else
                    lastReadDate = [self getConversationDate:message.strUserFrom];
                
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
    
    for ( NSString* user in [unreadCounts allKeys] )
    {
        NSNumber* count = [unreadCounts objectForKey:user];
        Person* person = [globalData getPersonById:user];
        person.numUnreadMessages = [count integerValue];
    }
    
    return messagesUnique;
}

- (void)loadMessages:(InboxViewController*)controller
{
    // Query
    PFQuery *messagesQuery = [PFQuery queryWithClassName:@"Message"];
    [messagesQuery whereKey:@"idUserTo" equalTo:[[PFUser currentUser] objectForKey:@"fbId"]];
    
    // Loading
    [messagesQuery findObjectsInBackgroundWithBlock:^(NSArray *objects1, NSError *error) {
        
        PFQuery *messagesQuery = [PFQuery queryWithClassName:@"Message"];
        [messagesQuery whereKey:@"idUserFrom" equalTo:[[PFUser currentUser] objectForKey:@"fbId"]];
        
        [messagesQuery findObjectsInBackgroundWithBlock:^(NSArray *objects2, NSError *error) {
            
            // Merging results
            NSMutableSet *set = [NSMutableSet setWithArray:objects1];
            [set addObjectsFromArray:objects2];
            
            // Creating array
            messages = [[NSMutableArray alloc] init];
            
            // Loading it with data
            for ( PFObject* messageData in [set allObjects] )
                [self addMessageWithData:messageData];
            
            // Loading stage complete
            [self incrementLoadingStage:controller];
        }];
    }];
}

NSInteger sort(id message1, id message2, void *context)
{
    //    NSString* strDate1 = [message1 objectForKey:@"createdAt"];
    //    NSString* strDate2 = [message2 objectForKey:@"createdAt"];
    
    //    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    //    [dateFormatter setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
    PFObject* mes1 = message1;
    PFObject* mes2 = message2;
    NSDate *date1 = mes1.createdAt;//[dateFormatter dateFromString:strDate1 ];
    NSDate *date2 = mes2.createdAt;//[dateFormatter dateFromString:strDate2 ];
    
    if ([date2 compare:date1] == NSOrderedDescending)
        return NSOrderedDescending;
    
    return NSOrderedAscending;
}

- (void)loadThread:(Person*)person target:(id)target selector:(SEL)callback
{
    PFQuery *messageQuery1 = [PFQuery queryWithClassName:@"Message"];
    [messageQuery1 whereKey:@"idUserFrom" equalTo:strCurrentUserId ];
    [messageQuery1 whereKey:@"idUserTo" equalTo:person.strId ];
    
    PFQuery *messageQuery2 = [PFQuery queryWithClassName:@"Message"];
    [messageQuery2 whereKey:@"idUserFrom" equalTo:person.strId ];
    [messageQuery2 whereKey:@"idUserTo" equalTo:strCurrentUserId ];
    
    [messageQuery1 findObjectsInBackgroundWithBlock:^(NSArray *messages1, NSError* error) {
        [messageQuery2 findObjectsInBackgroundWithBlock:^(NSArray *messages2, NSError* error) {
            
            NSMutableSet *set = [NSMutableSet setWithArray:messages1];
            [set addObjectsFromArray:messages2];
            NSArray *array = [set allObjects];
            NSArray *sortedArray = [array sortedArrayUsingFunction:sort context:NULL];
            
            [target performSelector:callback withObject:sortedArray];
            
            // Last read message date
            if ( [sortedArray count] > 0 )
                [globalData updateConversation:((PFObject*)sortedArray[0]).createdAt count:[sortedArray count] thread:person.strId];
        }];
    }];
}


@end