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

#define globalData [GlobalData sharedInstance]
#define strCurrentUserId [[PFUser currentUser] objectForKey:@"fbId"]
#define strCurrentUserName [[PFUser currentUser] objectForKey:@"fbName"]

enum EInviteStatus
{
    INVITE_NEW      = 0,
    INVITE_DECLINED = 1,
    INVITE_ACCEPTED = 2
};

enum EMeetupCommentType
{
    COMMENT_PLAIN   = 0,
    COMMENT_CREATED = 1,
    COMMENT_SAVED   = 2,
    COMMENT_JOINED  = 3
};

#define INBOX_LOADED    4   // Number of stages in loading

@interface GlobalData : NSObject
{
    // Main data pack
    NSMutableDictionary *circles;
    NSMutableArray      *meetups;
    
    // Inbox and notifications
    NSArray             *newUsers;
    NSArray             *invites;
    NSMutableArray      *messages;
    NSArray             *comments;
    NSUInteger          nInboxLoadingStage;
}

+ (id)sharedInstance;

// Retrievers
- (Circle*) getCircle:(NSUInteger)circle;
- (Circle*) getCircleByNumber:(NSUInteger)num;
- (Person*) getPersonById:(NSString*)strFbId;
- (NSArray*) getPersonsByIds:(NSArray*)strFbIds;
- (NSArray*) getCircles;
- (NSArray*) getMeetups;
- (NSArray*) getInbox;

-(NSArray*)searchForUserName:(NSString*)searchStr;

-(void)createCommentForMeetup:(Meetup*)meetup commentType:(NSUInteger)type commentText:(NSString*)text;

// New meetup created during the session
- (void)addMeetup:(Meetup*)meetup;
// New message created in user profile window
- (void)addMessage:(PFObject*)message;

// Global data, loading in foreground
- (void)reload:(MapViewController*)controller;

// Inbox data, loading in background
- (void)reloadInbox:(InboxViewController*)controller;
- (Boolean)isInboxLoaded;

// Inbox utils
- (void) updateConversationDate:(NSDate*)date thread:(NSString*)strThread;
- (NSDate*) getConversationDate:(NSString*)strThread;
- (void) subscribeToThread:(NSString*)strThread;
- (void) unsubscribeToThread:(NSString*)strThread;
- (Boolean) isSubscribedToThread:(NSString*)strThread;

// Invites
// One of two last parameters should be nil
- (void)createInvite:(Meetup*)meetup objectTo:(Person*)recipient stringTo:(NSString*)strRecipient;


@end
