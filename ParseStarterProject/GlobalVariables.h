//
//  GlobalVariables.h
//  SecondCircle
//
//  Created by Mikhail Larionov on 12/31/12.
//
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

#define globalVariables [GlobalVariables sharedInstance]

#define pCurrentUser [PFUser currentUser]
#define strCurrentUserId [[PFUser currentUser] objectForKey:@"fbId"]
#define strCurrentUserName [[PFUser currentUser] objectForKey:@"fbName"]

#define meetupIcons @[@"iconMeetup", @"iconThread", @"iconThread", @"iconThread", @"iconThread", @"iconThread", @"iconThread"]

// Query distance to discover
#define RANDOM_PERSON_KILOMETERS    50000
#define RANDOM_EVENT_KILOMETERS     50000

// Location update distance (to call save for PFUser
#define LOCATION_UPDATE_KILOMETERS  0.5f

// Pins
#define PERSON_OUTDATED_TIME        3600*6

// Pushes
#define PUSH_DISCOVERY_KILOMETERS   100
#define PUSH_DISCOVERY_EXPIRATION   3600*24

// Not to overload with data
#define MAX_ANNOTATIONS_ON_THE_MAP  200

// To keep recent venues list clean
#define MAX_RECENT_VENUES_COUNT     5

// Merging meetups with persons
#define TIME_FOR_JOIN_PERSON_AND_MEETUP         0.95 //in %
#define DISTANCE_FOR_JOIN_PERSON_AND_MEETUP     100 //in meters

// Merging pins
#define DISTANCE_FOR_GROUPING_PINS              500000 //in meters

// Zoom parameters
#define MAX_ZOOM_LEVEL              19

// Text view for outcoming messages
#define TEXT_VIEW_MAX_LINES         9

// App store path
#define APP_STORE_PATH              @"http://itunes.apple.com/app/id378458261"

// Feedback bot ID
#define FEEDBACK_BOT_ID             @"100004580194936"

// Viral
#define FB_INVITE_MESSAGE           @"Discover new friends and local activities!"

@interface GlobalVariables : NSObject
{
    Boolean bNewUser;
    Boolean bSendPushToFriends;
    NSMutableDictionary* settings;
}

- (Boolean)isNewUser;
- (void)setNewUser;

- (Boolean)shouldSendPushToFriends;
- (void)pushToFriendsSent;

- (Boolean)shouldAlwaysAddToCalendar;
- (void)setToAlwaysAddToCalendar;

+ (id)sharedInstance;

- (NSNumber*)currentVersion;

- (NSString*)trimName:(NSString*)name;

@end
