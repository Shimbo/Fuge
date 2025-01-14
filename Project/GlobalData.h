//
//  GlobalData.h
//  SecondCircle
//
//  Created by Mikhail Larionov on 1/5/13.
//
//

#import <Foundation/Foundation.h>
#import "GlobalVariables.h"
#import "Circle.h"
#import "FUGEvent.h"
#import "Message.h"
#import "Comment.h"
#import "EventbriteLoader.h"
#import "FacebookLoader.h"
#import "MeetupLoader.h"

@class MapViewController;
@class InboxViewController;

static NSString *const kInboxUnreadCountDidUpdate = @"kInboxUnreadCountDidChange";

static NSString *const kLoadingMainComplete = @"kLoadingMainComplete";
static NSString *const kLoadingMapComplete = @"kLoadingMapComplete";
static NSString *const kLoadingEncountersComplete = @"kLoadingEncountersComplete";
static NSString *const kLoadingCirclesComplete = @"kLoadingCirclesComplete";
//static NSString *const kLoadingFriendsComplete = @"kLoadingFriendsComplete";
static NSString *const kLoadingInboxComplete = @"kLoadingInboxComplete";

static NSString *const kLoadingMainFailed = @"kLoadingMainFailed";
static NSString *const kLoadingMapFailed = @"kLoadingMapFailed";
static NSString *const kLoadingCirclesFailed = @"kLoadingCirclesFailed";
static NSString *const kLoadingInboxFailed = @"kLoadingInboxFailed";

static NSString *const kAppRestored = @"kAppRestored";
static NSString *const kNewMeetupCreated = @"kNewMeetupCreated";
static NSString *const kNewMeetupChanged = @"kNewMeetupChanged";
static NSString *const kInboxUpdated = @"kInboxUpdated";
static NSString *const kLocationEnabled = @"kLocationEnabled";
static NSString *const kOpportunitiesHidden = @"kOpportunitiesHidden";

static NSString *const kPushReceivedNewFriend = @"kPushReceivedNewFriend";
static NSString *const kPushReceivedNewMessage = @"kPushReceivedNewMessage";
static NSString *const kPushReceivedNewComment = @"kPushReceivedNewComment";
static NSString *const kPushReceivedNewInvite = @"kPushReceivedNewInvite";
static NSString *const kPushReceivedNewMeetup = @"kPushReceivedNewMeetup";
// Following are not used yet
static NSString *const kPushReceivedMeetupAttendee = @"kPushReceivedMeetupAttendee";
static NSString *const kPushReceivedMeetupLeaver = @"kPushReceivedMeetupLeaver";
static NSString *const kPushReceivedMeetupCanceled = @"kPushReceivedMeetupCanceled";
static NSString *const kPushReceivedMeetupChanged = @"kPushReceivedMeetupChanged";

#define globalData [GlobalData sharedInstance]

typedef enum ELoadingSection
{
    LOADING_MAIN        = 0,
    LOADING_MAP         = 1,
    LOADING_CIRCLES     = 2,
    LOADING_INBOX       = 3
}LoadingSection;

typedef enum EInboxLoadingSection
{
    INBOX_ALL           = 0,
    INBOX_INVITES       = 1,
    INBOX_MESSAGES      = 2,
    INBOX_COMMENTS      = 3
}InboxLoadingSection;

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

#define INBOX_LOADED    3   // Number of stages in loading

#ifdef TARGET_S2C
#define MAP_LOADED      2
#elif defined TARGET_FUGE
#define MAP_LOADED      3
#endif

#define CIRCLES_LOADED  1

@interface GlobalData : NSObject
{
    // Main data pack
    NSMutableDictionary *circles;
    
    // Inbox and notifications
    NSArray             *newUsers;
    NSMutableArray      *invites;
    NSMutableArray      *messages;
    NSMutableArray      *comments;
    NSUInteger          nInboxUnreadCount;
    NSUInteger          nInboxLoadingStage;
    NSUInteger          nMapLoadingStage;
    NSUInteger          nCirclesLoadingStage;
    NSMutableArray      *newFriendsFb;
    NSMutableArray      *oldFriends2O, *newFriends2O;
    
    NSMutableDictionary *_circleByNumber;
    
    NSUInteger          nLoadStatusMain;
    NSUInteger          nLoadStatusMap;
    NSUInteger          nLoadStatusCircles;
    NSUInteger          nLoadStatusInbox;
    
    EventbriteLoader*   EBloader;
    FacebookLoader*     FBloader;
    MeetupLoader*       MTloader;
    
    Boolean             firstDataLoad;
    
    NSDictionary*       readEventsDictionaryCachedPointer;
}

+ (id)sharedInstance;

// Retrievers
- (Circle*) getCircle:(CircleType)circle;
- (Circle*) getCircleByNumber:(NSUInteger)num;
- (Person*) getPersonById:(NSString*)strFbId;
- (NSArray*) getPersonsByIds:(NSArray*)strFbIds;
- (NSArray*) getCircles;

-(NSArray*)searchForUserName:(NSString*)searchStr;

// Person added somehow (opened from unread pm for example)
- (Person*)addPerson:(PFUser*)user userCircle:(NSUInteger)circleUser;

// Global data, loading in foreground
- (void)loadData;
- (NSUInteger)getLoadingStatus:(NSUInteger)nStage;
- (void)loadImportedEvent:(NSString*)eventId target:(id)target selector:(SEL)callback;

// Global data callers to load in background
- (void)reloadFriendsInBackground;//:(Boolean)loadRandom;
- (void)reloadMapInfoInBackground:(PFGeoPoint*)southWest toNorthEast:(PFGeoPoint*)northEast;
- (void) loadPersonsBySearchString:(NSString*)searchString target:(id)target selector:(SEL)callback;
- (void) loadPersonsByIdsList:(NSArray*)idsList target:(id)target selector:(SEL)callback;

// Misc
- (void) setRecentInvites:(NSArray*)recentInvites;
- (void) addRecentVenue:(FSVenue*)recentVenue;
- (NSArray*) getRecentPersons;
- (NSArray*) getRecentVenues;
//- (void) addPersonToSeenList:(NSString*)strId;    // not used as rudimental yet
//- (Boolean) isPersonSeen:(NSString*)strId;
- (Boolean) setUserPosition:(PFGeoPoint*)geoPoint;
- (void) removeUserFromNew:(NSString*)strUser;

- (void) attendMeetup:(FUGEvent*)meetup addComment:(Boolean)addComment target:(id)target selector:(SEL)callback;
- (void) unattendMeetup:(FUGEvent*)meetup target:(id)target selector:(SEL)callback;
- (Boolean) isAttendingMeetup:(NSString*)strThread;
- (Boolean) hasLeftMeetup:(NSString*)strMeetup;
- (void) eventCanceled:(FUGEvent*)meetup;

- (void) subscribeToThread:(NSString*)strThread;
- (void) unsubscribeToThread:(NSString*)strThread;
- (Boolean) isSubscribedToThread:(NSString*)strThread;

// Invites
// One of two last parameters should be nil
- (void)createInvite:(FUGEvent*)meetup stringTo:(NSString*)strRecipient target:(id)target selector:(SEL)callback;

// For internal use
- (void)loadingFailed:(NSUInteger)nStage status:(NSUInteger)nStatus;

@end


@interface GlobalData (Inbox)
    // Inbox data, loading in background
- (void)reloadInboxInBackground:(NSUInteger)inboxSection;
- (NSMutableDictionary*) getInbox;
- (void) incrementInboxLoadingStage;
    // Inbox utils
- (void)postInboxUnreadCountDidUpdate;
- (NSUInteger)getInboxUnreadCount;
- (void) updateConversation:(NSDate*)date count:(NSNumber*)msgCount thread:(NSString*)strThread meetup:(Boolean)bMeetup;
- (NSUInteger) unreadConversationCount:(FUGEvent*)event;
- (PFObject*)getInviteForMeetup:(NSString*)strId;
- (void) updateInvite:(NSString*)strId attending:(NSUInteger)status;

- (void) setEventRead:(NSString*)eventId withExpirationDate:(NSDate*)expirationDate;
- (BOOL) isEventRead:(NSString*)eventId;

- (void) setPersonOpportunityHidden:(NSString*)personId tillDate:(NSDate*)date;
- (NSDate*) getPersonOpportunityHideDate:(NSString*)personId;

@end

@interface GlobalData (Messages)
- (void)addMessage:(Message*)message;
- (void)loadMessages;
- (NSArray*)getUniqueMessages;
- (void)loadMessageThread:(Person*)person target:(id)target selector:(SEL)callback;
- (void)createMessage:(NSString*)strText person:(Person*)personTo target:(id)target selector:(SEL)callback;
@end

@interface GlobalData (Comments)
- (void)addComment:(Comment*)message;
- (void)loadComments;
- (NSArray*)getUniqueThreads;
- (void)loadCommentThread:(FUGEvent*)meetup target:(id)target selector:(SEL)callback;
-(void)createCommentForMeetup:(FUGEvent*)meetup commentType:(CommentType)type commentText:(NSString*)text target:(id)target selector:(SEL)callback;
@end