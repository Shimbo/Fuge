//
//  GlobalVariables.m
//  SecondCircle
//
//  Created by Mikhail Larionov on 12/31/12.
//
//

#import "GlobalVariables.h"
#import <Parse/Parse.h>
#import "LocationManager.h"

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
        personalSettings = nil;
        globalSettings = nil;
        bLoaded = false;
        
        // DO NOT change the order, server side uses this numeration
        arrayRoles = [[NSMutableArray alloc] init];
        [arrayRoles addObject:@"Other"];
        [arrayRoles addObject:@"Engineer"];
        [arrayRoles addObject:@"Designer"];
        [arrayRoles addObject:@"Marketing"];
        [arrayRoles addObject:@"Product lead"];
        [arrayRoles addObject:@"CEO"];
        [arrayRoles addObject:@"CTO"];
        [arrayRoles addObject:@"Finance"];
        [arrayRoles addObject:@"Consultant"];
        [arrayRoles addObject:@"Teacher"];
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


- (NSMutableArray*)getRoles
{
    return arrayRoles;
}

- (NSString*) roleByNumber:(NSUInteger)number
{
    if ( number >= arrayRoles.count )
        return @"Unknown";
    return arrayRoles[number];
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
    if ( ! personalSettings )
    {
        personalSettings = [[PFUser currentUser] objectForKey:@"settings"];
        if ( ! personalSettings )
        {
            personalSettings = [[NSMutableDictionary alloc] init];
            NSNumber* falseNum = [[NSNumber alloc] initWithBool:false];
            [personalSettings setValue:[falseNum stringValue] forKey:@"addToCalendar"];
            [[PFUser currentUser] setObject:personalSettings forKey:@"settings"];
        }
    }
}

- (Boolean)shouldAlwaysAddToCalendar
{
    [self checkSettings];
    return [[personalSettings objectForKey:@"addToCalendar"] boolValue];
}

- (void)setToAlwaysAddToCalendar
{
    NSNumber* trueNum = [[NSNumber alloc] initWithBool:true];
    [personalSettings setValue:[trueNum stringValue] forKey:@"addToCalendar"];
    [[PFUser currentUser] setObject:personalSettings forKey:@"settings"];
    [[PFUser currentUser] saveInBackground];
}

- (NSString*)trimName:(NSString*)name
{
    NSRange range = [name rangeOfString:@" "];
    NSString* newString = [NSString stringWithFormat:@"%@.", [name substringToIndex:range.location+2]];
    return newString;
}

- (NSString*)shortName:(NSString*)firstName last:(NSString*)lastName
{
    if ( ! lastName || lastName.length == 0 )
        return firstName;
    if ( ! firstName || firstName.length == 0 )
        return lastName;
    return [NSString stringWithFormat:@"%@ %@.", firstName, [lastName substringToIndex:1]];
}

- (NSString*)fullName:(NSString*)firstName last:(NSString*)lastName
{
    if ( ! lastName || lastName.length == 0 )
        return firstName;
    if ( ! firstName || firstName.length == 0 )
        return lastName;
    return [NSString stringWithFormat:@"%@ %@", firstName, lastName];
}

- (NSString*)shortUserName
{
    return [self shortName:strCurrentUserFirstName last:strCurrentUserLastName];
}

- (NSString*)fullUserName
{
    return [self fullName:strCurrentUserFirstName last:strCurrentUserLastName];
}

- (NSNumber*)currentVersion
{
    NSString* strData = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    return [NSNumber numberWithFloat:[strData floatValue]];
}

- (Boolean) isUserAdmin
{
    if ( [pCurrentUser objectForKey:@"admin"] )
        if ( [[pCurrentUser objectForKey:@"admin"] boolValue] == TRUE )
        return true;
    return false;
}

- (PFGeoPoint*) currentLocation
{
    PFGeoPoint* ptUser = [[PFUser currentUser] objectForKey:@"location"];
    if ( ! ptUser )
        ptUser = [locManager getDefaultPosition];
    return ptUser;
}

- (void)setGlobalSettings:(NSDictionary*)settings
{
    globalSettings = settings;
}

- (id)getGlobalParam:(NSString*)key
{
    // We have the key stored in global data
    if ( globalSettings )
        if ( [globalSettings objectForKey:key] )
            return [globalSettings objectForKey:key];
    
    // Show error
    NSString* strError = [NSString stringWithFormat:@"The following key is missing in settings object! Key: %@", key];
    UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Error, bad settings key" message:strError delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [errorAlert show];
    
    return nil;
}

- (NSUInteger)globalParam:(NSString*)key default:(NSUInteger)defaultResult
{
    NSNumber* num = [globalVariables getGlobalParam:key];
    if ( ! num )
        return defaultResult;
    return [num integerValue];
}

- (void)setLoaded
{
    bLoaded = true;
}

- (Boolean)isLoaded
{
    return bLoaded;
}

@end