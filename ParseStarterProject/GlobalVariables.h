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

// TODO
#define RANDOM_PERSON_KILOMETERS    50000
#define RANDOM_EVENT_KILOMETERS     50000
#define MAX_ANNOTATIONS_ON_THE_MAP  200

#define TIME_FOR_JOIN_PERSON_AND_MEETUP  0.95 //in %
#define DISTANCE_FOR_JOIN_PERSON_AND_MEETUP  100 //in meters
#define DISTANCE_FOR_GROUPING_PINS  25 //in pixels


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

@end
