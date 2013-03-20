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

@class MapViewController;
@class InboxViewController;


static NSString *const kInboxUnreadCountDidUpdate = @"kInboxUnreadCountDidChange";

#define globalData [GlobalData sharedInstance]
#define strCurrentUserId [[PFUser currentUser] objectForKey:@"fbId"]
#define strCurrentUserName [[PFUser currentUser] objectForKey:@"fbName"]

typedef enum EInviteStatus
{
    INVITE_NEW      = 0,
    INVITE_DECLINED = 1,
    INVITE_ACCEPTED = 2
}InviteStatus;

typedef  enum EMeetupCommentType
{
    COMMENT_PLAIN   = 0,
    COMMENT_CREATED = 1,
    COMMENT_SAVED   = 2,
    COMMENT_JOINED  = 3
}CommentType;

#define INBOX_LOADED    3   // Number of stages in loading

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
    NSUInteger          nInboxLoadingStage;
    NSUInteger          nInboxUnreadCount;
    NSMutableArray*     newFriendsFb;
    NSMutableArray*     newFriends2O;
    
    NSMutableDictionary *_circleByNumber;
}

+ (id)sharedInstance;

// Retrievers
- (Circle*) getCircle:(CircleType)circle;
- (Circle*) getCircleByNumber:(NSUInteger)num;
- (Person*) getPersonById:(NSString*)strFbId;
- (NSArray*) getPersonsByIds:(NSArray*)strFbIds;
- (NSArray*) getCircles;
- (NSArray*) getMeetups;

-(NSArray*)searchForUserName:(NSString*)searchStr;

-(void)createCommentForMeetup:(Meetup*)meetup commentType:(CommentType)type commentText:(NSString*)text;

// New meetup created during the session
- (void)addMeetup:(Meetup*)meetup;
// New message created in user profile window
- (void)addMessage:(PFObject*)message;
// New comment created in meetup window
- (void)addComment:(PFObject*)comment;

// Global data, loading in foreground
- (void)reload:(MapViewController*)controller;

// Inbox data, loading in background
- (void)reloadInbox:(InboxViewController*)controller;
- (NSMutableDictionary*) getInbox:(InboxViewController*)controller;
- (Boolean)isInboxLoaded;

-(void)updateInboxUnreadCount;
- (NSUInteger)getInboxUnreadCount;

// Inbox utils
- (void) updateConversationDate:(NSDate*)date thread:(NSString*)strThread;
- (NSDate*) getConversationDate:(NSString*)strThread;
- (void) subscribeToThread:(NSString*)strThread;
- (void) unsubscribeToThread:(NSString*)strThread;
- (Boolean) isSubscribedToThread:(NSString*)strThread;

// Misc
- (void) addRecentInvites:(NSArray*)recentInvites;
- (void) addRecentVenue:(FSVenue*)recentVenue;
- (NSArray*) getRecentPersons;
- (NSArray*) getRecentVenues;
- (Boolean) isUserAdmin;
- (void) setUserPosition:(PFGeoPoint*)geoPoint;

// Invites
// One of two last parameters should be nil
- (void)createInvite:(Meetup*)meetup objectTo:(Person*)recipient stringTo:(NSString*)strRecipient;


@end
