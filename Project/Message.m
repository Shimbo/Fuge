//
//  Message.m
//  SecondCircle
//
//  Created by Mikhail Larionov on 3/31/13.
//
//

#import "Message.h"
#import "GlobalData.h"
#import "PushManager.h"

@implementation Message

@synthesize strUserFrom,strUserTo,strText,objUserTo,objUserFrom,strNameUserFrom,strNameUserTo,dateCreated;

-(id) init
{
    if (self = [super init]) {
        messageData = nil;
    }
    
    return self;
}

-(id) initWithWelcomeMessage
{
    if (self = [self init]) {
        
        dateCreated = pCurrentUser.createdAt;
        
        strUserFrom = FEEDBACK_BOT_ID;
        strUserTo = strCurrentUserId;
        strText = WELCOME_MESSAGE;
        objUserFrom = [PFUser objectWithoutDataWithObjectId:FEEDBACK_BOT_OBJECT];
        objUserTo = pCurrentUser;
        strNameUserFrom = @"Peter S.";
        strNameUserTo = @"Unknown";
    }
    
    return self;
}

- (void) save:(id)target selector:(SEL)selector
{
    // Already saved
    if ( messageData )
        return;
    
    messageData = [PFObject objectWithClassName:@"Message"];
    
    PFACL* messageACL = [PFACL ACLWithUser:pCurrentUser];
    [messageACL setReadAccess:TRUE forUser:objUserTo];
    [messageACL setReadAccess:TRUE forRoleWithName:@"Moderator"];
    [messageACL setWriteAccess:TRUE forRoleWithName:@"Moderator"];
    [messageData setACL:messageACL];
    
    [messageData setObject:strUserFrom forKey:@"idUserFrom"];
    [messageData setObject:strUserTo forKey:@"idUserTo"];
    [messageData setObject:strText forKey:@"text"];
    [messageData setObject:objUserFrom forKey:@"objUserFrom"];
    [messageData setObject:objUserTo forKey:@"objUserTo"];
    [messageData setObject:strNameUserFrom forKey:@"nameUserFrom"];
    [messageData setObject:strNameUserTo forKey:@"nameUserTo"];
    
    [messageData saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        
        if ( error )
        {
            NSLog( @"Message saving failed: %@", error );
        }
        else
        {
            dateCreated = messageData.createdAt;
            
            // Adding to inbox
            [globalData addMessage:self];
            
            // Sending push
            [pushManager sendPushNewMessage:strUserTo text:strText];
            
            // Update inbox
            [[NSNotificationCenter defaultCenter]postNotificationName:kInboxUpdated object:nil];
        }
        
        if ( target )
            [target performSelector:selector withObject:(error?nil:self)];
    }];
}

-(void) unpack:(PFObject*)data
{
    messageData = data;
    
    dateCreated = messageData.createdAt;
    
    strUserFrom = [messageData objectForKey:@"idUserFrom"];
    strUserTo = [messageData objectForKey:@"idUserTo"];
    strText = [messageData objectForKey:@"text"];
    objUserFrom = [messageData objectForKey:@"objUserFrom"];
    objUserTo = [messageData objectForKey:@"objUserTo"];
    strNameUserFrom = [messageData objectForKey:@"nameUserFrom"];
    strNameUserTo = [messageData objectForKey:@"nameUserTo"];
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