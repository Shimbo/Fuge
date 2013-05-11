//
//  GlobalVariables.m
//  SecondCircle
//
//  Created by Mikhail Larionov on 12/31/12.
//
//

#import "GlobalVariables.h"
#import <Parse/Parse.h>

@implementation GlobalVariables

static GlobalVariables *sharedInstance = nil;

// Get the shared instance and create it if necessary.
+ (GlobalVariables *)sharedInstance {
    if (sharedInstance == nil) {
        sharedInstance = [[super allocWithZone:NULL] init];
    }
    
    return sharedInstance;
}

// We can still have a regular init method, that will get called the first time the Singleton is used.
- (id)init
{
    self = [super init];
    
    if (self) {
        bNewUser = FALSE;
        bSendPushToFriends = FALSE;
        settings = nil;
    }
    
    return self;
}


// We don't want to allocate a new instance, so return the current one.
+ (id)allocWithZone:(NSZone*)zone {
    return [self sharedInstance];
}

// Equally, we don't want to generate multiple copies of the singleton.
- (id)copyWithZone:(NSZone *)zone {
    return self;
}




- (Boolean)isNewUser
{
    return sharedInstance->bNewUser;
}

- (void)setNewUser
{
    sharedInstance->bSendPushToFriends = TRUE;
    sharedInstance->bNewUser = TRUE;
}

- (Boolean)shouldSendPushToFriends
{
    return sharedInstance->bSendPushToFriends;
}

- (void)pushToFriendsSent
{
    sharedInstance->bSendPushToFriends = FALSE;
}


- (void) checkSettings
{
    if ( ! settings )
    {
        settings = [[PFUser currentUser] objectForKey:@"settings"];
        if ( ! settings )
        {
            settings = [[NSMutableDictionary alloc] init];
            NSNumber* falseNum = [[NSNumber alloc] initWithBool:false];
            [settings setValue:[falseNum stringValue] forKey:@"addToCalendar"];
            [[PFUser currentUser] setObject:settings forKey:@"settings"];
        }
    }
}

- (Boolean)shouldAlwaysAddToCalendar
{
    [self checkSettings];
    return [[settings objectForKey:@"addToCalendar"] boolValue];
}

- (void)setToAlwaysAddToCalendar
{
    NSNumber* trueNum = [[NSNumber alloc] initWithBool:true];
    [settings setValue:[trueNum stringValue] forKey:@"addToCalendar"];
    [[PFUser currentUser] setObject:settings forKey:@"settings"];
    [[PFUser currentUser] saveInBackground];
}

- (NSString*)trimName:(NSString*)name
{
    NSRange range = [name rangeOfString:@" "];
    NSString* newString = [NSString stringWithFormat:@"%@.", [name substringToIndex:range.location+2]];
    return newString;
}

- (NSNumber*)currentVersion
{
    NSString* strData = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    return [NSNumber numberWithFloat:[strData floatValue]];
}

@end