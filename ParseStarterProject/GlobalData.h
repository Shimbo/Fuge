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

@class RootViewController;
@class InboxViewController;

#define globalData [GlobalData sharedInstance]

#define INBOX_LOADED    4   // Number of stages in loading

@interface GlobalData : NSObject
{
    // Main data pack
    NSMutableDictionary *circles;
    NSMutableArray      *meetups;
    
    // Inbox and notifications
    NSArray             *newUsers;
    NSArray             *invites;
    NSArray             *messages;
    NSArray             *comments;
    NSUInteger          nInboxLoadingStage;
}

+ (id)sharedInstance;

// Retrievers
- (Circle*) getCircle:(NSUInteger)circle;
- (Circle*) getCircleByNumber:(NSUInteger)num;
- (Person*) getPersonById:(NSString*)strFbId;
- (NSArray*) getCircles;
- (NSArray*) getMeetups;
- (NSArray*) getInbox;

// New meetup window calls
- (void)addMeetup:(Meetup*)meetup;

// Global data, loading in foreground
- (void)reload:(RootViewController*)controller;

// Inbox data, loading in background
- (void)reloadInbox:(InboxViewController*)controller;
- (Boolean)isInboxLoaded;

// Inbox utils
- (void) updateConverationDate:(NSDate*)date user:(NSString*)strUser;
- (NSDate*) getConversationDate:(NSString*)strUser;

@end
