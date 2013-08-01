//
//  FacebookLoader.h
//  SecondCircle
//
//  Created by Mikhail Larionov on 6/22/13.
//
//

#import <Foundation/Foundation.h>
#import "LIALinkedInApplication.h"
#import "LIALinkedInHttpClient.h"

// API key wizm9maq6ucs
// Secret Key: AfVbpBqqyuOiya0U
// OAuth User Token: b09f4d15-9da2-4c63-b755-9251a17e00b9
// OAuth User Secret: 0b9d2104-25f6-4833-bfd6-0b9a783c9d99

#define lnLoader [LinkedinLoader sharedInstance]

@interface LinkedinLoader : NSObject
{
    LIALinkedInApplication* application;
    LIALinkedInHttpClient*  client;
    NSString*               accessToken;
    NSDictionary*           userProfile;
}

+ (id)sharedInstance;

- (void)initialize:(id)target selector:(SEL)callback failed:(SEL)failure;

- (NSString*)getProfileInHtml:(NSString*)profileStatus summary:(NSString*)profileSummary jobs:(NSArray*)profileJobs;

@end
