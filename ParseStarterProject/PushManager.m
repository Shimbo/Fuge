//
//  PushManager.m
//  SecondCircle
//
//  Created by Mikhail Larionov on 2/3/13.
//
//

#import "PushManager.h"
#import <Parse/Parse.h>
#import "GlobalVariables.h"

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
    
    NSString* strName = [[PFUser currentUser] objectForKey:@"fbName"];
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
    
    NSString* strChannel =[[NSString alloc] initWithFormat:@"fb%@", strTo];
    
    [PFPush sendPushMessageToChannelInBackground:strChannel withMessage:strPush];
    [dicNewUserPushesSent setObject:@"Sent" forKey:strTo];
}

/*- (void)sendPushNewMessage:(NSInteger)pushType idTo:(NSString*)strTo
{
    NSString* strFrom = [[PFUser currentUser] objectForKey:@"fbName"];
    NSString* strPush = @"Wrong push!";
    switch (pushType)
    {
        case PUSH_NEW_MESSAGE:
            strPush = [[NSString alloc] initWithFormat:@"New message from %@!", strFrom];
            break;
    }
    NSString* strChannel = [[NSString alloc] initWithFormat:@"fb%@", strTo];
    [PFPush sendPushMessageToChannelInBackground:strChannel withMessage:strPush];
}*/

- (void)initChannelsFirstTime
{
    NSString* strUserChannel =[[NSString alloc] initWithFormat:@"fb%@", [[PFUser currentUser] objectForKey:@"fbId"]];
    [[PFInstallation currentInstallation] addUniqueObject:strUserChannel forKey:@"channels"];
    [[PFInstallation currentInstallation] addUniqueObject:@"" forKey:@"channels"];
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
    }]; // TODO: here was Eventually
    [PFPush subscribeToChannelInBackground:strChannel target:self selector:@selector(subscribeFinished:error:)];
}

- (void)removeChannel:(NSString*)strChannel
{
    [[PFInstallation currentInstallation] removeObject:strChannel forKey:@"channels"];
    [[PFInstallation currentInstallation] saveInBackground]; // TODO: here was Eventually
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