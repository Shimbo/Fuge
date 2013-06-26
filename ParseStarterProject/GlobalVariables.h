//
//  GlobalVariables.h
//  SecondCircle
//
//  Created by Mikhail Larionov on 12/31/12.
//
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

//#define IOS7_ENABLE

#define globalVariables [GlobalVariables sharedInstance]

#define pCurrentUser [PFUser currentUser]
#define strCurrentUserId [[PFUser currentUser] objectForKey:@"fbId"]
#define strCurrentUserFirstName [[PFUser currentUser] objectForKey:@"fbNameFirst"]
#define strCurrentUserLastName [[PFUser currentUser] objectForKey:@"fbNameLast"]
#define bIsAdmin [globalVariables isUserAdmin]

#define IPAD (UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad)

#define meetupIcons @[@"iconMtGeneric", @"iconMtMovie", @"iconMtMusic", @"iconMtSports", @"iconMtGames", @"iconMtStudy"]

// Query distance to discover
#define RANDOM_PERSON_KILOMETERS_NORMAL    [globalVariables globalParam:@"RandomPersonKilometersNormal" default:50]
#define RANDOM_EVENT_KILOMETERS_NORMAL     [globalVariables globalParam:@"RandomEventKilometersNormal" default:50]
#define RANDOM_PERSON_KILOMETERS_ADMIN     [globalVariables globalParam:@"RandomPersonKilometersAdmin" default:50000]
#define RANDOM_EVENT_KILOMETERS_ADMIN      [globalVariables globalParam:@"RandomEventKilometersNormal" default:50000]


// Location update distance (to call save for PFUser
#define LOCATION_UPDATE_KILOMETERS  0.5f

// Pins
#define PERSON_OUTDATED_TIME        3600*6

// Pushes
#define PUSH_DISCOVERY_KILOMETERS   [globalVariables globalParam:@"PushDiscoveryKilometers" default:100]
#define PUSH_DISCOVERY_EXPIRATION   [globalVariables globalParam:@"PushDiscoveryExpiration" default:86400]

// Not to overload with data
#define MAX_ANNOTATIONS_ON_THE_MAP  200

// To keep recent venues list clean
#define MAX_RECENT_VENUES_COUNT     [globalVariables globalParam:@"MaxRecentVenueCount" default:5]

// Merging meetups with persons
#define TIME_FOR_JOIN_PERSON_AND_MEETUP         0.95 //in %
#define DISTANCE_FOR_JOIN_PERSON_AND_MEETUP     200 //in meters

// Merging pins
#define DISTANCE_FOR_GROUPING_PINS  [globalVariables globalParam:@"DistanceForGroupingPins" default:500000]

// Otherwise not showing at all
#define MAX_DAYS_TILL_MEETUP        [globalVariables globalParam:@"MaxDaysTillMeetup" default:7]

#define WELCOME_MESSAGE             (NSString*)[globalVariables getGlobalParam:@"WelcomeMessage"]

// Zoom parameters
#define MAX_ZOOM_LEVEL              19

// Text view for outcoming messages
#define TEXT_VIEW_MAX_LINES         9

// App store path
#define APP_STORE_PATH              @"http://itunes.apple.com/app/id662139655"

// Feedback bot ID
#define FEEDBACK_BOT_ID             @"100004580194936"
#define FEEDBACK_BOT_OBJECT         @"zQceZ994lt"

// Viral
#define FB_INVITE_MESSAGE           @"Discover new friends and local activities!"

#define CAN_GROUP_PERSON           NO
#define CAN_GROUP_MEETUP           YES
#define CAN_GROUP_THREAD           YES

@interface GlobalVariables : NSObject
{
    Boolean bNewUser;
    Boolean bSendPushToFriends;
    NSMutableDictionary* personalSettings;      // Personal settings (from PFUser)
    NSDictionary*       globalSettings; // Global settings (from settings object)
    NSMutableArray*     arrayRoles;
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

- (NSString*)trimName:(NSString*)name;
- (NSString*)shortName:(NSString*)firstName last:(NSString*)lastName;
- (NSString*)fullName:(NSString*)firstName last:(NSString*)lastName;
- (NSString*)shortUserName;
- (NSString*)fullUserName;

- (NSMutableArray*)getRoles;
- (NSString*)roleByNumber:(NSUInteger)number;

@end
