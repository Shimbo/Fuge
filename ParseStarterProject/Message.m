//
//  Message.m
//  SecondCircle
//
//  Created by Mikhail Larionov on 3/31/13.
//
//

#import "Message.h"
#import "GlobalData.h"

@implementation Message

@synthesize strUserFrom,strUserTo,strText,objUserTo,objUserFrom,strNameUserFrom,strNameUserTo,dateCreated;

-(id) init
{
    if (self = [super init]) {
        messageData = nil;
    }
    
    return self;
}

- (void) save:(id)t selector:(SEL)s
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
    
    dateCreated = [NSDate date];
    
    [messageData saveInBackgroundWithTarget:t selector:s];
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

@end