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
        
    messageData = [[PFObject alloc] initWithClassName:@"Message"];

    [messageData setObject:strUserFrom forKey:@"idUserFrom"];
    [messageData setObject:strUserTo forKey:@"idUserTo"];
    [messageData setObject:strText forKey:@"text"];
    [messageData setObject:objUserFrom forKey:@"objUserFrom"];
    [messageData setObject:objUserTo forKey:@"objUserTo"];
    [messageData setObject:strNameUserFrom forKey:@"nameUserFrom"];
    [messageData setObject:strNameUserTo forKey:@"nameUserTo"];
    
    dateCreated = [NSDate date];
    
    // Protection (read only for both, write for nobody owner)
    //meetupData.ACL = [PFACL ACLWithUser:[PFUser currentUser]];
    //[meetupData.ACL setPublicReadAccess:true];
    
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

-(void) fetchUserIfNeeded
{
    NSError* error;
    if ( [strUserFrom compare:strCurrentUserId] == NSOrderedSame )
        [objUserTo fetchIfNeeded:&error];
    else
        [objUserFrom fetchIfNeeded:&error];
}

@end