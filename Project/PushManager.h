//
//  PushManager.h
//  SecondCircle
//
//  Created by Mikhail Larionov on 2/3/13.
//
//

#import <Parse/Parse.h>
#import <Foundation/Foundation.h>

#define pushManager [PushManager sharedInstance]

enum EPushType
{
    PUSH_NEW_FBFRIEND   = 1,
    PUSH_NEW_2OFRIEND   = 2,
    PUSH_NEW_MESSAGE    = 3,
    PUSH_NEW_MTCOMMENT  = 4
};

@interface PushManager : NSObject
{
    NSMutableArray* newUserPushesSent;
}

+ (id)sharedInstance;

- (void)sendPushNewUser:(NSInteger)pushType idsTo:(NSArray*)to;
- (void)sendPushNewMessage:(NSString*)userId text:(NSString*)strText;
- (void)sendPushAttendingMeetup:(NSString*)meetupId;
- (void)sendPushLeftMeetup:(NSString*)meetupId;
- (void)sendPushCommentedMeetup:(NSString*)meetupId;
- (void)sendPushInviteForMeetup:(NSString*)meetupId user:(NSString*)userId;
- (void)sendPushCreatedMeetup:(NSString*)meetupId ignore:(NSArray*)ignoreList;
- (void)sendPushCanceledMeetup:(NSString*)meetupId;
- (void)sendPushChangedMeetup:(NSString*)meetupId;

// All other pushes are cloud-based
//- (void)sendPushNewMessage:(NSInteger)pushType idTo:(NSString*)strTo;

- (void)initChannels;
- (void)addChannels:(NSArray*)channels;
- (void)removeChannels:(NSArray*)channels;
- (void)logout;

@end


