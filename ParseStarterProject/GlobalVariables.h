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

// TODO
#define RANDOM_PERSON_KILOMETERS    50000
#define RANDOM_EVENT_KILOMETERS     50000
#define MAX_ANNOTATIONS_ON_THE_MAP  200

#define MAX_RECENT_VENUES_COUNT     5

#define TIME_FOR_JOIN_PERSON_AND_MEETUP         0.95 //in %
#define DISTANCE_FOR_JOIN_PERSON_AND_MEETUP     100 //in meters
#define DISTANCE_FOR_GROUPING_PINS              500000 //in meters

//in meters
#define MAX_ZOOM_LEVEL              19
#define MAX_LINES                   9

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
