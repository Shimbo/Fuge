
#import "CoreLocation/CLLocationManager.h"
#import <CoreLocation/CoreLocation.h>
#import <Parse/Parse.h>

//@class PersonView;

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
@property (nonatomic, assign) NSUInteger isCurrentUser;

@property (nonatomic, copy) PFUser *personData;

@property (nonatomic, retain) NSArray *friendsFb;
@property (nonatomic, retain) NSArray *friends2O;
@property (nonatomic, retain) NSArray *likes;

// User could be nil (!) for fb friends who are not in the app yet for example
- (id)init:(PFUser*)user circle:(NSUInteger)nCircle;
- (id)initEmpty:(NSUInteger)nCircle;

- (void)updateLocation:(PFGeoPoint*)ptNewLocation;
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
- (NSUInteger) matchesRank;
- (NSDictionary*) getLikeById:(NSString*)like;

@end
