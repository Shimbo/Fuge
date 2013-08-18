
#import "CoreLocation/CLLocationManager.h"
#import <CoreLocation/CoreLocation.h>
#import <Parse/Parse.h>
#import "GeoObject.h"

//@class PersonView;

#define currentPerson [[Person alloc] init:pCurrentUser circle:CIRCLE_NONE]

@interface Person : GeoObject {
    
    NSString *strId;
    NSString *strFirstName;
    NSString *strLastName;
    NSString *strAge;
    NSString *strGender;
    NSNumber *role;
    NSString* strEmployer;
    NSString* strPosition;
    
    NSArray* friendsFb;
    NSArray* friends2O;
    NSArray* likes;
    
    NSUInteger  numUnreadMessages;
    Boolean     discoverable;
    
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
@property (nonatomic, retain) NSString *strEmployer;
@property (nonatomic, retain) NSString *strPosition;
@property (nonatomic, retain) NSString *strCircle;
@property (nonatomic) NSUInteger idCircle;
@property (nonatomic, assign) NSUInteger numUnreadMessages;
@property (nonatomic, readonly) Boolean discoverable;
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

- (void)changeCircle:(NSUInteger)nCircle;

//- (NSUInteger)getFriendsInCommonCount;

- (Boolean)isOutdated;
- (NSDate*)updateDate;

-(NSString*)smallAvatarUrl;
-(NSString*)largeAvatarUrl;

-(NSString*)timeString;

-(NSString*)shortName;
-(NSString*)fullName;

-(NSString*)jobInfo;
#ifdef TARGET_S2C
-(NSString*)industryInfo;
#endif

-(void)openProfileInBrowser;

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
