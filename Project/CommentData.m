//
//  CommentData.c
//  Fuge
//
//  Created by Mikhail Larionov on 7/22/13.
//
//

#import "GlobalData.h"
#import "GlobalVariables.h"
#import "Message.h"
#import "TestFlight.h"
#import "PushManager.h"

@implementation GlobalData (Comments)

- (void)addComment:(Comment*)comment
{
    [comments addObject:comment];
}

- (void)addCommentWithData:(PFObject*)commentData
{
    Comment* comment = [[Comment alloc] init];
    [comment unpack:commentData];
    [comments addObject:comment];
}

- (NSArray*)getUniqueThreads
{
    NSMutableArray *threadsUnique = [[NSMutableArray alloc] init];
    Person* current = currentPerson;
    for (Comment *comment in comments)
    {
        // Looking for already created thread
        Boolean bSuchThreadAlreadyAdded = false;
        for (Comment *commentOld in threadsUnique)
            if ( [comment.strMeetupId compare:commentOld.strMeetupId] == NSOrderedSame )
            {
                // Replacing with an older unread:
                // checking date, if it's > than last read, but < than current, replace
                
                Boolean bExchange = false;
                
                Boolean bOwnMessage = ( [comment.strUserFrom compare:strCurrentUserId] == NSOrderedSame );
                Boolean bOldOwnMessage = ( [commentOld.strUserFrom compare:strCurrentUserId] == NSOrderedSame );
                
                NSDate* lastReadDate = [current getConversationDate:comment.strMeetupId meetup:TRUE];
                
                Boolean bOldBeforeThanReadDate = false;
                Boolean bNewLaterThanReadDate = true;
                Boolean bNewIsBeforeOld = false;

                bNewIsBeforeOld = ( [ comment.dateCreated compare:commentOld.dateCreated ] == NSOrderedAscending );
                if ( lastReadDate )
                {
                    bOldBeforeThanReadDate = [commentOld.dateCreated compare:lastReadDate] != NSOrderedDescending;
                    bNewLaterThanReadDate = [comment.dateCreated compare:lastReadDate] == NSOrderedDescending;
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
    messagesQuery.limit = 1000;
    [messagesQuery orderByDescending:@"createdAt"];
    //[messagesQuery whereKey:@"system" notEqualTo:[NSNumber numberWithInt:1]];
    
    // TODO: add here later another query limitation by date (like 10 last days) to not push server too hard. It will be like pages, loading every 10 previous days or so.
    
    // Loading
    [messagesQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        if ( error )
        {
            NSLog(@"Uh oh. An error occurred: %@", error);
            [self loadingFailed:LOADING_INBOX status:LOAD_NOCONNECTION];
        }
        else
        {
            // Comments
            comments = [NSMutableArray arrayWithCapacity:30];
            
            // Loading it with data
            for ( PFObject* commentData in objects )
                [self addCommentWithData:commentData];
            
            // Loading stage complete
            [self incrementInboxLoadingStage];
        }
    }];
}

- (void)loadCommentThread:(Meetup*)meetup target:(id)target selector:(SEL)callback
{
    PFQuery *commentsQuery = [PFQuery queryWithClassName:@"Comment"];
    commentsQuery.limit = 1000;
    [commentsQuery whereKey:@"meetupId" equalTo:meetup.strId];
    [commentsQuery orderByAscending:@"createdAt"];
    
    [commentsQuery findObjectsInBackgroundWithBlock:^(NSArray *result, NSError* error) {
        
        NSMutableArray* threadComments = [NSMutableArray arrayWithCapacity:30];
        for ( PFObject* commentData in result )
        {
            Comment* comment = [[Comment alloc] init];
            [comment unpack:commentData];
            [threadComments addObject:comment];
        }
        if ( threadComments.count > 0 )
            [self addComment:[threadComments lastObject]];
        
        [target performSelector:callback withObject:threadComments withObject:error];
        
        // Last read message date
        NSDate* commentDate = nil;
        if ( threadComments.count > 0 )
            commentDate = ((Comment*)[threadComments lastObject]).dateCreated;
        [globalData updateConversation:commentDate count:[NSNumber numberWithInteger:meetup.numComments] thread:meetup.strId meetup:TRUE];
    }];
}

-(void)createCommentForMeetup:(Meetup*)meetup commentType:(CommentType)type commentText:(NSString*)text
{
    // Creating comment about meetup creation in db
    Comment* comment = [[Comment alloc] init];
    NSMutableString* strComment = [NSMutableString stringWithFormat:@""];
    NSNumber* typeNum = [NSNumber numberWithInt:meetup.meetupType];
    
    switch (type)
    {
        case COMMENT_CREATED:
            [strComment appendString:[globalVariables fullUserName]];
            if (meetup.meetupType == TYPE_MEETUP)
                [strComment appendString:@" created the meetup: "];
            else
                [strComment appendString:@" created the thread: "];
            [strComment appendString:meetup.strSubject];
            break;
        case COMMENT_SAVED:
            [strComment appendString:[globalVariables fullUserName]];
            if (meetup.meetupType == TYPE_MEETUP)
                [strComment appendString:text];
            else
                [strComment appendString:text];
            break;
        case COMMENT_JOINED:
            [strComment appendString:[globalVariables fullUserName]];
            [strComment appendString:@" joined the meetup."];
            break;
        case COMMENT_LEFT:
            [strComment appendString:[globalVariables fullUserName]];
            [strComment appendString:@" has left the meetup."];
            break;
        case COMMENT_CANCELED:
            [strComment appendString:[globalVariables fullUserName]];
            [strComment appendString:@" canceled the meetup!"];
            break;
        case COMMENT_PLAIN:
            [strComment appendString:text];
            meetup.numComments++;
            [globalData updateConversation:nil count:[NSNumber numberWithInteger:meetup.numComments] thread:meetup.strId meetup:TRUE];
            break;
    }
    
    comment.systemType = [NSNumber numberWithInt:type];
    comment.strUserFrom = strCurrentUserId;
    comment.strNameUserFrom = [globalVariables fullUserName];
    comment.objUserFrom = pCurrentUser;
    comment.strMeetupSubject = meetup.strSubject;
    comment.strMeetupId = meetup.strId;
    comment.meetupData = meetup.meetupData;
    comment.strComment = strComment;
    comment.typeNum = typeNum;
    [comment save];
    
    // Add comment to the list of threads
    [self addComment:comment];
    
    // Subscription
    [globalData subscribeToThread:meetup.strId];
    
    // Send push for normal comment
    if ( type == COMMENT_PLAIN )
        [pushManager sendPushCommentedMeetup:meetup.strId];
}


@end