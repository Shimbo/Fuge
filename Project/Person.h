
#import "CoreLocation/CLLocationManager.h"
#import <CoreLocation/CoreLocation.h>
#import <Parse/Parse.h>
#import "ULGeoObject.h"

//@class PersonView;

#define currentPerson [Person currentInstance]

@interface FUGOpportunity : NSObject
@property (nonatomic, retain) NSString* opId;
@property (nonatomic, retain) NSString* text;
@property (nonatomic, retain) NSDate*   dateCreated;
@property (nonatomic, retain) NSDate*   dateUpdated;
@property (nonatomic) BOOL read;
-(NSDictionary*)serialized;
-(BOOL)isOutdated;
@end

@interface Person : ULGeoObject {
    
    NSString    *_strFirstName;
    NSString    *_strLastName;
    NSString    *_strAge;
    NSString    *_strGender;
    NSNumber    *_role;
    NSString    *_strEmployer;
    NSString    *_strPosition;
    
    NSArray     *_friendsFb;
    NSArray     *_friends2O;
    NSArray     *_likes;
    
    NSUInteger  _numUnreadMessages;
    Boolean     _discoverable;
    
    NSUInteger  _idCircle;
    Boolean     _isCurrentUser;
    
    // Read-only of course
    PFUser*     _personData;
    
    NSMutableArray  *_visibleOpportunities;
    NSMutableArray  *_allOpportunities;
    NSUInteger      _visibleOpportunitiesHeight;
}

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

@property (nonatomic, retain) NSMutableArray *visibleOpportunities;
@property (nonatomic, retain) NSMutableArray *allOpportunities;
@property (nonatomic, readonly) NSUInteger  visibleOpportunitiesHeight;

+ (Person*)currentInstance;

// User could be nil (!) for fb friends who are not in the app yet for example
- (id)init:(PFUser*)user circle:(NSUInteger)nCircle;
- (id)initEmpty:(NSUInteger)nCircle;
- (void)update:(PFUser*)newData;

- (void)changeCircle:(NSUInteger)nCircle;

//- (NSUInteger)getFriendsInCommonCount;

- (Boolean)isNotActive;
- (Boolean)isOutdated;
- (NSDate*)updateDate;

-(NSString*)smallAvatarUrl;
-(NSString*)largeAvatarUrl;

-(NSString*)timeString;

-(NSString*)shortName;
-(NSString*)fullName;

-(NSString*)jobInfo;
-(NSString*)industryInfo;   // S2C only

-(NSString*)profileSummary;
-(NSArray*)profilePositions;

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

// Search
- (NSUInteger) searchRating:(NSString*)searchString;

- (FUGOpportunity*) addOpportunity:(NSString*)text;
- (void) saveOpportunity:(FUGOpportunity*)op;
- (void) deleteOpportunity:(FUGOpportunity*)op;

@end
