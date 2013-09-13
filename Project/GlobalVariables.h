//
//  GlobalVariables.h
//  SecondCircle
//
//  Created by Mikhail Larionov on 12/31/12.
//
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>
#import "TestFlight.h"

#undef NSLog
#define NSLog(__FORMAT__, ...) TFLog((@"%s [Line %d] " __FORMAT__), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)

#define globalVariables [GlobalVariables sharedInstance]

#define pCurrentUser [PFUser currentUser]
#define currentUserIsAuthenticated  ([PFUser currentUser] && [[PFUser currentUser] isAuthenticated])
#define strCurrentUserId [[PFUser currentUser] objectForKey:@"fbId"]
#define strCurrentUserFirstName [[PFUser currentUser] objectForKey:@"fbNameFirst"]
#define strCurrentUserLastName [[PFUser currentUser] objectForKey:@"fbNameLast"]
#define bIsAdmin [globalVariables isUserAdmin]

#define meetupIcons @[@"iconMtGeneric", @"iconMtMovie", @"iconMtMusic", @"iconMtSports", @"iconMtGames", @"iconMtStudy", @"iconMtOutdoor", @"iconMtTheatre", @"iconMtArts", @"iconMtHacks", @"iconMtCocktail", @"iconMtClubs", @"iconMtPubs", @"iconMtYoga", @"iconMtWalking", @"iconMtCycling", @"iconMtSocializing", @"iconMtStartups", @"iconMtFinance", @"iconMtProfessionals"]

#define FACEBOOK_PERMISSIONS @[ @"user_about_me", @"user_relationships", @"user_birthday", @"user_likes", @"user_location", @"user_events", @"email"]

// Query distance to discover
#define RANDOM_PERSON_KILOMETERS    (bIsAdmin ? [globalVariables globalParam:@"RandomPersonKilometersAdmin" default:50000] : [globalVariables globalParam:@"RandomPersonKilometersNormal" default:200])
#define RANDOM_EVENT_KILOMETERS     (bIsAdmin ? [globalVariables globalParam:@"RandomEventKilometersAdmin" default:50000] : [globalVariables globalParam:@"RandomEventKilometersNormal" default:200])
#define RANDOM_PERSON_MAX_COUNT     [globalVariables globalParam:@"RandomPersonMaxCount" default:100]
#define SECOND_PERSON_MAX_COUNT     [globalVariables globalParam:@"SecondPersonMaxCount" default:100]

// Location update distance (to call save for PFUser
#define LOCATION_UPDATE_KILOMETERS  0.5f

// Pins on the map
#define PERSON_NOTACTIVE_TIME       [globalVariables globalParam:@"PersonNotActiveTime" default:3600*6]
#define PERSON_OUTDATED_TIME        [globalVariables globalParam:@"PersonOutdatedTime" default:86400]
#define PERSON_HERE_DISTANCE        [globalVariables globalParam:@"PersonHereDistance" default:1000]
#define PERSON_NEARBY_DISTANCE      [globalVariables globalParam:@"PersonNearbyDistance" default:20000]

// Pushes
#define PUSH_DISCOVERY_KILOMETERS   [globalVariables globalParam:@"PushDiscoveryKilometers" default:100]
#define PUSH_DISCOVERY_WINDOW       [globalVariables globalParam:@"PushDiscoveryWindow" default:43200]
#define PUSH_DISCOVERY_EXPIRATION   [globalVariables globalParam:@"PushDiscoveryExpiration" default:86400]

// Not to overload with data
#define MAX_ANNOTATIONS_ON_THE_MAP  200

// To keep recent venues list clean
#define MAX_RECENT_PEOPLE_COUNT     10
#define MAX_RECENT_VENUES_COUNT     [globalVariables globalParam:@"MaxRecentVenuesCount" default:5]

// Merging meetups with persons
#define TIME_FOR_JOIN_PERSON_AND_MEETUP         0.95 //in %
#define DISTANCE_FOR_JOIN_PERSON_AND_MEETUP     200 //in meters

// Merging pins
#define DISTANCE_FOR_GROUPING_PINS  [globalVariables globalParam:@"DistanceForGroupingPins" default:500000]

// Loading limitations
#define MAX_DAYS_TILL_MEETUP        [globalVariables globalParam:@"MaxDaysTillMeetup" default:14]
#define MAX_SECONDS_FROM_PERSON_LOGIN [globalVariables globalParam:@"MaxSecondsFromPersonLogin" default:86400*100]

#define WELCOME_MESSAGE             NSLocalizedString(@"WELCOME_MESSAGE",nil)
//Was (NSString*)[globalVariables getGlobalParam:@"WelcomeMessage"], to be removed later

#define MEETUP_TEMPLATE_DESCRIPTION (NSString*)[globalVariables getGlobalParam:@"MeetupTemplateDescription"]
#define MEETUP_TEMPLATE_PRICE       (NSString*)[globalVariables getGlobalParam:@"MeetupTemplatePrice"]
#define MEETUP_TEMPLATE_IMAGE       (NSString*)[globalVariables getGlobalParam:@"MeetupTemplateImage"]
#define MEETUP_TEMPLATE_URL         (NSString*)[globalVariables getGlobalParam:@"MeetupTemplateURL"]

// Zoom parameters
#define MAX_ZOOM_LEVEL              19

// App store path
#ifdef TARGET_FUGE
#define APP_STORE_PATH              @"http://itunes.apple.com/app/id662139655"
#elif defined TARGET_S2C
#define APP_STORE_PATH              @"http://itunes.apple.com/app/id685496110"
#endif

// Feedback bot ID
#ifdef TARGET_FUGE
#define FEEDBACK_BOT_ID             @"100004580194936"
#define FEEDBACK_BOT_OBJECT         @"zQceZ994lt"
#elif defined TARGET_S2C
#define FEEDBACK_BOT_ID             @"gpT8c6BpfU"
#define FEEDBACK_BOT_OBJECT         @"W7FFRVtAIr"
#endif

// Grouping
#define CAN_GROUP_PERSON            NO
#define CAN_GROUP_MEETUP            YES
#define CAN_GROUP_THREAD            YES

// Ranking
#define MATCHING_BONUS_FRIEND       10
#define MATCHING_BONUS_2O           1
#define MATCHING_BONUS_LIKE         1
#define MATCHING_BONUS_2O_CAP       10

@interface GlobalVariables : NSObject
{
    Boolean bNewUser;
    Boolean bSendPushToFriends;
    NSMutableDictionary* personalSettings;      // Personal settings (from PFUser)
    NSDictionary*       globalSettings; // Global settings (from settings object)
    NSMutableArray*     arrayRoles;
    Boolean             bLoaded;    // True if initial loading passed
}

+ (id)sharedInstance;

- (void)setGlobalSettings:(NSDictionary*)settings;
- (id)getGlobalParam:(NSString*)key;
- (NSUInteger)globalParam:(NSString*)key default:(NSUInteger)defaultResult;

- (Boolean)isNewUser;
- (void)setNewUser;

- (Boolean)shouldSendPushToFriends;
- (void)pushToFriendsSent;

- (Boolean)shouldAlwaysAddToCalendar;
- (void)setToAlwaysAddToCalendar;

- (NSNumber*)currentVersion;
- (PFGeoPoint*) currentLocation;
- (Boolean) isUserAdmin;
- (Boolean) isFeedbackBot:(NSString*)strId;

- (NSString*)trimName:(NSString*)name;
- (NSString*)shortName:(NSString*)firstName last:(NSString*)lastName;
- (NSString*)fullName:(NSString*)firstName last:(NSString*)lastName;
- (NSString*)shortUserName;
- (NSString*)fullUserName;

- (NSMutableArray*)getRoles;
- (NSString*)roleByNumber:(NSUInteger)number;

- (void)setLoaded;
- (void)setUnloaded;
- (Boolean)isLoaded;

@end
