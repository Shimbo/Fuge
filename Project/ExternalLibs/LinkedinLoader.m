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

- (void) showErrorMessage:(NSString*)strMessage
{
    UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:strMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [errorAlert show];
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
    // Id
    NSString* strId = [userProfile objectForKey:@"id"];
    [user setObject:strId forKey:@"fbId"];
    
    // First name
    NSString* strFirstName = [userProfile objectForKey:@"firstName"];
    if ( strFirstName )
        [user setObject:strFirstName forKey:@"fbNameFirst"];
    
    // Last name
    NSString* strLastName = [userProfile objectForKey:@"lastName"];
    if ( strLastName )
        [user setObject:strLastName forKey:@"fbNameLast"];
    
    // Position, industry
    NSString* strPosition = [userProfile objectForKey:@"headline"];
    if ( strPosition )
        [user setObject:strPosition forKey:@"profilePosition"];
    NSString* strIndustry = [userProfile objectForKey:@"industry"];
    if ( strIndustry )
        [user setObject:strIndustry forKey:@"profileIndustry"];
    
    // Jobs, summary and current employer
    NSString* strSummary = [userProfile objectForKey:@"summary"];
    if ( strSummary )
        [user setObject:strSummary forKey:@"profileSummary"];
    NSDictionary* dictJobs = [userProfile objectForKey:@"positions"];
    if ( dictJobs )
    {
        NSArray* jobs = [dictJobs objectForKey:@"values"];
        [user setObject:jobs forKey:@"profilePositions"];        
        for ( NSDictionary* job in jobs )
        {
            NSNumber* isCurrent = [job objectForKey:@"isCurrent"];
            if ( isCurrent && isCurrent.integerValue == 1 )
            {
                NSDictionary* company = [job objectForKey:@"company"];
                NSString* strEmployer = [company objectForKey:@"name"];
                if ( strEmployer )
                    [user setObject:strEmployer forKey:@"profileEmployer"];
            }
        }
    }
    
    // Avatar and profile page
    NSString* strAvatar = [userProfile objectForKey:@"pictureUrl"];
    if ( strAvatar )
        [user setObject:strAvatar forKey:@"urlAvatar"];
    NSString* strProfile = [userProfile objectForKey:@"publicProfileUrl"];
    if ( strProfile )
        [user setObject:strProfile forKey:@"urlProfile"];
    
    // Connections
    NSDictionary* connectionDict = [userProfile objectForKey:@"connections"];
    if ( connectionDict )
    {
        NSArray* connectionArray = [connectionDict objectForKey:@"values"];
        for ( NSDictionary* connection in connectionArray )
        {
            NSString* strId = [connection objectForKey:@"id"];
            [pCurrentUser addUniqueObject:strId forKey:@"fbFriends"];
        }
    }
    
    // Big photo
    NSDictionary* photos = [userProfile objectForKey:@"pictureUrls"];
    if ( photos )
    {
        NSArray* values = [photos objectForKey:@"values"];
        if ( values )
            [user setObject:values forKey:@"urlPhotos"];
    }
}

- (void)initialize:(id)target selector:(SEL)callback failed:(SEL)failure
{
    application = [LIALinkedInApplication applicationWithRedirectURL:@"http://www.shimbotech.com"
            clientId:@"wizm9maq6ucs" clientSecret:@"AfVbpBqqyuOiya0U"
            state:@"DCEEFWF45453sdffef424"
            grantedAccess:@[@"r_fullprofile", @"r_network", @"r_emailaddress", @"r_contactinfo", @"rw_groups"]];
    client = [LIALinkedInHttpClient clientForApplication:application presentingViewController:target];
    
    [client getAuthorizationCode:^(NSString * code) {
        [client getAccessToken:code success:^(NSDictionary *accessTokenData) {
            accessToken = [accessTokenData objectForKey:@"access_token"];
            [client getPath:[NSString stringWithFormat:@"https://api.linkedin.com/v1/people/~:(id,first-name,last-name,headline,industry,picture-url,public-profile-url,email-address,positions,summary,specialties,connections,picture-urls::(original))?oauth2_access_token=%@&format=json", accessToken] parameters:nil success:^(AFHTTPRequestOperation * operation, NSDictionary *result) {
                
                //NSLog(@"current user %@", result);
                userProfile = result;
                
                NSString* strId = [result objectForKey:@"id"];
                if ( ! strId )
                {
                    NSLog(@"Linkedin: failed to fetch user id");
                    [self showErrorMessage:@"Linkedin: failed to fetch user id"];
                    [target performSelector:failure withObject:nil];
                    return;
                }
                NSString* strEmail = [result objectForKey:@"emailAddress"];
                if ( ! strEmail )
                {
                    NSLog(@"Linkedin: failed to fetch user e-mail");
                    [self showErrorMessage:@"Linkedin: failed to fetch user e-mail"];
                    [target performSelector:failure withObject:nil];
                    return;
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
                             {
                                 //[self showErrorMessage:[NSString stringWithFormat:@"Refresh error: %@", error]];
                                 NSLog(@"Refresh error: %@", error);
                                 [target performSelector:failure withObject:error];
                             }
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
                                     NSLog(@"Linkedin: user signup failed, error: %@", error);
                                     //[self showErrorMessage:[NSString stringWithFormat:@"Linkedin: user signup failed, error: %@", error]];
                                     [target performSelector:failure withObject:nil];
                                 }
                             }];
                         }
                         else
                         {
                             NSLog(@"User login error (other than not found): %@", error);
                             //[self showErrorMessage:[NSString stringWithFormat:@"User login failed, error: %@", error]];
                             [target performSelector:failure withObject:nil];
                         }
                     }
                 }];
                
            } failure:^(AFHTTPRequestOperation * operation, NSError *error) {
                //[self showErrorMessage:[NSString stringWithFormat:@"Failed to fetch Linkedin user, error: %@", error]];
                NSLog(@"Failed to fetch current Linkedin user, error: %@", error);
                [target performSelector:failure withObject:nil];
            }];
        } failure:^(NSError *error) {
            //[self showErrorMessage:[NSString stringWithFormat:@"Linkedin accessToken quering failed, error: %@", error]];
            NSLog(@"Linkedin accessToken quering failed, error: %@", error);
            [target performSelector:failure withObject:nil];
        }];
    } cancel:^{
        NSLog(@"Linkedin authorization was cancelled by user.");
        [self showErrorMessage:@"Linkedin authorization was cancelled by user."];
        [target performSelector:failure withObject:nil];
    } failure:^(NSError *error) {
        //[self showErrorMessage:[NSString stringWithFormat:@"Linkedin: authorization failed, error: %@", error]];
        NSLog(@"Linkedin authorization failed, error: %@", error);
        [target performSelector:failure withObject:nil];
    }];
}

- (NSString*)getProfileInHtml:(NSString*)profileStatus summary:(NSString*)profileSummary jobs:(NSArray*)profileJobs
{
    NSMutableString* stringResult = [NSMutableString stringWithString:@""];
    if ( profileStatus && profileStatus.length > 0 )
    {
        //[stringResult appendString:@"<h3>Status</h3>"];
        [stringResult appendString:profileStatus];
        [stringResult appendString:@"<BR>"];
    }
    if ( profileSummary && profileSummary.length > 0 )
    {
        [stringResult appendString:@"<h3>Summary</h3>"];
        [stringResult appendString:profileSummary];
        [stringResult appendString:@"<BR>"];
    }
    if ( profileJobs )
    {
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        
        [stringResult appendString:@"<h3>Positions</h3>"];
        for ( NSDictionary* job in profileJobs )
        {
            if ( [job objectForKey:@"title"] )
                [stringResult appendString:[NSString stringWithFormat:@"<b>%@</b><BR>", [job objectForKey:@"title"]]];
            if ( [job objectForKey:@"company"] )
            {
                NSDictionary* company = [job objectForKey:@"company"];
                if ( [company objectForKey:@"name"] )
                    [stringResult appendString:[NSString stringWithFormat:@"%@<BR>", [company objectForKey:@"name"]]];
            }
            if ( [job objectForKey:@"startDate"] )
            {
                NSDictionary* startDate = [job objectForKey:@"startDate"];
                if ( [startDate objectForKey:@"month"] )
                {
                    NSInteger month = [[startDate objectForKey:@"month"] integerValue];
                    [stringResult appendString:[NSString stringWithFormat:@"%@ ", [[df monthSymbols] objectAtIndex:month-1]]];
                }
                
                if ( [startDate objectForKey:@"year"] )
                    [stringResult appendString:[NSString stringWithFormat:@"%@ - ", [startDate objectForKey:@"year"]]];
            }
            if ( [job objectForKey:@"isCurrent"] && [[job objectForKey:@"isCurrent"] boolValue] == TRUE )
                [stringResult appendString:@"Present<BR>"];
            else
            {
                NSDictionary* endDate = [job objectForKey:@"endDate"];
                if ( [endDate objectForKey:@"month"] )
                {
                    NSInteger month = [[endDate objectForKey:@"month"] integerValue];
                    [stringResult appendString:[NSString stringWithFormat:@"%@ ", [[df monthSymbols] objectAtIndex:month-1]]];
                }
                
                if ( [endDate objectForKey:@"year"] )
                    [stringResult appendString:[NSString stringWithFormat:@"%@", [endDate objectForKey:@"year"]]];
                [stringResult appendString:@"<BR>"];
            }
            if ( [job objectForKey:@"summary"] )
                [stringResult appendString:[NSString stringWithFormat:@"<BR>%@<BR>", [job objectForKey:@"summary"]]];
            [stringResult appendString:@"<BR>"];
        }
    }
    return stringResult;
}

@end
