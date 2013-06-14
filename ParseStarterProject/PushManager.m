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
        dicNewUserPushesSent = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (void)sendPushNewUser:(NSInteger)pushType idTo:(NSString*)strTo
{
    Boolean bShouldSendPushToFriends = [globalVariables shouldSendPushToFriends];
    if ( ! bShouldSendPushToFriends )
        return;
    
    if ( [strTo compare:[[PFUser currentUser] objectForKey:@"fbId"]] == NSOrderedSame )
        return;
    
    if ( [dicNewUserPushesSent objectForKey:strTo] )
        return;
    
    NSString* strName = [globalVariables fullUserName];
    NSString* strPush = @"Wrong push! Error codename: Cleopatra.";
    switch (pushType)
    {
        case PUSH_NEW_FBFRIEND:
            strPush = [[NSString alloc] initWithFormat:@"Woohoo! Your Facebook friend %@ joined Second Circle! Check if you've got new connections!", strName];
            break;
        case PUSH_NEW_2OFRIEND:
            strPush = [[NSString alloc] initWithFormat:@"Hurray! Your 2ndO friend %@ joined Second Circle!", strName];
            break;
    }
    
    NSString* strChannel = [NSString stringWithFormat:@"fb%@", strTo];
    NSDictionary* data = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"New friend!",   @"title",
                          strPush,          @"alert",
                          strCurrentUserId, @"user",
                          @"Increment",     @"badge",
                          nil];
    
    PFPush *push = [[PFPush alloc] init];
    [push setChannel:strChannel];
    [push setData:data];
    [push sendPushInBackground];
    
    [dicNewUserPushesSent setObject:@"Sent" forKey:strTo];
}

- (void)sendPushNewMessage:(NSString*)userId text:(NSString*)strText
{
    NSString* strChannel = [NSString stringWithFormat:@"fb%@", userId];
    NSString* strPush = [NSString stringWithFormat:@"%@: %@", [globalVariables shortUserName], strText];
    NSDictionary* data = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"New message!",  @"title",
                          strPush,          @"alert",
                          userId,           @"user",
                          @"Increment",     @"badge",
                          nil];
    
    PFPush *push = [[PFPush alloc] init];
    [push setChannel:strChannel];
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
    [push setQuery:pushQuery];
    NSDictionary* data = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"New attendee!", @"title",
                          strText,          @"alert",
                          meetupId,         @"meetup",
                          @"Increment",     @"badge",
                          nil];
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
    [push setData:data];
    [push sendPushInBackground];
}

- (void)sendPushInviteForMeetup:(NSString*)meetupId user:(NSString*)userId
{
    Meetup* meetup = [globalData getMeetupById:meetupId];
    if ( ! meetup )
        return;
    
    NSString* strChannel = [NSString stringWithFormat:@"fb%@", userId];
    NSString* strText = [NSString stringWithFormat:@"%@ invited you to %@", [globalVariables shortUserName], meetup.strSubject];
    NSDictionary* data = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"New comment!",  @"title",
                          strText,          @"alert",
                          meetupId,         @"meetup",
                          @"Increment",     @"badge",
                          nil];
    
    PFPush *push = [[PFPush alloc] init];
    [push setChannel:strChannel];
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
    [push setData:data];
    [push expireAfterTimeInterval:PUSH_DISCOVERY_EXPIRATION];
    [push sendPushInBackground];
}

- (void)initChannelsForTheFirstTime:(NSString*)strId
{
    NSString* strUserChannel =[[NSString alloc] initWithFormat:@"fb%@", strId];
    [[PFInstallation currentInstallation] addUniqueObject:strUserChannel forKey:@"channels"];
    [[PFInstallation currentInstallation] addUniqueObject:@"" forKey:@"channels"];
    [[PFInstallation currentInstallation] setObject:strId forKey:@"ownerId"];
    [[PFInstallation currentInstallation] setObject:pCurrentUser forKey:@"ownerData"];
    [[PFInstallation currentInstallation] saveInBackground];
    [PFPush subscribeToChannelInBackground:@"" target:self selector:@selector(subscribeFinished:error:)];
    [PFPush subscribeToChannelInBackground:strUserChannel target:self selector:@selector(subscribeFinished:error:)];
}

- (void)addChannel:(NSString*)strChannel
{
    PFInstallation* currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation addUniqueObject:strChannel forKey:@"channels"];
    [currentInstallation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (error)
            NSLog(@"Sync Error:%@", error);
    }];
    [PFPush subscribeToChannelInBackground:strChannel target:self selector:@selector(subscribeFinished:error:)];
}

- (void)removeChannel:(NSString*)strChannel
{
    [[PFInstallation currentInstallation] removeObject:strChannel forKey:@"channels"];
    [[PFInstallation currentInstallation] saveInBackground];
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