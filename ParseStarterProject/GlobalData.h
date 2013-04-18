//
//  GlobalData.h
//  SecondCircle
//
//  Created by Mikhail Larionov on 1/5/13.
//
//

#import <Foundation/Foundation.h>
#import "Circle.h"
#import "Meetup.h"
#import "Message.h"

@class MapViewController;
@class InboxViewController;

static NSString *const kInboxUnreadCountDidUpdate = @"kInboxUnreadCountDidChange";

static NSString *const kLoadingMainComplete = @"kLoadingMainComplete";
static NSString *const kLoadingMapComplete = @"kLoadingMapComplete";
static NSString *const kLoadingCirclesComplete = @"kLoadingCirclesComplete";
static NSString *const kLoadingInboxComplete = @"kLoadingInboxComplete";

static NSString *const kLoadingMainFailed = @"kLoadingMainFailed";
static NSString *const kLoadingSecondaryFailed = @"kLoadingSecondaryFailed";

static NSString *const kAppRestored = @"kAppRestored";

#define globalData [GlobalData sharedInstance]
#define strCurrentUserId [[PFUser currentUser] objectForKey:@"fbId"]
#define strCurrentUserName [[PFUser currentUser] objectForKey:@"fbName"]

typedef enum ELoadingSection
{
    LOADING_MAIN        = 0,
    LOADING_SECONDARY   = 1
}LoadingSection;

typedef enum ELoadingResult
{
    LOAD_OK             = 0,
    LOAD_NOCONNECTION   = 1,
    LOAD_NOFACEBOOK     = 2,
    LOAD_STARTED        = 99
}LoadingResult;

typedef enum EInviteStatus
{
    INVITE_NEW      = 0,
    INVITE_DECLINED = 1,
    INVITE_ACCEPTED = 2,
    INVITE_DUPLICATE = 3,
    INVITE_EXPIRED  = 4
}InviteStatus;

typedef  enum EMeetupCommentType
{
    COMMENT_PLAIN   = 0,
    COMMENT_CREATED = 1,
    COMMENT_SAVED   = 2,
    COMMENT_JOINED  = 3
}CommentType;

#define INBOX_LOADED    3   // Number of stages in loading
#define MAP_LOADED      3
#define CIRCLES_LOADED  1

@interface GlobalData : NSObject
{
    // Main data pack
    NSMutableDictionary *circles;
    NSMutableArray      *meetups;
    
    // Inbox and notifications
    NSArray             *newUsers;
    NSArray             *invites;
    NSMutableArray      *messages;
    NSMutableArray      *comments;
    NSUInteger          nInboxUnreadCount;
    NSUInteger          nInboxLoadingStage;
    NSUInteger          nMapLoadingStage;
    NSUInteger          nCirclesLoadingStage;
    NSMutableArray      *newFriendsFb;
    NSMutableArray      *newFriends2O;
    
    NSMutableDictionary *_circleByNumber;
    
    NSUInteger          nLoadStatusMain;
    NSUInteger          nLoadStatusSecondary;
    NSUInteger          nLoadStatusInbox;
}

+ (id)sharedInstance;

// Retrievers
- (Circle*) getCircle:(CircleType)circle;
- (Circle*) getCircleByNumber:(NSUInteger)num;
- (Person*) getPersonById:(NSString*)strFbId;
- (NSArray*) getPersonsByIds:(NSArray*)strFbIds;
- (NSArray*) getCircles;
- (NSArray*) getMeetups;
- (Meetup*) getMeetupById:(NSString*)strId;

-(NSArray*)searchForUserName:(NSString*)searchStr;

-(void)createCommentForMeetup:(Meetup*)meetup commentType:(CommentType)type commentText:(NSString*)text;

// New meetup created during the session
- (void)addMeetup:(Meetup*)meetup;
// New comment created in meetup window
- (void)addComment:(PFObject*)comment;

// Global data, loading in foreground
- (void)loadData;
- (void)reloadFriendsInBackground;
- (void)reloadMapInfoInBackground:(PFGeoPoint*)southWest toNorthEast:(PFGeoPoint*)northEast;
- (NSUInteger)getLoadingStatus:(NSUInteger)nStage;
- (Boolean)isMapLoaded;
- (Boolean)areCirclesLoaded;

// Misc
- (void) addRecentInvites:(NSArray*)recentInvites;
- (void) addRecentVenue:(FSVenue*)recentVenue;
- (NSArray*) getRecentPersons;
- (NSArray*) getRecentVenues;
- (Boolean) isUserAdmin;
- (void) setUserPosition:(PFGeoPoint*)geoPoint;
- (void) removeUserFromNew:(NSString*)strUser;
- (void) attendMeetup:(NSString*)strMeetup;
- (void) unattendMeetup:(NSString*)strMeetup;
- (Boolean) isAttendingMeetup:(NSString*)strThread;
- (void) subscribeToThread:(NSString*)strThread;
- (void) unsubscribeToThread:(NSString*)strThread;
- (Boolean) isSubscribedToThread:(NSString*)strThread;

// Invites
// One of two last parameters should be nil
- (void)createInvite:(Meetup*)meetup objectTo:(Person*)recipient stringTo:(NSString*)strRecipient;

@end


@interface GlobalData (Inbox)
    // Inbox data, loading in background
- (void)reloadInboxInBackground;
- (NSMutableDictionary*) getInbox;
- (Boolean)isInboxLoaded;
- (void) incrementInboxLoadingStage;
    // Inbox utils
- (void)postInboxUnreadCountDidUpdate;
- (NSUInteger)getInboxUnreadCount;
- (void) updateConversation:(NSDate*)date count:(NSUInteger)msgCount thread:(NSString*)strThread;
- (NSDate*) getConversationDate:(NSString*)strThread;
- (NSUInteger) getConversationCount:(NSString*)strThread;
- (PFObject*)getInviteForMeetup:(NSString*)strId;
- (void) updateInvite:(NSString*)strId attending:(NSUInteger)status;
@end

@interface GlobalData (Messages)
- (void)addMessage:(Message*)message;
- (void)loadMessages;
- (NSArray*)getUniqueMessages;
- (void)loadThread:(Person*)person target:(id)target selector:(SEL)callback;
@end