//
//  PushManager.m
//  SecondCircle
//
//  Created by Mikhail Larionov on 2/3/13.
//
//

#import "PushManager.h"
#import <Parse/Parse.h>
#import "GlobalData.h"

@implementation PushManager

static PushManager *sharedInstance = nil;

+ (PushManager *)sharedInstance {
    if (sharedInstance == nil) {
        sharedInstance = [[super allocWithZone:NULL] init];
    }
    
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    
    if (self) {
        newUserPushesSent = [NSMutableArray arrayWithCapacity:30];
    }
    
    return self;
}

- (void)sendPushNewUser:(NSInteger)pushType idsTo:(NSArray*)to
{
    Boolean bShouldSendPushToFriends = [globalVariables shouldSendPushToFriends];
    if ( ! bShouldSendPushToFriends )
        return;
    
    NSMutableArray* ids = [NSMutableArray arrayWithArray:to];
    [ids removeObject:strCurrentUserId];
    [ids removeObjectsInArray:newUserPushesSent];
    
    if ( ids.count == 0 )
        return;
    
    NSString* strName = [globalVariables fullUserName];
    NSString* strPush = @"Wrong push! Error codename: Cleopatra.";
    NSString* strChannel = @"Wrong channel";
    switch (pushType)
    {
        case PUSH_NEW_FBFRIEND:
            strPush = [[NSString alloc] initWithFormat:NSLocalizedString(@"PUSH_NEW_FRIEND",nil), strName];
            strChannel = @"newFbFriend";
            break;
        case PUSH_NEW_2OFRIEND:
            strPush = [[NSString alloc] initWithFormat:NSLocalizedString(@"PUSH_NEW_2OFRIEND",nil), strName];
            strChannel = @"new2OFriend";
            break;
    }
    
    PFQuery *pushQuery = [PFInstallation query];
    [pushQuery whereKey:@"ownerId" containedIn:ids];
    
    NSDictionary* data = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"New friend!",   @"title",
                          strPush,          @"alert",
                          strCurrentUserId, @"user",
                          @"Increment",     @"badge",
                          nil];
    
    PFPush *push = [[PFPush alloc] init];
    
    [push setQuery:pushQuery];
    [push setChannel:strChannel];
    [push setData:data];
    [push sendPushInBackground];
    
    [newUserPushesSent addObjectsFromArray:ids];
}

- (void)sendPushNewMessage:(NSString*)userId text:(NSString*)strText
{
    NSString* strMessageChannel =[[NSString alloc] initWithFormat:@"fb%@_message", userId];
    NSString* strPush = [NSString stringWithFormat:@"%@: %@", [globalVariables shortUserName], strText];
    NSDictionary* data = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"New message!",  @"title",
                          strPush,          @"alert",
                          userId,           @"user",
                          @"Increment",     @"badge",
                          nil];
    
    PFPush *push = [[PFPush alloc] init];
    [push setChannel:strMessageChannel];
    [push setData:data];
    [push sendPushInBackground];
}


- (void)sendPushAttendingMeetup:(NSString*)meetupId
{
    Meetup* meetup = [globalData getMeetupById:meetupId];
    if ( ! meetup )
        return;
    
    // Excluding the case where you just created it
    if ( [meetup.strOwnerId compare:strCurrentUserId] == NSOrderedSame )
        return;
    
    PFQuery *pushQuery = [PFInstallation query];
    [pushQuery whereKey:@"ownerId" containedIn:meetup.attendees];
    [pushQuery whereKey:@"ownerId" notEqualTo:strCurrentUserId];
    
    NSString* strText = [NSString stringWithFormat:@"%@ joined meetup %@", [globalVariables shortUserName], meetup.strSubject];
    
    PFPush *push = [[PFPush alloc] init];
    
    NSDictionary* data = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"New attendee!", @"title",
                          strText,          @"alert",
                          meetupId,         @"meetup",
                          @"Increment",     @"badge",
                          nil];
    
    [push setQuery:pushQuery];
    [push setChannel:@"newJoin"];
    [push setData:data];
    [push sendPushInBackground];
}

- (void)sendPushLeftMeetup:(NSString*)meetupId
{
    Meetup* meetup = [globalData getMeetupById:meetupId];
    if ( ! meetup )
        return;
    
    PFQuery *pushQuery = [PFInstallation query];
    [pushQuery whereKey:@"ownerId" containedIn:meetup.attendees];
    [pushQuery whereKey:@"ownerId" notEqualTo:strCurrentUserId];
    
    NSString* strText = [NSString stringWithFormat:@"%@ left meetup %@", [globalVariables shortUserName], meetup.strSubject];
    
    PFPush *push = [[PFPush alloc] init];
    
    NSDictionary* data = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"Attendee left", @"title",
                          strText,          @"alert",
                          meetupId,         @"meetup",
                          @"Increment",     @"badge",
                          nil];
    
    [push setQuery:pushQuery];
    [push setChannel:@"newJoin"];
    [push setData:data];
    [push sendPushInBackground];
}

- (void)sendPushCanceledMeetup:(NSString*)meetupId
{
    Meetup* meetup = [globalData getMeetupById:meetupId];
    if ( ! meetup )
        return;
    
    PFQuery *pushQuery = [PFInstallation query];
    [pushQuery whereKey:@"ownerId" containedIn:meetup.attendees];
    [pushQuery whereKey:@"ownerId" notEqualTo:strCurrentUserId];
    
    NSString* strText = [NSString stringWithFormat:@"%@ canceled meetup %@", [globalVariables shortUserName], meetup.strSubject];
    
    PFPush *push = [[PFPush alloc] init];
    
    NSDictionary* data = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"Meetup canceled!", @"title",
                          strText,             @"alert",
                          meetupId,            @"meetup",
                          @"Increment",        @"badge",
                          nil];
    
    [push setQuery:pushQuery];
    [push setChannel:@""];  // These messages shouldn't be blocked as they are very important
    [push setData:data];
    [push sendPushInBackground];
}

- (void)sendPushCommentedMeetup:(NSString*)meetupId
{
    Meetup* meetup = [globalData getMeetupById:meetupId];
    if ( ! meetup )
        return;
    
    PFQuery *pushQuery = [PFInstallation query];
    [pushQuery whereKey:@"ownerId" containedIn:meetup.attendees];
    [pushQuery whereKey:@"ownerId" notEqualTo:strCurrentUserId];
    
    NSString* strText = [NSString stringWithFormat:@"%@ left a comment in %@", [globalVariables shortUserName], meetup.strSubject];
    
    PFPush *push = [[PFPush alloc] init];
    [push setQuery:pushQuery];
    NSDictionary* data = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"New comment!",  @"title",
                          strText,          @"alert",
                          meetupId,         @"meetup",
                          @"Increment",     @"badge",
                          nil];
    [push setChannel:@"newComment"];
    [push setData:data];
    [push sendPushInBackground];
}

- (void)sendPushInviteForMeetup:(NSString*)meetupId user:(NSString*)userId
{
    Meetup* meetup = [globalData getMeetupById:meetupId];
    if ( ! meetup )
        return;
    
    NSString* strInviteChannel =[NSString stringWithFormat:@"fb%@_invite", userId];
    NSString* strText = [NSString stringWithFormat:@"%@ invited you to %@", [globalVariables shortUserName], meetup.strSubject];
    NSDictionary* data = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"New comment!",  @"title",
                          strText,          @"alert",
                          meetupId,         @"meetup",
                          @"Increment",     @"badge",
                          nil];
    
    PFPush *push = [[PFPush alloc] init];
    [push setChannel:strInviteChannel];
    [push setData:data];
    [push sendPushInBackground];
}

- (void)sendPushCreatedMeetup:(NSString*)meetupId ignore:(NSArray*)ignoreList
{
    Meetup* meetup = [globalData getMeetupById:meetupId];
    if ( ! meetup )
        return;
    
    NSMutableArray* ignoreIds = [[NSMutableArray alloc] initWithObjects:strCurrentUserId, nil];
    if ( ignoreList )
        for ( Person* person in ignoreList )
            [ignoreIds addObject:person.strId];
    
    PFQuery *userQuery = [PFUser query];
    userQuery.limit = 1000;
    [userQuery whereKey:@"fbId" notContainedIn:ignoreIds];
    [userQuery whereKey:@"location" nearGeoPoint:meetup.location withinKilometers:PUSH_DISCOVERY_KILOMETERS];
    
    PFQuery *pushQuery = [PFInstallation query];
    [pushQuery whereKey:@"ownerData" matchesQuery:userQuery];
    
    NSString* strText;
    NSString* strTitle;
    if ( meetup.meetupType == TYPE_MEETUP )
    {
        strText = [NSString stringWithFormat:@"%@ just created a meetup nearby: %@", [globalVariables shortUserName], meetup.strSubject];
        strTitle = @"New meetup!";
    }
    else
    {
        strText = [NSString stringWithFormat:@"%@ just created a thread nearby: %@", [globalVariables shortUserName], meetup.strSubject];
        strTitle = @"New thread!";
    }
    
    PFPush *push = [[PFPush alloc] init];
    [push setQuery:pushQuery];
    NSDictionary* data = [NSDictionary dictionaryWithObjectsAndKeys:
                          strTitle,         @"title",
                          strText,          @"alert",
                          meetupId,         @"meetup",
    //                      @"Increment",     @"badge", // Don't increment as not inbox event
                          nil];
    [push setChannel:@"newMeetupNearby"];
    [push setData:data];
    [push expireAfterTimeInterval:PUSH_DISCOVERY_EXPIRATION];
    [push sendPushInBackground];
}

- (void)initChannels
{
    //NSString* strUserChannel =[[NSString alloc] initWithFormat:@"fb%@", strId];
    NSString* strMessageChannel =[[NSString alloc] initWithFormat:@"fb%@_message", strCurrentUserId];
    NSString* strInviteChannel =[[NSString alloc] initWithFormat:@"fb%@_invite", strCurrentUserId];
    
    //[[PFInstallation currentInstallation] addUniqueObject:strUserChannel forKey:@"channels"];
    [[PFInstallation currentInstallation] addUniqueObject:@"" forKey:@"channels"];
    [[PFInstallation currentInstallation] addUniqueObject:@"newFbFriend" forKey:@"channels"];
    [[PFInstallation currentInstallation] addUniqueObject:@"new2OFriend" forKey:@"channels"];
    [[PFInstallation currentInstallation] addUniqueObject:strMessageChannel forKey:@"channels"];
    [[PFInstallation currentInstallation] addUniqueObject:strInviteChannel forKey:@"channels"];
    [[PFInstallation currentInstallation] addUniqueObject:@"newJoin" forKey:@"channels"];
    [[PFInstallation currentInstallation] addUniqueObject:@"newComment" forKey:@"channels"];
    [[PFInstallation currentInstallation] addUniqueObject:@"newMeetupNearby" forKey:@"channels"];
    
    [[PFInstallation currentInstallation] setObject:strCurrentUserId forKey:@"ownerId"];
    [[PFInstallation currentInstallation] setObject:pCurrentUser forKey:@"ownerData"];
    [[PFInstallation currentInstallation] saveInBackground];
    
    //[PFPush subscribeToChannelInBackground:strUserChannel target:self selector:@selector(subscribeFinished:error:)];
    [PFPush subscribeToChannelInBackground:@"" target:self selector:@selector(subscribeFinished:error:)];
    [PFPush subscribeToChannelInBackground:@"newFbFriend" target:self selector:@selector(subscribeFinished:error:)];
    [PFPush subscribeToChannelInBackground:@"new2OFriend" target:self selector:@selector(subscribeFinished:error:)];
    [PFPush subscribeToChannelInBackground:strMessageChannel target:self selector:@selector(subscribeFinished:error:)];
    [PFPush subscribeToChannelInBackground:strInviteChannel target:self selector:@selector(subscribeFinished:error:)];
    [PFPush subscribeToChannelInBackground:@"newJoin" target:self selector:@selector(subscribeFinished:error:)];
    [PFPush subscribeToChannelInBackground:@"newComment" target:self selector:@selector(subscribeFinished:error:)];
    [PFPush subscribeToChannelInBackground:@"newMeetupNearby" target:self selector:@selector(subscribeFinished:error:)];
}

- (void)logout
{
    NSString* strMessageChannel =[[NSString alloc] initWithFormat:@"fb%@_message", strCurrentUserId];
    NSString* strInviteChannel =[[NSString alloc] initWithFormat:@"fb%@_invite", strCurrentUserId];
    
    [PFPush unsubscribeFromChannelInBackground:@""];
    [PFPush unsubscribeFromChannelInBackground:@"newFbFriend"];
    [PFPush unsubscribeFromChannelInBackground:@"new2OFriend"];
    [PFPush unsubscribeFromChannelInBackground:strMessageChannel];
    [PFPush unsubscribeFromChannelInBackground:strInviteChannel];
    [PFPush unsubscribeFromChannelInBackground:@"newJoin"];
    [PFPush unsubscribeFromChannelInBackground:@"newComment"];
    [PFPush unsubscribeFromChannelInBackground:@"newMeetupNearby"];
}

- (void)addChannels:(NSArray*)channels
{
    [[PFInstallation currentInstallation] addUniqueObjectsFromArray:channels forKey:@"channels"];
    [[PFInstallation currentInstallation] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (error)
            NSLog(@"Parse installation save (during push add channel) failed with error: %@", error);
    }];
    for ( NSString* strChannel in channels )
        [PFPush subscribeToChannelInBackground:strChannel target:self selector:@selector(subscribeFinished:error:)];
}

- (void)removeChannels:(NSArray*)channels
{
    [[PFInstallation currentInstallation] removeObjectsInArray:channels forKey:@"channels"];
    [[PFInstallation currentInstallation] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (error)
            NSLog(@"Parse installation save (during push remove channel) failed with error: %@", error);
    }];
    for ( NSString* strChannel in channels )
        [PFPush unsubscribeFromChannelInBackground:strChannel];
}

- (void)subscribeFinished:(NSNumber *)result error:(NSError *)error {
    if ([result boolValue]) {
        NSLog(@"ParseStarterProject successfully subscribed to push notifications on the broadcast channel.");
    } else {
        NSLog(@"ParseStarterProject failed to subscribe to push notifications on the broadcast channel.");
    }
}

@end