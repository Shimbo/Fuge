//
//  PushManager.h
//  SecondCircle
//
//  Created by Mikhail Larionov on 2/3/13.
//
//

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
    NSMutableDictionary* dicNewUserPushesSent;
}

+ (id)sharedInstance;

- (void)sendPushNewUser:(NSInteger)pushType idTo:(NSString*)strTo;
- (void)sendPushNewMessage:(NSInteger)pushType idTo:(NSString*)strTo;

- (void)initChannelsFirstTime;
- (void)addChannel:(NSString*)strChannel;

@end


