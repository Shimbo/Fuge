//
//  FacebookLoader.h
//  SecondCircle
//
//  Created by Mikhail Larionov on 6/22/13.
//
//

#import <Foundation/Foundation.h>
#import <FacebookSDK/FacebookSDK.h>

#define fbLoader [FacebookLoader sharedInstance]

#define keys @[@"/me/movies", @"/me/music", @"/me/games", @"/me/books", @"/me/interests", @"/me/likes"]
#define categories @[@"Movies", @"Music", @"Games", @"Books", @"Interests", @"Likes"]

@interface FacebookLoader : NSObject
{
    
}

+ (id)sharedInstance;

- (void)loadUserData:(NSDictionary<FBGraphUser>*)user;
- (void)loadMeetups:(id)target selector:(SEL)callback;
- (void)loadLikes:(id)target selector:(SEL)callback;
- (void)loadFriends:(id)target selectorSuccess:(SEL)callbackSuccess selectorFailure:(SEL)callbackFailure;

// Utils
- (NSString*)getProfileUrl:(NSString*)strId;
- (NSString*)getSmallAvatarUrl:(NSString*)fbId;
- (NSString*)getLargeAvatarUrl:(NSString*)fbId;

// Virals
- (void)showInviteDialog:(NSArray*)strIds message:(NSString*)message;

@end
