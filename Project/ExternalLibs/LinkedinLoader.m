//
//  FacebookLoader.m
//  SecondCircle
//
//  Created by Mikhail Larionov on 6/22/13.
//
//

#import "LinkedinLoader.h"

@implementation LinkedinLoader

#pragma mark -
#pragma mark Singleton

static LinkedinLoader *sharedInstance = nil;

+ (LinkedinLoader *)sharedInstance {
    if (sharedInstance == nil) {
        sharedInstance = [[super allocWithZone:NULL] init];
    }
    
    return sharedInstance;
}

// Initialization
- (id)init
{
    self = [super init];
    
    if (self) {
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


#pragma mark -
#pragma mark Loaders

- (void)loadUserData:(PFUser*)user
{
    NSString* strId = [userProfile objectForKey:@"id"];
    [user setObject:strId forKey:@"fbId"];
    
    NSString* strFirstName = [userProfile objectForKey:@"firstName"];
    if ( strFirstName )
        [user setObject:strFirstName forKey:@"fbNameFirst"];
    
    NSString* strLastName = [userProfile objectForKey:@"lastName"];
    if ( strLastName )
        [user setObject:strLastName forKey:@"fbNameLast"];
}

- (void)initialize:(id)target selector:(SEL)callback failed:(SEL)failure
{
    application = [LIALinkedInApplication applicationWithRedirectURL:@"http://www.ancientprogramming.com"
            clientId:@"wizm9maq6ucs" clientSecret:@"AfVbpBqqyuOiya0U"
            state:@"DCEEFWF45453sdffef424"
            grantedAccess:@[@"r_fullprofile", @"r_network", @"r_emailaddress", @"r_contactinfo", @"rw_groups"]];
    client = [LIALinkedInHttpClient clientForApplication:application presentingViewController:target];
    
    [client getAuthorizationCode:^(NSString * code) {
        [client getAccessToken:code success:^(NSDictionary *accessTokenData) {
            accessToken = [accessTokenData objectForKey:@"access_token"];
            [client getPath:[NSString stringWithFormat:@"https://api.linkedin.com/v1/people/~:(id,first-name,last-name,headline,industry,picture-url,public-profile-url,email-address,positions,summary,specialties)?oauth2_access_token=%@&format=json", accessToken] parameters:nil success:^(AFHTTPRequestOperation * operation, NSDictionary *result) {
                
                NSLog(@"current user %@", result);
                userProfile = result;
                
                NSString* strId = [result objectForKey:@"id"];
                if ( ! strId )
                {
                    // ERROR!
                }
                NSString* strEmail = [result objectForKey:@"emailAddress"];
                if ( ! strEmail )
                {
                    // ERROR!
                }
                NSString* strPassword = @"singlePassword777";
                
                [PFUser logInWithUsernameInBackground:strId password:strPassword block:^(PFUser *user, NSError *error)
                 {
                     if (user) {
                         
                         // Main loading
                         NSLog(@"User logged in through Linkedin!");                         
                         [pCurrentUser refreshInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                             if ( ! error )
                             {
                                 // Social network data
                                 [self loadUserData:user];
                                 [target performSelector:callback withObject:nil];
                             }
                             else
                                 [target performSelector:failure withObject:error];
                         }];
                     } else {
                         if ( error.code == 101 ) // not found
                         {
                             PFUser* user = [PFUser user];
                             user.username = strId;
                             user.password = strPassword;
                             user.email = strEmail;
                             
                             [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                                 if (!error) {
                                     
                                     // Social network data
                                     [self loadUserData:user];
                                     
                                     // Main loading
                                     NSLog(@"User signed up and logged in through Linkedin!");
                                     [globalVariables setNewUser];
                                     [target performSelector:callback withObject:nil];
                                     
                                 } else {
                                     NSString *errorString = [[error userInfo] objectForKey:@"error"];
                                     NSLog(@"Error: %@", errorString);
                                     [target performSelector:failure withObject:error];
                                 }
                             }];
                         }
                     }
                 }];
                
            } failure:^(AFHTTPRequestOperation * operation, NSError *error) {
                NSLog(@"failed to fetch current user %@", error);
                [target performSelector:failure withObject:error];
            }];
        } failure:^(NSError *error) {
            NSLog(@"Quering accessToken failed %@", error);
            [target performSelector:failure withObject:error];
        }];
    } cancel:^{
        NSLog(@"Authorization was cancelled by user");
        [target performSelector:failure withObject:nil];
    } failure:^(NSError *error) {
        NSLog(@"Authorization failed %@", error);
        [target performSelector:failure withObject:error];
    }];

}

@end
