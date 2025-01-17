//
//  Comment.m
//  Fuge
//
//  Created by Mikhail Larionov on 7/22/13.
//
//

#import "Comment.h"
#import "GlobalData.h"
#import "PushManager.h"

@implementation Comment

@synthesize strUserFrom,strNameUserFrom,objUserFrom,strComment,strMeetupSubject,dateCreated,meetupData,systemType,strMeetupId, typeNum;

-(id) init
{
    if (self = [super init]) {
        commentData = nil;
    }
    
    return self;
}

- (void) save:(id)target selector:(SEL)callback;
{
    // Already saved
    if ( commentData )
        return;
    
    commentData = [PFObject objectWithClassName:@"Comment"];
    
    [commentData setObject:strUserFrom forKey:@"userId"];
    [commentData setObject:strNameUserFrom forKey:@"userName"];
    [commentData setObject:objUserFrom forKey:@"userData"];
    
    [commentData setObject:strComment forKey:@"comment"];
    [commentData setObject:systemType forKey:@"system"];
    
    [commentData setObject:strMeetupId forKey:@"meetupId"];
    [commentData setObject:strMeetupSubject forKey:@"meetupSubject"];
    if ( meetupData )
        [commentData setObject:meetupData forKey:@"meetupData"];
    [commentData setObject:typeNum forKey:@"type"];
    
    dateCreated = [NSDate date];
    
    [commentData saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if ( error )
        {
            NSLog( @"Comment saving failed: %@", error );
        }
        else
        {
            dateCreated = commentData.createdAt;
            
            // Add comment to the list of threads
            [globalData addComment:self];
            
            // Send push for normal comment
            if ( [systemType integerValue] == COMMENT_PLAIN )
                [pushManager sendPushCommentedMeetup:strMeetupId];
            
            // Subscription
            [globalData subscribeToThread:strMeetupId];
            
            // Conversation
            if ( [typeNum integerValue] != COMMENT_PLAIN )
                [globalData updateConversation:dateCreated count:nil thread:strMeetupId meetup:TRUE];
            
            // Update inbox
            [[NSNotificationCenter defaultCenter]postNotificationName:kInboxUpdated object:nil];
        }
        
        if ( target )
            [target performSelector:callback withObject:(error?nil:self)];
    }];
}

-(void) unpack:(PFObject*)data
{
    commentData = data;
    
    dateCreated = commentData.createdAt;
    
    strUserFrom = [commentData objectForKey:@"userId"];
    strNameUserFrom = [commentData objectForKey:@"userName"];
    objUserFrom = [commentData objectForKey:@"userData"];
    
    strComment = [commentData objectForKey:@"comment"];
    systemType = [commentData objectForKey:@"system"];
    
    strMeetupId = [commentData objectForKey:@"meetupId"];
    strMeetupSubject = [commentData objectForKey:@"meetupSubject"];
    meetupData = [commentData objectForKey:@"meetupData"];
    typeNum = [commentData objectForKey:@"type"];
}

-(Person*) owner
{
    return [globalData getPersonById:strUserFrom];
}

-(Boolean) isOwn
{
    return [strUserFrom compare:strCurrentUserId] == NSOrderedSame;
}

@end