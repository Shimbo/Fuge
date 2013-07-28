
#import "CoreLocation/CLLocationManager.h"
#import <CoreLocation/CoreLocation.h>
#import <Parse/Parse.h>

//@class PersonView;

#define currentPerson [[Person alloc] init:pCurrentUser circle:CIRCLE_NONE]

@interface Person : NSObject {
    
    NSString *strId;
    NSString *strFirstName;
    NSString *strLastName;
    NSString *strAge;
    NSString *strGender;
    NSNumber *distance;
    NSNumber *role;
    NSString* strEmployer;
    NSString* strPosition;
    
    NSArray* friendsFb;
    NSArray* friends2O;
    NSArray* likes;
    
    NSUInteger  numUnreadMessages;
    
    PFGeoPoint* location;
    
    NSUInteger idCircle;
    Boolean isCurrentUser;
    
    // Read-only of course
    PFUser* personData;
}

@property (nonatomic, retain) NSString *strId;
@property (nonatomic, retain) NSString *strFirstName;
@property (nonatomic, retain) NSString *strLastName;
@property (nonatomic, retain) NSString *strAge;
@property (nonatomic, retain) NSString *strGender;
@property (nonatomic, retain) NSNumber *distance;
@property (nonatomic, retain) NSString *strEmployer;
@property (nonatomic, retain) NSString *strPosition;
@property (nonatomic, retain) NSString *strCircle;
@property (nonatomic) NSUInteger idCircle;
@property (nonatomic, assign) NSUInteger numUnreadMessages;
@property (nonatomic, retain) NSString *strStatus;
@property (nonatomic, assign) Boolean isCurrentUser;

@property (nonatomic, copy) PFUser *personData;

@property (nonatomic, retain) NSArray *friendsFb;
@property (nonatomic, retain) NSArray *friends2O;
@property (nonatomic, retain) NSArray *likes;

// User could be nil (!) for fb friends who are not in the app yet for example
- (id)init:(PFUser*)user circle:(NSUInteger)nCircle;
- (id)initEmpty:(NSUInteger)nCircle;
- (void)update:(PFUser*)newData;

- (void)calculateDistance;
- (void)changeCircle:(NSUInteger)nCircle;

//- (NSUInteger)getFriendsInCommonCount;

- (Boolean)isOutdated;

-(NSString*)imageURL;
-(NSString*)largeImageURL;

-(NSString*)distanceString;

-(NSString*)timeString;

+(NSString*)imageURLWithId:(NSString*)fbId;
+(NSString*)largeImageURLWithId:(NSString*)fbId;

-(NSString*)shortName;
-(NSString*)fullName;

-(NSString*)jobInfo;

- (PFGeoPoint*) getLocation;

+(void)showInviteDialog:(NSString*)strId;
+(void)openProfileInBrowser:(NSString*)strId;

// Matching
- (NSArray*) matchedFriendsToFriends;
- (NSArray*) matchedFriendsTo2O;
- (NSArray*) matched2OToFriends;
- (NSArray*) matchedLikes;
- (NSUInteger) matchesTotal;
- (NSUInteger) matchesAdminBonus;
- (NSUInteger) matchesRank;
- (NSDictionary*) getLikeById:(NSString*)like;

// For statistics
- (NSUInteger) getConversationCountStats:(Boolean)onlyNotEmpty onlyMessages:(Boolean)bOnlyMessages;

// Conversations
- (Boolean) getConversationPresence:(NSString*)strThread meetup:(Boolean)bMeetup;
- (NSDate*) getConversationDate:(NSString*)strThread meetup:(Boolean)bMeetup;
- (NSUInteger) getConversationCount:(NSString*)strThread meetup:(Boolean)bMeetup;

@end
